$(function() {
    var socket = io();

    var mixedMode = {
        name: "htmlmixed",
        scriptTypes: [{matches: /\/x-handlebars-template|\/x-mustache/i,
            mode: null},
            {matches: /(text|application)\/(x-)?vb(a|script)/i,
            mode: "vbscript"}]
    };

    textarea = document.getElementById('editor');
    editor = CodeMirror.fromTextArea(textarea, {
      lineNumbers: true,
      viewportMargin: Infinity,
      mode: mixedMode,
      // theme: "base16-tomorrow-dark",
      autoCloseBrackets: true
    });


    var timeout
    function setValue() {
        window.clearTimeout(timeout)
        timeout = window.setTimeout(function() {
            var html = editor.doc.getValue();
            var encodedHtml = encodeURIComponent(html);
            document.getElementById('view').src = "data:text/html," + encodedHtml;              
        }, 1000)
    }
    setValue()

    var text = $('#content').html()
    editor.doc.on('change', function(codemirror, changeObj) {
        setValue()
        console.log()
        if (changeObj.origin != 'remote') {
            socket.emit('change', {
                change: changeObj,
                all_content: editor.doc.getValue()
            });            
        }
    })

    socket.on('remote_change', function(changeObj) {
        var history = editor.doc.getHistory()
        editor.doc.replaceRange(
            changeObj.text, 
            changeObj.from, 
            changeObj.to, 
            'remote'
        )
        editor.doc.setHistory(history)

        // var cursor_coords = editor.cursorCoords(changeObj.to)
        // console.log(cursor_coords)
        // var fake_cursor = document.createElement('div')
        // fake_cursor.className = "CodeMirror-cursor"
        // fake_cursor.innerHTML = "&nbsp;"
        // fake_cursor.style.top = (cursor_coords.top - 4) + 'px'
        // fake_cursor.style.left = (cursor_coords.left - 29) + 'px'
        // fake_cursor.style.height = '13px'
        // console.log(fake_cursor.style)

        // $('.CodeMirror-cursors').append(fake_cursor)
    })

})