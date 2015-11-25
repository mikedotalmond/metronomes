package;

import haxe.Timer;
import nape.shape.Polygon;
import napetools.NapeHelpers;

import nape.callbacks.CbEvent;
import nape.callbacks.CbType;
import nape.callbacks.InteractionListener;
import nape.callbacks.InteractionType;
import nape.constraint.PivotJoint;
import nape.constraint.WeldJoint;
import nape.dynamics.InteractionGroup;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.phys.Compound;
import nape.phys.Material;
import nape.shape.Circle;
import nape.shape.Shape;
import nape.space.Space;

import pixi.core.display.Container;
import pixi.core.graphics.Graphics;

/**
 * ...
 * @author Mike Almond - https://github.com/mikedotalmond
 */
class Metronome {

	static inline var WEIGHT_HEIGHT	:Float = 16.0;
	static inline var BAR_LENGTH	:Float = 300.0;
	
	static public var sensorCbType	(default, null):CbType = new CbType();
	static public var barCbType		(default, null):CbType = new CbType();
	
	var space:Space;
	
	public var pivotBall	(default, null):Body;
	public var massBall		(default, null):Body;
	public var tuneWeight	(default, null):Body;
	public var bar			(default, null):Body;
	
	public var pivot		(default, null):PivotJoint;
	public var massWeld		(default, null):WeldJoint;
	public var tuneWeld		(default, null):WeldJoint;
	
	public var tickSensor	(default, null):Body;
	var ticked:Bool = false;
	
	public var tuneAnchorPosition:Float;
	
	public var graphics(default, null):Graphics;
	
	var _x:Float; var _y:Float;
	
	public var x(get, set):Float;
	public var y(get, set):Float;
	public var index(default, null):Int;
	public var massVelocityX(get, set):Float;
	
	public function new(index:Int, x:Float, y:Float, space:Space) {
	
		this.index = index;
		this.space = space;
		
		graphics = new Graphics();
		
		_x = x;
		_y = y;
		
		setup();
	}
	
	public function setup() {
		
		var b:Body;
		var px:Float;
		var py:Float;
		
		// new Material(0.2, 0.57, 0.74, 7.85, 0.001); //rolled steel - 7850 kg/m3
		// steel = new Material(0.2,0.57,0.74,7.8,0.001)
		// http://www.csgnetwork.com/specificgravmettable.html
		
		var compound:Compound = new Compound();
		
		px = _x;
		py = _y - 100;
		
		// bar
		b = NapeHelpers.createBox(BodyType.DYNAMIC, px, py, 5, BAR_LENGTH);
		b.setShapeMaterials(new Material(0.2, 0.57, 0.74, 2.7, 0.001)); // aluminium
		b.group = new InteractionGroup(false);
		//b.shapes.at(0).sensorEnabled = true;
		b.cbTypes.add(barCbType);
		b.compound = compound;
		bar = b;
		
		// mass ball
		py = _y + 100;
		b = NapeHelpers.createCircle(BodyType.DYNAMIC, px, py, 32);
		b.setShapeMaterials(new Material(0, 0.57, 0.84, 11.34, 0.01)); // lead - 11340 kg/m3
		b.compound = compound;
		massBall = b;
		
		// pivot
		py = _y;
		b = NapeHelpers.createCircle(BodyType.KINEMATIC, px, py, 8);
		b.compound = compound;
		pivotBall = b;
		
		// tuning weight
		py = _y - 100;
		b = NapeHelpers.createCircle(BodyType.DYNAMIC, px, py, WEIGHT_HEIGHT);
		b.setShapeMaterials(new Material(0, 0.57, 0.84, 11.34, 0.01)); // lead - 11340 kg/m3
		b.compound = compound;
		tuneWeight = b;
		
		// 
		pivot = new PivotJoint(pivotBall, bar, Vec2.weak(), Vec2.weak(0, BAR_LENGTH / 4));
		pivot.compound = compound;
		pivot.ignore = true;
		pivot.stiff = true;
		pivot.damping = 0;
		
		massWeld = new WeldJoint(massBall, bar, Vec2.weak(), Vec2.weak(0, BAR_LENGTH / 2));
		massWeld.compound = compound;
		massWeld.ignore = true;
		massWeld.stiff = true;
		massWeld.damping = 0;
		
		tuneWeld = new WeldJoint(tuneWeight, bar, Vec2.weak(), Vec2.weak());
		tuneWeld.compound = compound;
		tuneWeld.ignore = true;
		tuneWeld.stiff = true;
		tuneWeld.damping = 0;
		
		// sensor
		var tickSensorShape = new Circle(1);
		tickSensorShape.sensorEnabled = true;
		
		tickSensor = new Body(BodyType.KINEMATIC, Vec2.weak(_x, _y - BAR_LENGTH / 2));
		tickSensor.shapes.add(tickSensorShape);
		tickSensor.group = bar.group;
		tickSensor.compound = compound;
		tickSensor.cbTypes.add(sensorCbType);
		tickSensor.userData.metronome = this;
		
		compound.space = space;
		
		this.x = _x;
		this.y = _y;
		
		tuneAnchorPosition = -1;
		setTuneAnchorPosition(0.5);
	}
	
