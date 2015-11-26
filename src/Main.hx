package;

import haxe.macro.Type.FieldKind;
import haxe.Timer;
import js.Browser;
import js.html.audio.GainNode;
import pixi.core.display.Container;
import pixi.plugins.NapeHelpers;
import tones.utils.NoteFrequencyUtil;

import nape.callbacks.CbEvent;
import nape.callbacks.InteractionCallback;
import nape.callbacks.InteractionListener;
import nape.callbacks.InteractionType;
import nape.geom.Vec2;
import nape.space.Space;

import pixi.plugins.app.NapeApplication;

import tones.AudioBase;
import tones.data.OscillatorType;
import tones.Tones;



/**
 * ...
 * @author Mike Almond - https://github.com/mikedotalmond
 */

class Main extends NapeApplication {

	var tones:Tones;
	var outGain:GainNode;
	
	var noteIndex:Int = -1;
	var notes:Array<Int> = [];
	var freqs:Array<Float> = [];
	//
	var container:Container;
	
	public function new() {
		noteUtils = new NoteFrequencyUtil();
		super(Browser.document.getElementById('pixi-container'), new Space(Vec2.get(0, 10000)), AudioBase.createContext());
	}
	
	override function setup() {
		
		renderer.backgroundColor = 0x1C1D37;
		
		notes = [for (i in 0...12) 32 + Std.int(Math.random() * 18) ]; // 1.5 octave range
		
		for (note in 0...notes.length) freqs.push(noteUtils.noteIndexToFrequency(notes[Std.int(Math.random()*notes.length)]));
		
		
		// setup pixi
		container = new Container();
		stage.addChild(container);
		container.scale.set(.75);
		// setupAudio
		outGain = audioContext.createGain();
		outGain.gain.value = 1.0;
		outGain.connect(audioContext.destination);
		
		tones = new Tones(audioContext, outGain);
		tones.type = OscillatorType.SAWTOOTH;
		tones.attack = 0.02;
		tones.release = 0.25;
		tones.volume = 0;	
		
		//
		createMetronomes();
		//container.scale.set(.8);
		Timer.delay(resize, 1);
		
		Timer.delay(function() {
			for (m in metronomes) m.applyStartForce();
		}, 2500);
	}
	
	override function updateSpace(dt:Float) {
		for (m in metronomes) m.update(dt);
	}
	
	override function draw(dt:Float) {
		for (m in metronomes) m.draw(dt);
	}
	
	override function resize() {
		//container.scale.set();
		//width / height;
		
		container.x = width / 2 - container.width / 2;
		container.y = height / 2 - container.height / 2;
	}
	
	
	function createMetronomes() {
		
		metronomes = [];
		var py = 240;
		var px = 0;
		for (i in 0...5) {
			metronomes[i] = new Metronome(i, px, py, space);
			metronomes[i].setTuneAnchorPosition(.001 +  0.01 * i);
			container.addChild(metronomes[i].graphics);
			px += 215;
		}
			
		//px = 0;
		//py += 440;		
		//for (i in 0...6) {
			//metronomes[6+i] = new Metronome(i, px, py, space);
			//metronomes[6+i].setTuneAnchorPosition(1 - 0.005 * i);
			//container.addChild(metronomes[6+i].graphics);
			//px += 220;
		//}
		
		tickListener = new InteractionListener(CbEvent.BEGIN, InteractionType.SENSOR, Metronome.barCbType, Metronome.sensorCbType, tickSensorHandler);		
		space.listeners.add(tickListener);
	}
	
	var maxTickVelocity:Float = 1400;
	var tickListener:InteractionListener;
	var metronomes:Array<Metronome>;
	var noteUtils:tones.utils.NoteFrequencyUtil;
	
	function tickSensorHandler(cb:InteractionCallback):Void {
		
		var m:Metronome = cb.int2.userData.metronome;
		
		m.tick(freqs.length);
		
		var f = freqs[m.tickIndex];
		
		var n:Float = 1 - (m.index / metronomes.length);
		
		tones.volume = .025 + .5 * n*n*n*n;
		tones.attack = .005 + (1-n) * (1-n) * .5;
		//tones.release = .25 + (1-(n*n*n*n));
		
		f = noteUtils.detune(f, 1200 * m.index + NapeHelpers.rRange(4));
		
		tones.playFrequency(f);
		
	}
	
	
	static function main() new Main();
}