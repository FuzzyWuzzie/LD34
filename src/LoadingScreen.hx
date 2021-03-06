import tusk.debug.Log;
import tusk.lib.comp.TextComponent;
import tusk.lib.comp.*;
import tusk.lib.proc.*;
import tusk.Tusk;
import tusk.Scene;
import tusk.Entity;
import tusk.resources.*;

import promhx.Promise;

import glm.Vec2;
import glm.Vec3;
import glm.Quat;
import glm.Vec4;

import tusk.events.*;

class LoadingScreen extends Scene {
	private var gameName:String;
	private var loadingDone:Promise<Scene>;

	public function new(gameName:String, loadingDone:Promise<Scene>) {
		this.gameName = gameName;
		this.loadingDone = loadingDone;
		super('LoadingScreen');
	}

	private static var salutations:Array<String> = ['Mr.', 'Mrs.', 'Ms.', 'Dr.', 'The'];
	private static var adjectives:Array<String> = ['Purple', 'Green', 'Fast', 'Slow', 'Time-Travelling', 'Time Traveller\'s', 'Clever',
		'Clumsy', 'Thrifty', 'Quick', 'Cranky', 'Lumpy', 'Polite', 'Sparkling', 'Sturdy', 'Creaky', 'Odd', 'Friendly'];
	private static var nouns:Array<String> = ['Wife', 'Husband', 'Son', 'Daughter', 'Lawyer', 'Swordfish', 'Squid', 'Cheetah', 'Space-man',
		'Cosmonaut', 'Apprentice', 'Champ', 'Pancake', 'Chicken', 'Unicorn', 'Bunny', 'Gnome', 'Mermaid'];
	private function generateName():String {
		var s:StringBuf = new StringBuf();
		s.add(salutations[tusk.math.Random.int(0, salutations.length - 1)]);
		s.add(' ');
		s.add(adjectives[tusk.math.Random.int(0, adjectives.length - 1)]);
		s.add(' ');
		s.add(nouns[tusk.math.Random.int(0, nouns.length - 1)]);
		return s.toString();
	}

