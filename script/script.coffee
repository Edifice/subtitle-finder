
$ ->
	# seting language by browser's language
	$.getJSON 'languages.json', (supportedLanguages)->
		LanguageCtrl =
			initList: ->
				$('#languageSelector ul').empty()
				$("<li data-langval='#{lang.short}'>" + LanguageCtrl.formatText(lang) + "</li>").appendTo('#languageSelector ul') for lang in supportedLanguages
			
			formatText: (obj)->
				obj.int + (if obj.int isnt obj.native then " <small>#{obj.native}</small>" else '')
			
			getUserLanguage: ->
				(window.navigator.userLanguage || window.navigator.language || 'en').substr 0, 2
			
			setLanguage: (shortCode)->
				selected = l for l in supportedLanguages when l.short is shortCode

				$('#languageSelector').data 'value', selected.long
				$('#languageSelector .selected span').html LanguageCtrl.formatText selected
				return selected

		userLang = $.cookie('userLang') || LanguageCtrl.getUserLanguage()
		
		userLangObj = null;
		userLangObj = l for l in supportedLanguages when l.short is userLang

		# if we have wrong data stored, we fall back to english
		unless userLangObj
			userLangObj = l for l in supportedLanguages when l.short is 'en'

		LanguageCtrl.initList()
		LanguageCtrl.setLanguage(userLangObj.short)

		$('#languageSelector .selected').on 'click touch', ->
			$('#languageSelector ul').addClass 'active'

		$('li[data-langval]').on 'click touch', ->
			langCode = $(@).data 'langval'
			LanguageCtrl.setLanguage langCode
			$('#languageSelector ul').removeClass 'active'
			$.cookie 'userLang', langCode, {expires: 10*365}
			@
		@

	$('#searchForm').on 'submit', (e)->
		getData()
		e.preventDefault()
		false

	getData = ->
		$('#result').empty()

		$('<p>Loading... this might take a minute, so sit back and relax!</p>').appendTo('#result')
		
		$.get '/' + $('#languageSelector').data('value') + '-subtitle-for-' + $('#fileName').val(), (res)->
			data = []

			# we add all the unique versions only
			for sub in res.subtitles
				hasIt = false
				hasIt = true for dat in data when isSame dat.name, sub.name
				data.push sub if not hasIt

			$('#result').empty()

			perfects = []
			notPerfects = []

			data.forEach (d)->
				if d.perfect
					perfects.push d
				else
					notPerfects.push d

			if perfects.length > 0
				$('<p class="hint">Perfect matches:</p>').appendTo('#result')
				$('<p class="perfect"><a href="' + item.download + '">' + item.name + '</a></p>').appendTo('#result') for item in perfects

			if notPerfects.length > 0
				$('<p class="hint">Nearly perfect matches:</p>').appendTo('#result')
				$('<p class="notperfect"><a href="' + item.download + '">' + item.name + '</a></p>').appendTo('#result') for item in notPerfects

			if notPerfects.length is 0 and perfects.length is 0
				$('<p>Sorry, we could not find any subtitles to your file name and the selected language :(</p>').appendTo('#result')
			
			$('#background').css('background-image', "url(#{res.backdrop})")
			
			console.log res

	isSame = (a, b)->
		uglify a is uglify b

	uglify = (string)->
		trim string.toLowerCase().replace /\s/g, '.'

	trim = (s) ->
		l = 0
		r = s.length - 1
		l++ while l < s.length and s[l] is " "
		r -= 1  while r > l and s[r] is " "
		s.substring l, r + 1
