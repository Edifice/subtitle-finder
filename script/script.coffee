
$ ->
	# seting language by browser's language
	do ->
		supportedLanguages = [{"int":"Afrikaans","native":"Afrikaans","short":"af","long":"afr"},{"int":"Albanian","native":"gjuha shqipe","short":"sq","long":"alb"},{"int":"Arabic","native":"العربية","short":"ar","long":"ara"},{"int":"Armenian","native":"Հայերեն","short":"hy","long":"arm"},{"int":"Basque","native":"euskara, euskera","short":"eu","long":"baq"},{"int":"Belarusian","native":"беларуская мова","short":"be","long":"bel"},{"int":"Bengali, Bangla","native":"বাংলা","short":"bn","long":"ben"},{"int":"Bosnian","native":"bosanski jezik","short":"bs","long":"bos"},{"int":"Breton","native":"brezhoneg","short":"br","long":"bre"},{"int":"Bulgarian","native":"български език","short":"bg","long":"bul"},{"int":"Burmese","native":"ဗမာစာ","short":"my","long":"bur"},{"int":"Catalan, Valencian","native":"català, valencià","short":"ca","long":"cat"},{"int":"Chinese","native":"中文","short":"zh","long":"chi"},{"int":"Croatian","native":"hrvatski jezik","short":"hr","long":"hrv"},{"int":"Czech","native":"čeština","short":"cs","long":"cze"},{"int":"Danish","native":"dansk","short":"da","long":"dan"},{"int":"Dutch","native":"Nederlands, Vlaams","short":"nl","long":"dut"},{"int":"English","native":"English","short":"en","long":"eng"},{"int":"Esperanto","native":"Esperanto","short":"eo","long":"epo"},{"int":"Estonian","native":"eesti, eesti keel","short":"et","long":"est"},{"int":"Finnish","native":"suomi, suomen kieli","short":"fi","long":"fin"},{"int":"French","native":"français","short":"fr","long":"fre"},{"int":"Galician","native":"galego","short":"gl","long":"glg"},{"int":"Georgian","native":"ქართული","short":"ka","long":"geo"},{"int":"German","native":"Deutsch","short":"de","long":"ger"},{"int":"Hebrew (modern)","native":"עברית","short":"he","long":"heb"},{"int":"Hindi","native":"हिन्दी, हिंदी","short":"hi","long":"hin"},{"int":"Hungarian","native":"magyar","short":"hu","long":"hun"},{"int":"Indonesian","native":"Bahasa Indonesia","short":"id","long":"ind"},{"int":"Icelandic","native":"Íslenska","short":"is","long":"ice"},{"int":"Italian","native":"italiano","short":"it","long":"ita"},{"int":"Japanese","native":"日本語 (にほんご)","short":"ja","long":"jpn"},{"int":"Kazakh","native":"қазақ тілі","short":"kk","long":"kaz"},{"int":"Khmer","native":"ខ្មែរ, ខេមរភាសា, ភាសាខ្មែរ","short":"km","long":"khm"},{"int":"Korean","native":"한국어, 조선어","short":"ko","long":"kor"},{"int":"Luxembourgish, Letzeburgesch","native":"Lëtzebuergesch","short":"lb","long":"ltz"},{"int":"Lithuanian","native":"lietuvių kalba","short":"lt","long":"lit"},{"int":"Latvian","native":"latviešu valoda","short":"lv","long":"lav"},{"int":"Macedonian","native":"македонски јазик","short":"mk","long":"mac"},{"int":"Malay","native":"bahasa Melayu, بهاس ملايو‎","short":"ms","long":"may"},{"int":"Malayalam","native":"മലയാളം","short":"ml","long":"mal"},{"int":"Mongolian","native":"монгол","short":"mn","long":"mon"},{"int":"Norwegian","native":"Norsk","short":"no","long":"nor"},{"int":"Occitan","native":"occitan, lenga d'òc","short":"oc","long":"oci"},{"int":"Persian (Farsi)","native":"فارسی","short":"fa","long":"per"},{"int":"Polish","native":"język polski, polszczyzna","short":"pl","long":"pol"},{"int":"Portuguese","native":"português","short":"pt","long":"por"},{"int":"Romanian","native":"limba română","short":"ro","long":"rum"},{"int":"Russian","native":"русский язык","short":"ru","long":"rus"},{"int":"Sinhala, Sinhalese","native":"සිංහල","short":"si","long":"sin"},{"int":"Slovak","native":"slovenčina","short":"sk","long":"slo"},{"int":"Slovene","native":"slovenski jezik","short":"sl","long":"slv"},{"int":"Spanish, Castilian","native":"español","short":"es","long":"spa"},{"int":"Swahili","native":"Kiswahili","short":"sw","long":"swa"},{"int":"Swedish","native":"Svenska","short":"sv","long":"swe"},{"int":"Tamil","native":"தமிழ்","short":"ta","long":"tam"},{"int":"Telugu","native":"తెలుగు","short":"te","long":"tel"},{"int":"Thai","native":"ไทย","short":"th","long":"tha"},{"int":"Tagalog","native":"Wikang Tagalog","short":"tl","long":"tgl"},{"int":"Turkish","native":"Türkçe","short":"tr","long":"tur"},{"int":"Ukrainian","native":"українська мова","short":"uk","long":"ukr"},{"int":"Urdu","native":"اردو","short":"ur","long":"urd"},{"int":"Vietnamese","native":"Tiếng Việt","short":"vi","long":"vie"}]
		
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
			data = res.subtitles

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
				$('<p><a href="' + item.download + '">' + item.name + '</a></p>').appendTo('#result') for item in notPerfects

			if notPerfects.length is 0 and perfects.length is 0
				$('<p>Sorry, we could not find any subtitles to your file name and the selected language :(</p>').appendTo('#result')
			
			$('#background').css('background-image', "url(#{res.backdrop})")
			
			console.log res