	override public function onLoad(event:LoadEvent) {
		if(event.scene != this) return;
		Log.info("load screen..");

		// load the resources
		Promise.when(
			tusk.defaults.Primitives.loadTextMesh(),
			tusk.defaults.Fonts.loadSubatomic_Screen(),
			tusk.defaults.Materials.loadTextBasic(),
			tusk.defaults.Primitives.loadQuad(),
			tusk.defaults.Materials.loadEffectCircleOut(),
			Tusk.assets.loadSound(tusk.Files.sounds___loadingcrunch__ogg),
			Tusk.assets.loadSound(tusk.Files.sounds___introwobble__ogg),
			Tusk.assets.loadSound(tusk.Files.sounds___introtrumpet__ogg),
			tusk.defaults.Materials.loadUnlitColoured()
		).then(function(textMesh:Mesh, font:Font, fontMat:Material, quad:Mesh, circleOutMat:Material, loadingCrunch:Sound, introWobble:Sound, trumpet:Sound, bgMaterial:Material) {
			Camera2DProcessor.cameras = new Array<Camera2DComponent>();
			// set the material's texture
			fontMat.textures = new Array<Texture>();
			fontMat.textures.push(font.texture);

			// load processors
			this.useProcessor(new TimedPromiseProcessor());
			this.useProcessor(new MaterialProcessor());
			this.useProcessor(new Camera2DProcessor());
			this.useProcessor(new loading.SlamProcessor());
			this.useProcessor(new loading.SlideProcessor());
			this.useProcessor(new TransformProcessor());
			this.useProcessor(new TextProcessor());
			this.useProcessor(new MeshProcessor());
			this.useProcessor(new Renderer2DProcessor(new Vec4(0.25, 0.25, 0.25, 1.0)));
			this.useProcessor(new CircleEffectRendererProcessor());
			this.useProcessor(new SoundProcessor());

			// create the camera
			var w:Float = Tusk.instance.app.window.width;
			var h:Float = Tusk.instance.app.window.height;
			entities.push(new Entity(this, 'Camera', [
				new TransformComponent(),
				new Camera2DComponent(new Vec2(w, h) / -2.0, new Vec2(w, h) / 2.0, -100, 100)
			]));

			// create the background
			var bgMesh:Mesh = quad.clone('mesh.bgintro');
			bgMesh.colours = new Array<Vec4>();
			var gradientColours:Array<Vec4> = Util.randomGradientColours();
			for(v in bgMesh.vertices) {
				var colour:Vec4 = gradientColours[if(v.y > 0) 1 else 0];
				bgMesh.colours.push(colour);
			}
			entities.push(new Entity(this, 'Image', [
				new TransformComponent(new Vec3(0, 0, 1), Quat.identity(), new Vec3(1024, 1024, 1024)),
				new MeshComponent(bgMesh),
				new MaterialComponent(bgMaterial),
			]));

			var cec:CircleEffectComponent = new CircleEffectComponent(true);
			entities.push(new Entity(this, 'Circle Effect', [
				new TransformComponent(new Vec3(0, 0, 0.1), Quat.identity(), new Vec3(1024, 1024, 1024)),
				new MeshComponent(quad.path),
				new MaterialComponent(circleOutMat.path),
				cec
			]));
			cec.done.pipe(function(_) {
				entities.push(new Entity(this, '', [new SoundComponent(loadingCrunch.path, true)]));
				var scp1:loading.SlamComponent = new loading.SlamComponent(0.5, 16, 2);
				entities.push(new Entity(this, 'Player 1', [
					new TransformComponent(new Vec3(-256, 192, 0.05), Quat.identity(), new Vec3(2, 2, 2)),
					new MeshComponent(textMesh.clone('p1text')),
					new MaterialComponent(fontMat.path),
					new TextComponent(font, '${GameTracker.player[0].name}\nAKA. ${generateName()}\n(with ${GameTracker.player[0].score} points!)',
						TextAlign.Centre, TextVerticalAlign.Centre,
						new Vec4(1, 1, 1, 1)),
					scp1
				]));
				return scp1.done;
			}).pipe(function(_) {
				entities.push(new Entity(this, '', [new SoundComponent(loadingCrunch.path, true)]));
				var scvs:loading.SlamComponent = new loading.SlamComponent(0.5, 96, 16);
				entities.push(new Entity(this, 'VS', [
					new TransformComponent(new Vec3(0, 0, 0.05), Quat.identity(), new Vec3(16, 16, 16)),
					new MeshComponent(textMesh.clone('vstext')),
					new MaterialComponent(fontMat.path),
					new TextComponent(font, 'VS',
						TextAlign.Centre, TextVerticalAlign.Top,
						new Vec4(1, 1, 1, 1)),
					scvs
				]));
				return scvs.done;
			}).pipe(function(_) {
				entities.push(new Entity(this, '', [new SoundComponent(loadingCrunch.path, true)]));
				var scp2:loading.SlamComponent = new loading.SlamComponent(0.5, 16, 2);
				entities.push(new Entity(this, 'Player 2', [
					new TransformComponent(new Vec3(256, 192, 0.05), Quat.identity(), new Vec3(2, 2, 2)),
					new MeshComponent(textMesh.clone('p2text')),
					new MaterialComponent(fontMat.path),
					new TextComponent(font, '${GameTracker.player[1].name}\nAKA. ${generateName()}\n(with ${GameTracker.player[1].score} points!)',
						TextAlign.Centre, TextVerticalAlign.Centre,
						new Vec4(1, 1, 1, 1)),
					scp2
				]));
				return scp2.done;
			}).pipe(function(_) {
				entities.push(new Entity(this, '', [new SoundComponent(introWobble.path, true)]));
				var scn:loading.SlideComponent = new loading.SlideComponent(1, new Vec3(0, -300, 0.05), new Vec3(0, -192, 0.05));
				entities.push(new Entity(this, 'in:\n${this.gameName}', [
					new TransformComponent(new Vec3(0, -192, 0.05), Quat.identity(), new Vec3(4, 4, 4)),
					new MeshComponent(textMesh.clone('vstext')),
					new MaterialComponent(fontMat.path),
					new TextComponent(font, 'in:\n${this.gameName}',
						TextAlign.Centre, TextVerticalAlign.Centre,
						new Vec4(1, 1, 1, 1)),
					scn
				]));
				return scn.done;
			}).pipe(function(_) {
				// create the trumpet sound effect
				entities.push(new Entity(this, 'Trumpet', [
					new SoundComponent(trumpet.path, true)
				]));

				// wait a second
				var fadeDelay:TimedPromiseComponent = new TimedPromiseComponent(1);
				entities.push(new Entity(this, 'Delay', [fadeDelay]));
				return fadeDelay.done;
			}).pipe(function(_) {
				Log.info('Waiting for loading to complete..');
				return loadingDone;
			}).pipe(function(_) {
				cec.t = 0;
				cec.circleIn = false;
				cec.reset();
				return cec.done;
			}).then(function(_) {
				Log.info('Loading screen done!');
				sceneDone.resolve(this);
			}).catchError(function(err:Dynamic) {
				Log.error(err);
			});

			// tell the processors we've started
			Tusk.router.onEvent(tusk.events.EventType.Start);
		});
	}
}