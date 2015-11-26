package;

import haxe.Timer;
import js.Browser;
import js.html.audio.GainNode;
import nape.callbacks.CbEvent;
import nape.callbacks.InteractionCallback;
import nape.callbacks.InteractionListener;
import nape.callbacks.InteractionType;
import nape.geom.Vec2;
import nape.space.Space;
import pixi.core.display.Container;
import pixi.plugins.app.NapeApplication;
import pixi.plugins.NapeHelpers;
import tones.AudioBase;
import tones.data.OscillatorType;
import tones.Tones;
import tones.utils.NoteFrequencyUtil;



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
		
		
		// setup pixi
		container = new Container();
		stage.addChild(container);
		container.scale.set(.75);
		renderer.backgroundColor = 0x10101F;
		
		
		// setup audio
		notes = [for (i in 0...12) 48 + Std.int(Math.random() * 16) ]; // 12 random notes in a 1 octave range
		for (note in 0...notes.length) freqs.push(noteUtils.noteIndexToFrequency(notes[Std.int(Math.random()*notes.length)]));
		
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
		
		Timer.delay(function() {
			for (m in metronomes) m.applyStartForce();
		}, 2500);
	}
	
	override function updateSpace(dt:Float) {
		for (m in metronomes) {
			m.update(dt);
			phase += .0001;
			m.setTuneAnchorPosition(.01 + .01 * m.index + .48*(Math.sin(phase)+1));
		}
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
		for (i in 0...9) {
			metronomes[i] = new Metronome(i, px, py, space);
			metronomes[i].setTuneAnchorPosition(.001 +  0.01 * i);
			container.addChild(metronomes[i].graphics);
			px += 215;
		}
		
		tickListener = new InteractionListener(CbEvent.BEGIN, InteractionType.SENSOR, Metronome.barCbType, Metronome.sensorCbType, tickSensorHandler);		
		space.listeners.add(tickListener);
	}
	
	var maxTickVelocity:Float = 1400;
	var tickListener:InteractionListener;
	var metronomes:Array<Metronome>;
	var noteUtils:tones.utils.NoteFrequencyUtil;
	var playCount:Int = 0;
	var phase:Float = -Math.PI/2;
	function tickSensorHandler(cb:InteractionCallback):Void {
		
		var m:Metronome = cb.int2.userData.metronome;
		
		var n = freqs.length;
		if (m.index==0 && m.tickIndex == n-1) {
			var r = .01 + Math.random() * Math.random() * .99;
			//for (mm in metronomes) mm.setTuneAnchorPosition(r + (mm.index * .01));
			//for (m in metronomes) m.setTuneAnchorPosition(1 - (.001 + m.index * 0.005 + (playCount / (n * 1.5))));			
			playCount = (playCount + 1) % n;
		}
			
		m.tick(freqs.length);
		
		var f = freqs[m.tickIndex];
		
		var x:Float = 1 - (m.index / metronomes.length);
		
		tones.volume = .025 + .5 * x * x * x * x;
		tones.attack = .005 + (1-x) * (1-x) * .5;
		tones.release = .2 + (1-x) * .25;
		//tones.release = .25 + (1-(n*n*n*n));
		
		f = noteUtils.detune(f, 300 * m.index + NapeHelpers.rRange(4));
		
		tones.playFrequency(f);
		
	}
	
	
	static function main() new Main();
}