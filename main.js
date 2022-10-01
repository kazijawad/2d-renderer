import './styles.css';
import { Renderer, Program } from 'gl-layer';
import frag from './frag.glsl';

const W = 1000;
const H = 1000;

const renderer = new Renderer();

init();
addEventHandlers();

function init() {
    handleResize();
    render();
}

function addEventHandlers() {
    window.addEventListener('resize', handleResize);
}

function handleResize() {
    renderer.setSize(W, H);
}

function render() {
    const program = new Program(frag);
    renderer.render(program);
}
