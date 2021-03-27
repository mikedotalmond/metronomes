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
import pixi.core.graphics.Graphics;
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
	
	var tickListener:InteractionListener;
	var metronomes:Array<Metronome>;
	var noteUtils:tones.utils.NoteFrequencyUtil;
	var phase:Float = -Math.PI / 2;
	
	
	public function new() {
		
		NapeApplication.FixedTimeStep = 1 / 60;
		NapeApplication.VelocityIterationsPerTimeStep = 20;
		NapeApplication.PositionIterationsPerTimeStep = 20;
		
		noteUtils = new NoteFrequencyUtil();
		
		super(Browser.document.getElementById('pixi-container'), new Space(Vec2.get(0, 10000)), AudioBase.createContext());
		
	}
	
	override function setup() {
		
		// setup pixi
		container = new Container();
		stage.addChild(container);
		trace(container.width, container.height);
		//container.scale.set(.75);
		renderer.backgroundColor = 0x10101F;
		
		// setup audio
		selectFreqs();
		
		outGain = audioContext.createGain();
		outGain.gain.value = .5;
		outGain.connect(audioContext.destination);
		
		tones = new Tones(audioContext, outGain);
		tones.type = OscillatorType.SAWTOOTH;
		tones.attack = 0.05;
		tones.release = 0.25;
		tones.volume = 0;	
		
		// 
		createMetronomes();
		Timer.delay(function() {
			for (m in metronomes) m.applyStartForce();
		}, 2000);
	}
	
	
	function selectFreqs(){	
		freqs = [for (i in 0...12) noteUtils.noteIndexToFrequency(54 + Std.int(Math.random() * 17))];
	}
	
	
	override function resize() {
		
		container.scale.set(Math.min(width / 1440.0, height / 440.0));
		
		//trace(container.width, container.height);
		
		container.x = width / 2 - container.width / 2;
		container.y = height / 2 - container.height / 2;
		
	}
	
	var lastPhase:Float = 0.0;
	var lastDirection = 1;
	
	override function updateSpace(dt:Float) {
		for (m in metronomes) {
			m.update(dt);
			phase += .0001;
			var p = Math.sin(phase) + 1;
			m.setTuneAnchorPosition(.01 + .01 * m.index + .48 * (p));
			
			if (m.index == 0){
				var d = (p - lastPhase) < 0 ? -1 : 1;
				
				if (d != lastDirection){
					//trace("new notes please");
					selectFreqs();
				}
				
				lastDirection = d;
				lastPhase = p;
				
			}
		}
	}
	
	override function draw(dt:Float) {		
		for (m in metronomes) m.draw(dt);
	}
	
	var g = new Graphics();
	function createMetronomes() {
		
		container.addChild(g);
		g.lineStyle(2, 0x2F0000);
		g.moveTo(32, 235);
		g.lineTo(215*5+32, 235);
		
		metronomes = [];
		var py = 235;
		var px = 32;
		for (i in 0...6) {
			metronomes[i] = new Metronome(i, px, py, space);
			metronomes[i].setTuneAnchorPosition(.001 +  0.01 * i);
			container.addChild(metronomes[i].graphics);
			px += 215;
		}
		
		tickListener = new InteractionListener(CbEvent.BEGIN, InteractionType.SENSOR, Metronome.barCbType, Metronome.sensorCbType, tickSensorHandler);		
		space.listeners.add(tickListener);
	}
	

	function tickSensorHandler(cb:InteractionCallback):Void {
		
		var m:Metronome = cb.int2.userData.metronome;
		
		m.tick(freqs.length);
		
		var f = freqs[m.tickIndex];
		
		var x:Float = (m.index / metronomes.length);
		var x1:Float = 1 - x;
		
		tones.volume = .025 + .25 * x1 * x1 * x1 * x1;
		tones.attack = .025 + x * x * .5;
		tones.release = .2 + x * .5;
		
		if (m.index > 1) tones.volume *= .8;
		
		f = noteUtils.detune(f, 1200 * Std.int(m.index/2) + NapeHelpers.rRange(8));
		
		tones.playFrequency(f);
	}
	
	
	static function main() new Main();
}