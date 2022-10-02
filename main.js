import './styles.css';
import { Renderer, Program } from 'gl-layer';
import frag from './frag.glsl';

const W = 1000;
const H = 1000;

const keyMap = {};

const renderer = new Renderer(document.createElement('canvas'), { preserveDrawingBuffer: true });

init();
addEventHandlers();

function init() {
    handleResize();
    render();
}

function addEventHandlers() {
    window.addEventListener('resize', handleResize);
    window.addEventListener('keydown', handleKey);
    window.addEventListener('keyup', handleKey);
}

function handleResize() {
    renderer.setSize(W, H);
}

function handleKey(event) {
    keyMap[event.key] = event.type === 'keydown';
    if (keyMap.Meta && keyMap.s) {
        event.preventDefault();
        renderer.element.toBlob((blob) => {
            const link = document.createElement('a');
            link.download = `render_${Date.now()}.png`;
            link.href = URL.createObjectURL(blob);
            link.click();
            URL.revokeObjectURL(link.href);
        });
    }
}

function render() {
    const program = new Program(frag);
    renderer.render(program);
}
