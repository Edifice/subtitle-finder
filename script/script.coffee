
$ ->
	$('#searchForm').on 'submit', (e)->
		getData()
		e.preventDefault()
		false

	getData = ->
		$('#result').empty()

		$('<li>Loading... this might take a minute, so sit back and relax!</li>').appendTo('#result')
		
		$.get '/hun-subtitle-for-' + $('#fileName').val(), (res)->
			data = res.subtitles

			$('#result').empty()
			$('<li><a href="' + item.download + '">' + item.name + '</a></li>').appendTo('#result') for item in data
			
			$('body').css('background-image', "url(#{res.backdrop})")
			
			console.log res
