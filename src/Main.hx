package;

import js.Browser;
import js.html.audio.AudioBuffer;
import js.html.audio.AudioContext;
import js.html.audio.GainNode;
import pixi.plugins.app.Application;

import tones.AudioBase;
import tones.data.OscillatorType;
import tones.Tones;
import tones.utils.NoteFrequencyUtil;
import tones.utils.TimeUtil;



/**
 * ...
 * @author Mike Almond - https://github.com/mikedotalmond
 */

class Main extends Application {

	static function main()  new Main();
	
	var tones:Tones;
	
	var restartId:Int;
	var buffer:AudioBuffer;
	var outGain:GainNode;
	var ctx:AudioContext;
	
	public function new() {
		
		super();
		initPixi();
		initAudio();
	}
	
	function initPixi() {
		backgroundColor = 0x0a0a1a;
		start(null, Browser.document.getElementById('pixi-container'));
	}
	
	function initAudio() {
		
		
		ctx = AudioBase.createContext();
		outGain = ctx.createGain();
		outGain.gain.value = .7;
		outGain.connect(ctx.destination);
		
		tones = new Tones(ctx, outGain);
		tones.type = OscillatorType.SINE;
		tones.attack = 0.01;
		tones.release = .1;
		tones.volume = .25;
		playSequence(0);
	}
	
	function playSequence(delay:Float=0) {
		tones.playFrequency(440, delay + TimeUtil.stepTime(.5));
		tones.playFrequency(440, delay + TimeUtil.stepTime(1));
		tones.playFrequency(440, delay + TimeUtil.stepTime(1.5));
		tones.playFrequency(440, delay + TimeUtil.stepTime(2));
		tones.playFrequency(440, delay + TimeUtil.stepTime(2.5));
		tones.playFrequency(440, delay + TimeUtil.stepTime(3));
		tones.playFrequency(440, delay + TimeUtil.stepTime(3.5));
	}
}