import { Renderer, Program } from 'gl-layer'

import fragment from './shaders/screen.glsl'

const width = 1000
const height = 1000

const keyMap = {}

const renderer = new Renderer(document.createElement('canvas'), { preserveDrawingBuffer: true })

init()
addEventHandlers()

function init() {
    handleResize()
    render()
}

function addEventHandlers() {
    window.addEventListener('resize', handleResize)
    window.addEventListener('keydown', handleKey)
    window.addEventListener('keyup', handleKey)
}

function handleResize() {
    renderer.setSize(width, height)
}

function handleKey(event) {
    keyMap[event.key] = event.type === 'keydown'
    if (keyMap.Meta && keyMap.s) {
        event.preventDefault()
        renderer.element.toBlob((blob) => {
            const link = document.createElement('a')
            link.download = `render_${Date.now()}.png`
            link.href = URL.createObjectURL(blob)
            link.click()
            URL.revokeObjectURL(link.href)
        })
    }
}

function render() {
    const program = new Program(fragment)
    renderer.render(program)
}
