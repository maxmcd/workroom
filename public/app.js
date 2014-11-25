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

    function setValue() {
        var html = editor.doc.getValue();
        var encodedHtml = encodeURIComponent(html);
        document.getElementById('view').src = "data:text/html," + encodedHtml;  
    }
    setValue()

    var text = $('#content').html()
    editor.doc.on('change', function(codemirror, changeObj) {
        setValue()
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
    })

})