	public function applyStartForce() {
		massBall.applyImpulse(Vec2.weak(8192, 0));
	}
	
	public var tickIndex(default,null):Int = -1;
	public function tick(n:Int) {
		tickIndex = (tickIndex + 1) % n;

		var v = massVelocityX;
		massBall.applyImpulse(Vec2.weak(42 * (v > 0?1: -1), 0));
		
		ticked = true;
	}
	
	public function update(dt:Float) {
		
	}
	
	public function draw(dt:Float) {
		
		graphics.clear();
		
		
		//var c = 
		//if (ticked) {
			//}
			
		
		var v = tickIndex / 12;
		var c = Std.int((v * .9) * 0xff);
		c = c << 16 | c << 8 | c;
		
		
		
		var poly:Polygon = bar.shapes.at(0).castPolygon;
		var vertices = poly.worldVerts;
		var position = vertices.at(0);
		
		graphics.beginFill(c);
		graphics.moveTo(position.x, position.y);
		for (i in 1...vertices.length) {
			position = vertices.at(i);
			graphics.lineTo(position.x, position.y);
		}
		position = vertices.at(0);
		graphics.lineTo(position.x, position.y);
		graphics.endFill();
		
		// mass ball
		graphics.beginFill(0xBACAEF);
		graphics.drawCircle(massBall.position.x, massBall.position.y, 32);
		graphics.endFill();
		
		// pivot
		graphics.beginFill(0x292B54);
		graphics.drawCircle(pivotBall.position.x, pivotBall.position.y, 8);
		graphics.endFill();
		
		// tune
		graphics.beginFill(0xaaffaa);
		graphics.drawCircle(tuneWeight.position.x, tuneWeight.position.y, 16);
		graphics.endFill();
		
		ticked = false;	
	}
	
	
	
	inline function set_massVelocityX(value):Float return massBall.velocity.x = value;
	inline function get_massVelocityX():Float return massBall.velocity.x;
	
	inline function get_x():Float return _x;
	function set_x(value:Float):Float {
		return tickSensor.position.x = pivotBall.position.x = _x = value;
	}
	
	inline function get_y():Float return _y;
	function set_y(value:Float):Float {
		tickSensor.position.y = value - BAR_LENGTH / 2;
		return pivotBall.position.y = _y = value;
	}
	
	public function setTuneAnchorPosition(value:Float) {
		if (value != tuneAnchorPosition) {
			var max = -BAR_LENGTH / 2;
			var min = pivot.anchor2.y - WEIGHT_HEIGHT / 2 - 16;
			tuneWeld.anchor2.y = min + value * (max - min);
			tuneAnchorPosition = value;
		}
	}
}