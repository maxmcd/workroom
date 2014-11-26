#= require jquery-2.1.1.min
#= require codemirror
#= require closebrackets
#= require css
#= require foo
#= require javascript
#= require xml
#= require vbscript
#= require htmlmixed
$ ->

    resize = () ->
        editor_width = $('.editor-container').width()
        $('iframe').css('width', (window.innerWidth - editor_width))

    window.onresize = resize


    clicking = false;
    $('.resize').mousedown ->
      clicking = true;
      $(this).addClass('dragging');
    
    $(window).mouseup ->
      $('.resize').removeClass('dragging');
      $('body').removeClass('resizing');
      clicking = false

    $(window).mousemove (e) ->
      if clicking == true
        # editor.resize();
        $('body').addClass('resizing');
        $('iframe').css('width', (window.innerWidth - e.pageX))
        $('.editor-container').css('width', e.pageX)


    #connect to the default socket endpoint
    socket = io()

    #s
    mixedMode = {
        name: "htmlmixed"
        scriptTypes: [
            {
                matches: /\/x-handlebars-template|\/x-mustache/i,
                mode: null
            },
            {
                matches: /(text|application)\/(x-)?vb(a|script)/i,
                mode: "vbscript"
            }
        ]
    }

    textarea = document.getElementById('editor')
    editor = CodeMirror.fromTextArea textarea, 
        lineNumbers: true,
        viewportMargin: Infinity,
        mode: mixedMode,
        theme: "base16-tomorrow-dark",
        autoCloseBrackets: true

    $('.editor-container').css('width', window.innerWidth * 0.4)
    $('iframe').css('width', window.innerWidth * 0.6)
    
    # call this after the editor has been created


    timeout = null
    setValue = (duration) ->
        window.clearTimeout(timeout)
        timeout = window.setTimeout () ->
            html = editor.doc.getValue()
            encodedHtml = encodeURIComponent(html)
            document.getElementById('view').src = "data:text/html," + encodedHtml          
        , duration

    # populate the iframe with intial code
    setValue(0)

    text = $('#content').html()
    editor.doc.on 'change', (codemirror, changeObj) ->
        setValue(1000)
        console.log()
        if changeObj.origin != 'remote'
            socket.emit 'change',
                change: changeObj,
                all_content: editor.doc.getValue()

    socket.on 'remote_change', (changeObj) ->
        history = editor.doc.getHistory()
        editor.doc.replaceRange(
            changeObj.text, 
            changeObj.from, 
            changeObj.to, 
            'remote'
        )
        editor.doc.setHistory(history)

        # var cursor_coords = editor.cursorCoords(changeObj.to)
        # console.log(cursor_coords)
        # var fake_cursor = document.createElement('div')
        # fake_cursor.className = "CodeMirror-cursor"
        # fake_cursor.innerHTML = "&nbsp;"
        # fake_cursor.style.top = (cursor_coords.top - 4) + 'px'
        # fake_cursor.style.left = (cursor_coords.left - 29) + 'px'
        # fake_cursor.style.height = '13px'
        # console.log(fake_cursor.style)

        # $('.CodeMirror-cursors').append(fake_cursor)
