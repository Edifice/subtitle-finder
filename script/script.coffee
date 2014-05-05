
$ ->
	$('#searchForm').on 'submit', (e)->
		getData()
		e.preventDefault()
		false

	getData = ->
		$('#result').empty()

		$('<li>Loading... this might take a minute, so sit back and relax!</li>').appendTo('#result')
		
		$.get '/subtitle-for-' + $('#fileName').val(), (res)->
			isArray = $.isArray res

			data = res

			if !isArray
				data = [res]

			$('#result').empty()
			$('<li><a href="' + item.download + '">' + item.name + '</a></li>').appendTo('#result') for item in data
			
			console.log res
