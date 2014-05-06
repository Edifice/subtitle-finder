coffee    = require 'coffee-script'
express   = require 'express'
logfmt    = require 'logfmt'
stylus    = require 'stylus'
nib       = require 'nib'
fs        = require 'fs'

request   = require 'request'
jsdom     = require 'jsdom'
xmlParser = require 'xml2json'

Sequence  = require('sequence').Sequence

languages = require './languages.json'

fs.writeFileSync __dirname + '/public/script/script.js', (coffee.compile(fs.readFileSync __dirname + '/script/script.coffee', 'utf8'))

# init app
app = express()

# set app parameters and behaviour
app.set 'port', process.env.PORT || 8000
app.set 'views', __dirname + '/view'
app.set 'view engine', 'jade'
app.use logfmt.requestLogger()
app.use stylus.middleware
	src: __dirname + '/style/'
	dest: __dirname + '/public/style/'

app.use express.static __dirname + '/public'

app.set 'title', 'FindSub'

# route settings
app.get '/', (req, res) ->
	res.render 'index', {
		title: 'home'
	}
	return

app.get '/:language-subtitle-for-:queryString', (req, res)->
	title = req.params['queryString']
	return {} unless title
	console.log ">> Start processing for '#{title}'"

	# empty array for found data
	foundData = []
	toClient = 
		backdrop: null
		subtitles: []

	# converting sting name to object
	data = fetchName title
	data.language = req.params['language'] || 'all'

	# starting timer
	t = Date.now()

	# initiating sequence
	sequence = Sequence.create()
	sequence
	# Geting list of possible show names
	.then (next)->
		request
			url: encodeURL "http://www.omdbapi.com/?s=#{data.title}"
		, (error, response, body) ->
			if error or response.statusCode isnt 200
				console.log "Error when loading first omdbapi request: " + encodeURL "http://www.omdbapi.com/?s=#{data.title}"
				return 0

			searchResult = JSON.parse body
			if !searchResult.Search?
				console.log "OMDb Api error. Got response: ", searchResult.Error
				return 0
			
			searchResult = searchResult.Search.filter (x)-> x.Type is 'series' #we filter out all the movies and games
			
			if searchResult.length < 1
				console.error "We can not find this Show :("
				return 0
			
			if searchResult.length > 1
				console.log ">> We found #{searchResult.length} shows for this search. We will go on with the first: #{searchResult[0].Title} (#{searchResult[0].Year})"
			else
				console.log ">> Great, we found #{searchResult[0].Title} (#{searchResult[0].Year}) as a TV show!"

			data.imdb = imdbId = searchResult[0].imdbID
			next(imdbId)
	# get accurate Show details
	.then (next, imdbId)->
		console.log ">> The given Show is: #{imdbId}"

		# Then we request the available infos by the imdb id
		request
			url: encodeURL "http://www.omdbapi.com/?i=#{imdbId}&tomatoes=true"
		, (error, response, body) ->
			if error or response.statusCode isnt 200
				console.log "Error when loading second omdbapi request"
				return 0
			showData = JSON.parse body

			data.title = showData.Title

			next()
	# process Feliratok.info provider
	.then (next)->
		# replace spaces
		title = data.title.replace /\s/g, '+'
		# define translated language codes
		langs =
			'all': ''
			'eng': 'Angol'
			'hun': 'Magyar'
		_language = data.language.replace oldVal, newVal for oldVal, newVal of langs when oldVal is data.language
		# creating url
		url = "http://www.feliratok.info/?search=#{title}&soriSorszam=&nyelv=#{_language}&sorozatnev=&sid=&complexsearch=true&knyelv=0&evad=#{data.season}&epizod1=#{data.episode}&cimke=0&minoseg=0&rlsr=0&tab=all"

		console.log '>> Start loading page: ' + url
		request
			uri: url = encodeURL url
			timeout: 12000
		, (error, response, body) ->
			if error or response.statusCode isnt 200
				console.log "Error when loading #{url}"
				next()
			else
				console.log '>>>> Page loaded in ' + (Date.now() - t) + ' msec.'
				
				jsdom.env body, ["http://code.jquery.com/jquery-git2.min.js"], (err, window) ->
					console.log '>> Start getting data from HTML file'
					$ = window.jQuery
					
					table = $("table.result")

					$('tr#vilagit', table).each (index)->
						name = $('.eredeti', @).text()

						episode = '' + data.episode
						episode = '0' + episode if episode.length is 1

						if name.indexOf(" #{data.season}x#{episode}") > -1
							subtitle =
								perfect: false
								provider: 'feliratok.info'
								name: name
								source: url
								download: 'http://www.feliratok.info' + $('img[src="img/download.png"]', @).parent().attr('href')
							if name.toLowerCase().indexOf(data.release) > -1
								subtitle.perfect = true
							toClient.subtitles.push subtitle
						
					next()

	# process opensubtitler.org provider
	.then (next)->
		tempImdbId = data.imdb.replace /tt/i, ''

		url = "http://www.opensubtitles.org/en/ssearch/sublanguageid-#{data.language}/searchonlytvseries-on/season-#{data.season}/episode-#{data.episode}/imdbid-#{tempImdbId}/xml"
		console.log ">> Requesting: #{url}"
		request
			uri: url = encodeURL url
		, (error, response, body) ->
			if error or response.statusCode isnt 200
				console.log "Error when loading #{url}"
				return 0
			
			# parse XML
			xmlData = xmlParser.toJson body, {object: true}

			results = xmlData.opensubtitles.search.results
			_link = results.subtitle.EpisodeName.ImdbLink
			data.epImdb = _link.substr(_link.indexOf('/tt') + 1, 9)

			url = "http://www.opensubtitles.org/en/search/sublanguageid-#{data.language}/imdbid-" + data.epImdb.substr(2) + "/xml"
			console.log ">> Requesting: #{url}"
			request
				uri: encodeURL url
			, (error, response, body) ->
				if error or response.statusCode isnt 200
					console.log "Error when loading #{url}"
					return 0

				# parse XML
				xmlData = xmlParser.toJson body, {object: true}
				results = xmlData.opensubtitles.search.results.subtitle

				for sub in results
					if sub.IDSubtitle? # some of the nodes are for advertisements, so these doesn't have IDSubtitle parameter
						subtitle =
							perfect: false
							provider: 'opensubtitles.org'
							name: sub.MovieReleaseName
							source: url.replace '/xml', ''
							download: sub.IDSubtitle.LinkDownload
						if sub.MovieReleaseName.toLowerCase().indexOf(data.release) > -1
							subtitle.perfect = true
						toClient.subtitles.push subtitle

				next()
	.then (next)->
		url = "http://api.themoviedb.org/3/find/#{data.imdb}?api_key=8f7c64210ac192e7737d265409ac3ed9&external_source=imdb_id"
		console.log ">> Requesting: #{url}"
		request
			uri: url = encodeURL url
		, (error, response, body) ->
			if error or response.statusCode isnt 200
				console.log "Error when loading #{url}"
				return 0

			_show = JSON.parse(body).tv_results[0]

			toClient.backdrop = 'http://image.tmdb.org/t/p/original' + _show.backdrop_path
			
			next()

	# we show the list of possible subtitles
	.then (next)->
		res.json toClient
	return 

