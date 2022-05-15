import 'dart:convert';
import 'dart:math';
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_forge2d/body_component.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame_forge2d/forge2d_game.dart';
//import 'package:flutter/services.dart';
import 'package:sipl_client/boundaries.dart';

Vector2 vec2Median(List<Vector2> vecs) {
  var sum = Vector2(0, 0);
  for (final v in vecs) {
    sum += v;
  }
  return sum / vecs.length.toDouble();
}

Vector2 strToVec2(String vec) {
  return Vector2(
      double.parse(vec.split(', ')[0]), double.parse(vec.split(', ')[1]));
}

class MyGame extends Forge2DGame with MultiTouchDragDetector, HasTappables {
  MouseJoint? mouseJoint;
  static late BodyComponent grabbedBody;
  late Body groundBody;
  late String jsonPath;
  MyGame(this.jsonPath) : super(gravity: Vector2(0, -10.0));
  late double scale;
  //Game onLoad
  @override
  Future<void> onLoad() async {
    //final center = screenToWorld(camera.viewport.effectiveSize / 2);
    final bottomRight = screenToWorld(camera.viewport.effectiveSize);
    //final upper_left = Vector2(0, 0);
    //final bottom_left = Vector2(upper_left.x, bottom_right.y);
    scale = bottomRight.length / 271;
    var dummyForMouseJoint =
        Ball(Vector2(-5, 5) * scale, 0.1 * scale, bodyType: BodyType.static);
    await add(dummyForMouseJoint);
    grabbedBody = dummyForMouseJoint;
    final data = await json.decode(await File(jsonPath).readAsString());
    //Adding tringles
    var trigList = <Polygon>[];
    for (var trig in data["Triangles"]) {
      var ver = [
        strToVec2(trig["A"]) * scale,
        strToVec2(trig["B"]) * scale,
        strToVec2(trig["C"]) * scale
      ];
      var centerOfMass = vec2Median(ver);
      //Polygon is created around center of mass so we have to shift the vertecies back in order to create them in relation to upper_left
      ver = [
        strToVec2(trig["A"]) * scale - centerOfMass,
        strToVec2(trig["B"]) * scale - centerOfMass,
        strToVec2(trig["C"]) * scale - centerOfMass
      ];
      Polygon pol = Polygon(centerOfMass, ver, bodyType: BodyType.dynamic);
      trigList.add(pol);
      await add(pol);
    }

    var blockList = <Polygon>[];
    for (var block in data["Blocks"]) {
      var ver = [
        strToVec2(block["A"]) * scale,
        strToVec2(block["B"]) * scale,
        strToVec2(block["C"]) * scale,
        strToVec2(block["D"]) * scale
      ];
      var centerOfMass = vec2Median(ver);
      //Polygon is created around center of mass so we have to shift the vertecies back in order to create them in relation to upper_left
      ver = [
        strToVec2(block["A"]) * scale - centerOfMass,
        strToVec2(block["B"]) * scale - centerOfMass,
        strToVec2(block["C"]) * scale - centerOfMass,
        strToVec2(block["D"]) * scale - centerOfMass
      ];
      Polygon pol = Polygon(centerOfMass, ver,
          bodyType: block["IsStatic"] ? BodyType.static : BodyType.dynamic);
      blockList.add(pol);
      await add(pol);
    }

    var wallList = <Polygon>[];
    for (var wall in data["Walls"]) {
      var start = strToVec2(wall["A"]) * scale;
      var end = strToVec2(wall["B"]) * scale;
      Vector2 O =
          Vector2(start.y - end.y, end.x - start.x) / ((end - start).length);
      var ver = [start + O, end + O, start - O, end - O];
      var centerOfMass = vec2Median(ver);
      //Polygon is created around center of mass so we have to shift the vertecies back in order to create them in relation to upper_left
      ver = [
        start + O - centerOfMass,
        end + O - centerOfMass,
        start - O - centerOfMass,
        end - O - centerOfMass
      ];
      Polygon pol = Polygon(centerOfMass, ver, bodyType: BodyType.static);
      wallList.add(pol);
      await add(pol);
    }

    var cartList = <Polygon>[];
    for (var cart in data["Carts"]) {
      var ver = [
        strToVec2(cart["A"]) * scale,
        strToVec2(cart["B"]) * scale,
        strToVec2(cart["C"]) * scale,
        strToVec2(cart["D"]) * scale
      ];
      var centerOfMass = vec2Median(ver);
      //Polygon is created around center of mass so we have to shift the vertecies back in order to create them in relation to upper_left
      ver = [
        strToVec2(cart["A"]) * scale - centerOfMass,
        strToVec2(cart["B"]) * scale - centerOfMass,
        strToVec2(cart["C"]) * scale - centerOfMass,
        strToVec2(cart["D"]) * scale - centerOfMass
      ];
      Polygon pol = await makeCart(centerOfMass, ver, (cart["radius"] * scale),
          strToVec2(cart["wheel1"]) * scale, strToVec2(cart["wheel2"]) * scale);
      cartList.add(pol);
      //await add(pol);
    }

    var ballList = <Ball>[];
    for (var ball in data["Balls"]) {
      Ball b = Ball(strToVec2(ball["Center"]) * scale, ball["Radius"] * scale,
          bodyType: ball["IsStatic"] ? BodyType.static : BodyType.dynamic);
      ballList.add(b);
      await add(b);
    }

    for (var spring in data["Springs"]) {
      var connectionA = <TappableBodyComponent>[];
      switch (spring["connectionA"]) {
        case "Carts":
          connectionA = cartList;
          break;
        case "Balls":
          connectionA = ballList;
          break;
        case "Walls":
          connectionA = wallList;
          break;
        case "Blocks":
          connectionA = blockList;
          break;
        case "Triangles":
          connectionA = trigList;
          break;
        default:
      }
      var connectionB = <TappableBodyComponent>[];
      switch (spring["connectionB"]) {
        case "Carts":
          connectionB = cartList;
          break;
        case "Balls":
          connectionB = ballList;
          break;
        case "Walls":
          connectionB = wallList;
          break;
        case "Blocks":
          connectionB = blockList;
          break;
        case "Triangles":
          connectionB = trigList;
          break;
        default:
      }
      var body1 = connectionA[spring["indexA"]];
      var body2 = connectionB[spring["indexB"]];
      world.createJoint(DistanceJointDef()
        ..initialize(
            body1.body, body2.body, body1.centerOfMass, body2.centerOfMass)
        ..dampingRatio = 0.0
        ..frequencyHz =
            (1 / (2 * pi) * sqrt(50 / (body2.body.mass + body1.body.mass))));
    }

    super.onLoad();
    final boundaries = createBoundaries(this); //Adding boundries
    boundaries.forEach(add);

    groundBody = world.createBody(BodyDef());
    // 271 is a convinient number to have nice constents while developing on my 14" laptop
  }

