# a change comes in and is added to the queue
# if there are no remote changes we don't need 
# to do anything

# if a remote change comes in we add it to the queue
# then we sort the queue by timestamp and replay all
# changes

# how do we minimize queue size?
# 

class Editor
    constructor: (params={socket: null}) ->   
        $('#particles-js').remove()
        $('.text').hide();
        $('body').addClass('editor')
        @room_name = params.room_name
        @socket = params.socket
        @maximum_latency = 1000
        @queue = []
        @send_all_content = false
        @remote_edit_timeout = null
        @has_remote_edits = false
        @save_frequency = 5000
        @should_save = true

        @sort_by_time = (a,b) ->
            if a.time < b.time
                return -1
            if a.time > b.time
                return 1
            return 0

        @codemirror_init()

        @startcontent = @cm.doc.getValue()

        editor = @
        # time needs to be passed to the old queue, that's
        # why that fucking error from yesterday was so easy to
        # fix, all changes are change.change format, because there's 
        # change.change and change.time, BLAGH!!!!

        if old_queue?
            editor.cm.doc.replaceRange(
                change.change.text, 
                change.change.from, 
                change.change.to, 
                change.change.origin
            ) for change in old_queue


        @enable_resizer(@cm)
        @window_resize_listener()
        @listen_for_local_changes()

        @socket.on 'remote_change', (change) ->
            console.log('remote_change')
            editor.process_remote_change(change)


        @render_iframe_html()


    render_iframe_html: (duration) ->
        window.clearTimeout(@timeout)
        codemirror = @cm
        @timeout = window.setTimeout () ->
            html = codemirror.doc.getValue()
            encodedHtml = encodeURIComponent(html)
            document.getElementById('view').src = "data:text/html," + encodedHtml          
        , duration

    process_remote_change: (change) ->
        @has_remote_edits = true
        editor = @
        window.clearTimeout(@remote_edit_timeout)
        @remote_edit_timeout = window.setTimeout ->
            editor.has_remote_edits = false
            editor.startcontent = editor.cm.doc.getValue()
            editor.queue = []
        , @maximum_latency

        @queue.push({
            time: change.time,
            change: change.change
        })
        console.log(change)
        # rerender_editor_from_queue()
        history = @cm.doc.getHistory()
        @cm.doc.replaceRange(
            change.change.text, 
            change.change.from, 
            change.change.to, 
            'remote'
        )
        @cm.doc.setHistory(history)

    listen_for_local_changes: () ->
        editor = @
        @cm.doc.on 'change', (codemirror, changeObj) ->

            if editor.should_save
                editor.should_save = false
                window.setTimeout () ->
                    editor.socket.emit('save', 
                        content: editor.cm.doc.getValue(), 
                        room_name: editor.room_name
                    )
                    editor.should_save = true
                , editor.save_frequency

            d = new Date()
            time = d.getTime()

            if changeObj.origin != 'setValue'
                editor.render_iframe_html(1000)

            if (changeObj.origin != 'remote') && (changeObj.origin != 'setValue')
                d = new Date()
                change_time = d.getTime()
                change_and_time_obj = {
                    time: change_time,
                    change: changeObj
                }
                editor.queue.push(change_and_time_obj)
                editor.rerender_editor_from_queue()

                # logic to occaionally send all content to server
                # server will save on non-null value.

                editor.socket.emit 'change', 
                    room_name: editor.room_name
                    change: change_and_time_obj,
                    time: change_time


    rerender_editor_from_queue: () ->
        if @has_remote_edits
            history = @cm.doc.getHistory()
        
            @gueue = @queue.sort(@sort_by_time)

            scroll_position = @cm.getScrollInfo()
            cursor_position = @cm.doc.getCursor()

            @cm2.doc.setValue(startcontent)
            @cm2.doc.replaceRange(
                change.change.text, 
                change.change.from, 
                change.change.to, 
                change.change.origin
            ) for change in queue

            @cm.doc.setValue(@cm2.getValue())
            @cm.doc.setHistory(history)
            @cm.doc.setCursor(cursor_position)

            @cm.scrollTo(
                scroll_position.left, 
                scroll_position.top
            )

    enable_resizer: (codemirror) ->
        clicking = false;
        $('.resize').mousedown ->
          clicking = true;
          $(this).addClass('dragging');
        
        $(window).mouseup ->
          $('.resize').removeClass('dragging');
          $('body').removeClass('resizing');
          clicking = false
          codemirror.refresh()

        $(window).mousemove (e) ->
          if clicking == true
            # editor.resize();
            $('body').addClass('resizing');
            $('iframe').css('width', (window.innerWidth - e.pageX))
            $('.editor-container').css('width', e.pageX)

    window_resize_listener: () ->
        resize = () ->
            editor_width = $('.editor-container').width()
            $('iframe').css('width', (window.innerWidth - editor_width))

        window.onresize = resize

    codemirror_init: () ->
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
        @cm = CodeMirror.fromTextArea textarea, 
            lineNumbers: true,
            viewportMargin: Infinity,
            mode: mixedMode,
            theme: "base16-tomorrow-dark",
            autoCloseBrackets: true,
            indentUnit: 4

        @cm2 = CodeMirror.fromTextArea $('textarea.hide')[0]

        $('.editor-container').css('width', window.innerWidth * 0.4)
        $('iframe').css('width', window.innerWidth * 0.6)
        @cm.refresh()