# starting Web-App
port = Number(process.env.PORT or 8000)
app.listen port, ->
	console.log 'Listening on ' + port
	return




#    Sample names:
# 
# 
# Complicated names:
# ------------------
# Csillagkapu - Univerzum S02E19.avi
# [HorribleSubs] Ryuugajou Nanana no Maizoukin - 03 [720p].mkv
# hdtv-the.blacklist.s01e02.web-dl.x264.hun.eng.mkv
# Perfect.Couples.S01E07.HUN.HDTV.XviD-HNZ.avi
# dart-twd.hun.eng.s03e03.xvid.avi				- Walking Dead
# [HorribleSubs] Sekai de Ichiban Tsuyoku Naritai! - 10 [720p].mkv
# dart-twd.s03e02.hun.eng.x264.mkv
# 
# Simple names:
# ------------------
# Yu-Gi-Oh!_GX-S02E04.WEB-DL-Rip.XviD.HUN-Baggio1.avi
# hdtv-elementary.s02e09.1080p.web-dl.h264.hun.eng.mkv
# Sons.of.Anarchy.S02E01.BDRIP.x264-Krissz.mp4
# Modern.Family.S05E20.HDTV.XviD-AFG.avi
# Almost.Human.S01E10.WEB-DL.x264.Hun.Eng-pcroland.mkv
# Crisis.S01E03.WEB-DL.x264.HUN-Teko.mkv
# Faking.It.2014.S01E01.WEB-DL.x264-WLR.mkv
# Portlandia.S04E09.3D.Printer.1080p.WEB-DL.AAC2.0.h.264-NTb.mkv
# Marvel's.Avengers.Assemble.S01E20.1080p.WEB-DL.DD5.1.AAC2.0.H264-BgFr.mkv
# 
# Marvel.Agents.Of.SHIELD.S01E19.The.Only.Light.In.The.Darkness.1080p.WEB-DL.DD5.1.H.264-ECI.mkv
# Marvel.Agents.Of.SHIELD.S01E19.The.Only.Light.In.The.Darkness.720p.WEB-DL.DD5.1.H.264-ECI.mkv
# Marvels.Agents.of.S.H.I.E.L.D.S01E19.HDTV.XviD-AFG.avi
# Marvels.Agents.of.S.H.I.E.L.D.S01E19.720p.HDTV.x264-REMARKABLE.mkv
# Marvels.Agents.of.S.H.I.E.L.D.S01E19.HDTV.x264-EXCELLENCE.mp4
# 
# the.100.s01e06.hdtv.x264-2hd.mp4
# the.100.s01e06.720p.hdtv.x264-killers.mkv
# The.100.S01E06.HDTV.XviD-FUM.avi
# The.100.S01E06.720p.WEB-DL.DD5.1.H.264-KiNGS.mkv
# The.100.S01E06.1080p.WEB-DL.DD5.1.H.264-KiNGS.mkv
# The.100.S01E06.WEB-DL.XviD-Rorschach.avi
# 
# Vikings.S02E09.HDTV.x264-EXCELLENCE.mp4
# Vikings.S02E09.720p.HDTV.x264-REMARKABLE.mkv
# Vikings.S02E09.HDTV.XviD-AFG.avi
# Vikings.S02E09.The.Choice.1080p.WEB-DL.DD5.1.H.264-CtrlHD.mkv
# Vikings.S02E09.WEB-DL.x264-WLR.mkv
# Vikings.S02E10.HDTV.x264-2HD.mp4
# 
# salem.s01e01.hdtv.x264-2hd.mp4
# Salem.S01E01.720p.HDTV.X264-DIMENSION.mkv
# Salem.S01E01.The.Vow.1080p.WEB-DL.DD5.1.H.264-ABH.mkv
# Salem.S01E01.The.Vow.720p.WEB-DL.DD5.1.H.264-ABH.mkv
# Salem.S01E01.WEB-DL.x264-WLR.mkv
# Salem.S01E01.HDTV.XviD-AFG.avi
# 
# game.of.thrones.s04e03.hdtv.x264-killers.mp4
# game.of.thrones.s04e03.720p.hdtv.x264-killers.mkv
# Game.of.Thrones.S04E03.HDTV.XviD-AFG.avi
# Game.of.Thrones.S04E03.1080p.HDTV.x264-BATV.mkv
# Game.of.Thrones.S04E03.WEB-DL.x264-WLR.mkv
# Game.of.Thrones.S04E03.WEB-DL.XviD-Rorschach.avi
fetchName = (name)->
	name = name.toLowerCase()

	titleReplacers =
		'of shield': 'of S.H.I.E.L.D.'
		'of s h i e l d': 'of S.H.I.E.L.D.'
		'marvels': 'marvel\'s'
		'da vincis': 'da vinci\'s'

	data =
		imdb: 
			id: ''          # IMDb id of show
			rating: 0
			episodeId: ''   # IMDb id of episode
			episodeRating: 0
		title: ''
		language: ''
		season: 0
		episode: 0
		version: ''
		release: ''
		extension: ''

	# Simple format
	if (simplePos = name.search(/s\d{1,2}e\d{1,2}/g)) > -1
		data.title = trim name.substr(0, simplePos).replace(/\./g, ' ')
		data.title = data.title.replace oldVal, newVal for oldVal, newVal of titleReplacers

		data.season = parseInt(name.substr(simplePos + 1, 2))
		data.episode = parseInt(name.substr(simplePos + 4, 2))

		v = name.substr simplePos + 7
		vArray = v.split '.'

		if vArray[0] isnt 'hdtv' and vArray[0] isnt 'web-dl' and vArray[0] isnt '720p' and vArray[0] isnt '1080p'
			versions = ['720p', '1080p', 'hdtv', 'web-dl']
			data.version = v.substr index for version in versions when (index = v.indexOf version) > 0
			data.version = v if data.version is ''
		else
			data.version = v

		if data.version.lastIndexOf('.') > -1
			if  data.version.indexOf('.mkv') > -1 or data.version.indexOf('.mp4') > -1 or data.version.indexOf('.avi') > -1
				data.extension = data.version.substr data.version.lastIndexOf('.') + 1
				data.version = data.version.substr 0, data.version.lastIndexOf('.')
		
		if data.version.lastIndexOf('-') > -1
			data.release = data.version.substr data.version.lastIndexOf('-') + 1
			data.version = data.version.substr 0, data.version.lastIndexOf('-')
		

	return data

###
	Helper functions
###

trim = (s) ->
	l = 0
	r = s.length - 1
	l++ while l < s.length and s[l] is " "
	r -= 1  while r > l and s[r] is " "
	s.substring l, r + 1

encodeURL = (url)->
	encodeURI(url).replace(/\'/g, '%27')
