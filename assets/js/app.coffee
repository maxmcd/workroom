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
      editor.refresh()

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
    window.editor = CodeMirror.fromTextArea textarea, 
        lineNumbers: true,
        viewportMargin: Infinity,
        mode: mixedMode,
        theme: "base16-tomorrow-dark",
        autoCloseBrackets: true

    editor2 = CodeMirror.fromTextArea $('textarea.hide')[0]

    $('.editor-container').css('width', window.innerWidth * 0.4)
    $('iframe').css('width', window.innerWidth * 0.6)
    editor.refresh()
    
    # call this after the editor has been created


    timeout = null
    render_iframe_html = (duration) ->
        window.clearTimeout(timeout)
        timeout = window.setTimeout () ->
            html = editor.doc.getValue()
            encodedHtml = encodeURIComponent(html)
            document.getElementById('view').src = "data:text/html," + encodedHtml          
        , duration

    # populate the iframe with intial code
    render_iframe_html(0)



    # Init values for changes

    maximum_latency = 1000
    startcontent = editor.doc.getValue()
    queue = []
    send_all_content = false
    remote_edit_timeout = null
    has_remote_edits = false
    sort_by_time = (a,b) ->
        if a.time < b.time
            return -1
        if a.time > b.time
            return 1
        return 0


    rerender_editor_from_queue = () ->
        if has_remote_edits
            history = editor.doc.getHistory()
        
            gueue = queue.sort(sort_by_time)
            console.log(queue)

            scroll_position = editor.getScrollInfo()
            cursor_position = editor.doc.getCursor()

            editor2.doc.setValue(startcontent)
            editor2.doc.replaceRange(
                change.change.text, 
                change.change.from, 
                change.change.to, 
                change.change.origin
            ) for change in queue

            editor.doc.setValue(editor2.getValue())
            editor.doc.setHistory(history)
            editor.doc.setCursor(cursor_position)
            console.log(scroll_position)
            editor.scrollTo(scroll_position.left, scroll_position.top)


    editor.doc.on 'change', (codemirror, changeObj) ->

        # a change comes in and is added to the queue
        # if there are no remote changes we don't need 
        # to do anything

        # if a remote change comes in we add it to the queue
        # then we sort the queue by timestamp and replay all
        # changes

        # how do we minimize queue size?
        # 

        d = new Date();
        time = d.getTime();

        if changeObj.origin != 'setValue'
            render_iframe_html(1000)

        if (changeObj.origin != 'remote') && (changeObj.origin != 'setValue')
            d = new Date()
            change_time = d.getTime()
            queue.push({
                time: change_time,
                change: changeObj
            })
            rerender_editor_from_queue()

            # logic to occaionally send all content to server
            # server will save on non-null value.

            socket.emit 'change',
                change: changeObj,
                all_content: editor.doc.getValue(),
                time: change_time




    socket.on 'remote_change', (change) ->
        has_remote_edits = true

        window.clearTimeout(remote_edit_timeout)
        remote_edit_timeout = window.setTimeout ->
            has_remote_edits = false
            startcontent = editor.doc.getValue()
            queue = []

        , maximum_latency

        queue.push({
            time: change.time,
            change: change.change
        })
        # rerender_editor_from_queue()
        history = editor.doc.getHistory()
        editor.doc.replaceRange(
            change.change.text, 
            change.change.from, 
            change.change.to, 
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