  //Expects scaled values
  Future<Polygon> makeCart(Vector2 centerOfMass, List<Vector2> verteces,
      double wheelRadius, Vector2 wheel1Pos, Vector2 wheel2Pos,
      {BodyType bodyType = BodyType.dynamic}) async {
    var wheel1 = Ball(wheel1Pos, wheelRadius, bodyType: bodyType);
    await add(wheel1);
    var wheel2 = Ball(wheel2Pos, wheelRadius, bodyType: bodyType);
    await add(wheel2);
    final cartRect = Polygon(centerOfMass, verteces, bodyType: bodyType);
    await add(cartRect);

    world.createJoint(RevoluteJointDef()
      ..initialize(cartRect.body, wheel1.body, wheel1.centerOfMass));
    world.createJoint(RevoluteJointDef()
      ..initialize(cartRect.body, wheel2.body, wheel2.centerOfMass));
    return cartRect;
  }

  //For mouseJoint
  @override
  bool onDragUpdate(int pointerId, DragUpdateInfo info) {
    final mouseJointDef = MouseJointDef()
      ..maxForce = 3000 * grabbedBody.body.mass * 10 //Not neccerly needed
      ..dampingRatio = 1
      ..frequencyHz = 5
      ..target.setFrom(grabbedBody.body.position)
      ..collideConnected = false //Maybe set to true
      ..bodyA = groundBody
      ..bodyB = grabbedBody.body;

    mouseJoint ??= world.createJoint(mouseJointDef) as MouseJoint;

    mouseJoint?.setTarget(info.eventPosition.game);
    return false;
  }

  //For mouseJoint
  @override
  bool onDragEnd(int pointerId, DragEndInfo info) {
    if (mouseJoint == null) {
      return true;
    }
    world.destroyJoint(mouseJoint!);
    mouseJoint = null;
    return false;
  }
}

///Abstract class that encapsulate all rigid bodies properties
abstract class TappableBodyComponent extends BodyComponent with Tappable {
  final Vector2 centerOfMass;
  final BodyType bodyType;
  TappableBodyComponent(this.centerOfMass, {this.bodyType = BodyType.dynamic});

  @override
  bool onTapDown(info) {
    MyGame.grabbedBody = this;
    return false;
  }

  Body tappableBCreateBody(Shape shape) {
    final fixtureDef = FixtureDef(shape)
      ..restitution = 0.8
      ..density = 1.0
      ..friction = 1;

    final bodyDef = BodyDef()
      // To be able to determine object in collision
      ..userData = this
      ..angularDamping = 0.8
      ..position = centerOfMass
      ..type = bodyType;

    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }
}

class Ball extends TappableBodyComponent {
  final double radius;

  Ball(Vector2 position, this.radius, {BodyType bodyType = BodyType.dynamic})
      : super(position, bodyType: bodyType);

  @override
  Body createBody() {
    final shape = CircleShape();
    shape.radius = radius;
    return tappableBCreateBody(shape);
  }
}

///Polygon class, remember to place veteces around offset so MouseJoint will work correctly
class Polygon extends TappableBodyComponent {
  final List<Vector2> vertecies;

  Polygon(Vector2 centerOfMass, this.vertecies,
      {BodyType bodyType = BodyType.dynamic})
      : super(centerOfMass, bodyType: bodyType);

  @override
  Body createBody() {
    final shape = PolygonShape()..set(vertecies);
    return tappableBCreateBody(shape);
  }
}
