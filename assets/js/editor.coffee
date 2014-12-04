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

        @startcontent = @ace.getValue()

        editor = @
        # time needs to be passed to the old queue, that's
        # why that fucking error from yesterday was so easy to
        # fix, all changes are change.change format, because there's 
        # change.change and change.time, BLAGH!!!!

        if old_queue?
            deltas = []
            deltas.push(change.change) for change in old_queue
            @ace.session.doc.applyDeltas([change.change])
            # editor.ace.doc.replaceRange(
            #     change.change.text, 
            #     change.change.from, 
            #     change.change.to, 
            #     change.change.origin
            # ) for change in old_queue


        @enable_resizer(@ace)
        @window_resize_listener()
        @listen_for_local_changes()

        @socket.on 'remote_change', (change) ->
            editor.process_remote_change(change)


        @render_iframe_html()


    render_iframe_html: (duration) ->
        window.clearTimeout(@timeout)
        editor = @ace
        @timeout = window.setTimeout () ->
            html = editor.getValue()
            encodedHtml = encodeURIComponent(html)
            document.getElementById('view').src = "data:text/html," + encodedHtml          
        , duration

    process_remote_change: (change) ->
        @has_remote_edits = true
        editor = @
        window.clearTimeout(@remote_edit_timeout)
        @remote_edit_timeout = window.setTimeout ->
            editor.has_remote_edits = false
            editor.startcontent = editor.ace.getValue()
            editor.queue = []
        , @maximum_latency

        @queue.push({
            time: change.time,
            change: change.change
        })

        # only doing this on local changes if there are 
        # remote changes
        # rerender_editor_from_queue()

        # history = @ace.doc.getHistory()
        # @ace.doc.replaceRange(
        #     change.change.text, 
        #     change.change.from, 
        #     change.change.to, 
        #     'remote'
        # )
        # @ace.doc.setHistory(history)
        @remote_change = true
        @ace.session.doc.applyDeltas([change.change])
        @remote_change = false

    listen_for_local_changes: () ->
        editor = @
        @ace.on 'change', (changeObj) ->

            if !editor.set_value && editor.should_save
                editor.should_save = false
                window.setTimeout () ->
                    editor.socket.emit('save', 
                        content: editor.ace.getValue(), 
                        room_name: editor.room_name
                    )
                    editor.should_save = true
                , editor.save_frequency


            if !editor.set_value
                editor.render_iframe_html(1000)

            if editor.remote_change || editor.set_value
                editor.ace.session.$undoManager.$redoStack.pop()
                editor.ace.session.$undoManager.$undoStack.pop()


            if !editor.remote_change && !editor.set_value
                # user change

                d = new Date()
                change_time = d.getTime()
                change_and_time_obj = {
                    time: change_time,
                    change: changeObj.data
                }
                editor.queue.push(change_and_time_obj)
                editor.rerender_editor_from_queue()

                # logic to occaionally send all content to server
                # server will save on non-null value.

                editor.socket.emit 'change', 
                    room_name: editor.room_name
                    change: change_and_time_obj,
                    time: change_time

            else
                # other





    rerender_editor_from_queue: () ->
        # if @has_remote_edits
            console.log("rerender_editor_from_queue")
            # history = @ace.doc.getHistory()
        
            @gueue = @queue.sort(@sort_by_time)

            # scroll_position = @ace.getScrollInfo()
            # cursor_position = @ace.doc.getCursor()

            @set_value = true

            scratch = new ace.EditSession('')
            scratch.doc.setValue(@startcontent)
            deltas = []
            deltas.push(change.change) for change in @queue
            scratch.doc.applyDeltas([change.change])

            cursor_position = @ace.getCursorPosition()
            @ace.setValue(scratch.doc.getValue())
            @ace.moveCursorTo(cursor_position)

            @set_value = false

            # @ace2.doc.replaceRange(
            #     change.change.text, 
            #     change.change.from, 
            #     change.change.to, 
            #     change.change.origin
            # ) for change in queue

            # @ace.doc.setValue(@ace2.getValue())
            # @ace.doc.setHistory(history)
            # @ace.doc.setCursor(cursor_position)

            # @ace.scrollTo(
            #     scroll_position.left, 
            #     scroll_position.top
            # )

    enable_resizer: (codemirror) ->
        clicking = false;
        $('.resize').mousedown ->
          clicking = true;
          $(this).addClass('dragging');
        
        $(window).mouseup ->
          $('.resize').removeClass('dragging');
          $('body').removeClass('resizing');
          clicking = false
          # codemirror.refresh()

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
        @ace = ace.edit("editor");

        # textarea = document.getElementById('editor')
        # @ace = CodeMirror.fromTextArea textarea, 
        #     lineNumbers: true,
        #     viewportMargin: Infinity,
        #     mode: mixedMode,
        #     theme: "base16-tomorrow-dark",
        #     autoCloseBrackets: true,
        #     indentUnit: 4

        # @ace2 = CodeMirror.fromTextArea $('textarea.hide')[0]

        $('.editor-container').css('width', window.innerWidth * 0.4)
        $('iframe').css('width', window.innerWidth * 0.6)
        # @ace.refresh()

