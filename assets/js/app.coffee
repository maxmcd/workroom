#= require jquery-2.1.1.min
#= require codemirror
#= require closebrackets
#= require css
#= require foo
#= require javascript
#= require xml
#= require vbscript
#= require htmlmixed
#= require editor

$ ->
    $socket = io()
    $editor = new Editor($socket)

    # Connect to the default socket endpoint

    # Init values for changes

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
