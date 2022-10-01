import './styles.css';
import { Renderer, Program, Clock } from 'gl-layer';
import frag from './frag.glsl';

const W = 1000;
const H = 1000;

const clock = new Clock();

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
    program.setUniform('uTime', clock.time);
    renderer.render(program);
    requestAnimationFrame(render);
}
