package pixi.plugins.app;

/**
 * ...
 * @author Mike Almond - https://github.com/mikedotalmond
 */

import js.html.audio.AudioContext;
import js.html.Element;
import nape.geom.Vec2;
import nape.space.Space;
import pixi.plugins.app.Application;

import tones.AudioBase;

class NapeApplication extends Application { 
	
	static public var FixedTimeStep					:Float	= 1.0 / 60.0;
	static public var PositionIterationsPerTimeStep	:Int 	= 50;
	static public var VelocityIterationsPerTimeStep	:Int 	= 50;
	
	public var space		(default, null):Space;
	public var audioContext	(default, null):AudioContext;
	
	var cumalativeDt:Float;
	
	function new(domContainer:Element=null, space:Space = null, audioContext:AudioContext=null) {	
		
		super();
		
		initNape(space);
		initPixi(domContainer);
		initAudio(audioContext);
		
		setup();
		
		onUpdate = tick;
		onResize = resize;
		
		resize();
	}
	
	
	function initPixi(domContainer:Element = null) {
		antialias = true;
		start(null, domContainer);
	}
	
	
	function initNape(space:Space) {
		this.space = space == null ? new Space(Vec2.get(0, 0)) : space;
		cumalativeDt = .0;
	}
	
	
	function initAudio(audioContext:AudioContext) {
		if (audioContext == null) audioContext = AudioBase.createContext();
		this.audioContext = audioContext;
	}
	
	
	function tick(dt:Float) {
		updateSpace(dt);
		
		cumalativeDt += dt;
		while (cumalativeDt >= FixedTimeStep) {
			space.step(FixedTimeStep, VelocityIterationsPerTimeStep, PositionIterationsPerTimeStep);
			cumalativeDt -= dt;
		}
		
		draw(dt);
	}
	
	function setup() { }
	function updateSpace(dt:Float) { }	
	function draw(dt:Float) { }
	function resize() { }
}