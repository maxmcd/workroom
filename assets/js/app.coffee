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




    # particles = particlesJS 'particles-js', {
    #     particles: {
    #         color: '#fff',
    #         shape: 'circle', # "circle", "edge" or "triangle"
    #         opacity: 0.6,
    #         size: 2,
    #         size_random: false,
    #         nb: Math.floor(window.innerWidth/10),
    #         line_linked: {
    #             enable_auto: true,
    #             distance:150,
    #             color: '#fff',
    #             opacity: 0.4,
    #             width: 1,
    #             condensed_mode: {
    #                 enable: true,
    #                 rotateX: 600,
    #                 rotateY: 600
    #             }
    #         },
    #         anim: {
    #             enable: true,
    #             speed: 0.9
    #         }
    #     },
    #     interactivity: {
    #         enable: true,
    #         mouse: {
    #             distance: 200
    #         },
    #         detect_on: 'canvas', # "canvas" or "window"
    #         mode: 'grab'
    #     },
    #     retina_detect: true
    # }
