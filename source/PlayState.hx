package;

import FlxUIDropDownMenuCustom;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.ui.FlxBar;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import haxe.Http;
import lime.app.Application;
import openfl.net.URLLoader;
import openfl.net.URLRequest;

using StringTools;
#if sys
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
#end

class PlayState extends FlxState
{
	var bg:FlxSprite;

	var play:FlxButton;
	var version:FlxUIDropDownMenuCustom;

	public var online_url:String = "";

	var progBar_bg:FlxSprite;
	var progressBar:FlxBar;

	var http:Http;
	var versionList:String = '';
	var zip:URLLoader;

	var versionNumber:String = '';

	override public function create()
	{
		http = new Http("https://raw.githubusercontent.com/VideoBotYT/Universe-Engine/refs/heads/main/versionList.txt");

		bg = new FlxSprite(0, 0).loadGraphic("assets/images/bg.png");
		bg.screenCenter();
		add(bg);

		progBar_bg = new FlxSprite(FlxG.width / 2, FlxG.height / 2 + 50).makeGraphic(500, 20, FlxColor.BLACK);
		progBar_bg.x -= 250;
		progressBar = new FlxBar(progBar_bg.x + 5, progBar_bg.y + 5, LEFT_TO_RIGHT, Std.int(progBar_bg.width - 10), Std.int(progBar_bg.height - 10), this,
			"entire_progress", 0, 100);
		progressBar.numDivisions = 3000;
		progressBar.createFilledBar(0xFF8F8F8F, 0xFFAD4E00);

		play = new FlxButton(FlxG.width / 2 - 200, 0, "PLAY", function()
		{
			#if sys
			prepareInstall();
			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				startGame();
			});
			#end
		});
		play.screenCenter(Y);
		add(play);

		version = new FlxUIDropDownMenuCustom(0, 0, FlxUIDropDownMenuCustom.makeStrIdLabelArray(["Loading..."], true));
		version.screenCenter();
		add(version);

		http.onData = function(data:String)
		{
			var versions = data.split("\n").filter(function(line) return line.trim() != "");
			remove(version);
			version = new FlxUIDropDownMenuCustom(0, 0, FlxUIDropDownMenuCustom.makeStrIdLabelArray(versions, true));
			version.screenCenter();
			add(version);
		}

		http.onError = function(error)
		{
			trace('Error fetching version list: $error');
		}

		http.request();

		zip = new URLLoader();

		super.create();
	}

	override public function update(elapsed:Float)
	{
		versionNumber = "/" + version.selectedLabel + "/";
		super.update(elapsed);
	}

	#if sys
	function startGame()
	{
		var exePath = Sys.programPath();
		var exeDir = haxe.io.Path.directory(exePath);
		var versionPath = haxe.io.Path.directory("/versions/");
		var versionsPath = haxe.io.Path.directory(exeDir + versionPath + versionNumber);

		var batch = "@echo on\n";
		batch += "set \"versions=" + "versions" + "\"\r\n"; 
		batch += "set \"versionNumber=" + versionNumber + "\"\r\n";
		batch += "cd \"!versions!\"\"!versionNumber!\" UniverseEngine.exe\r\n";
		batch += "start UniverseEngine.exe\r\n";
		//batch += "endlocal";

		File.saveContent(haxe.io.Path.join([versionsPath, "start.bat"]), batch);

		new Process(versionsPath + "/start.bat", []);
	}

	function prepareInstall()
	{
		var fileEnd = 'zip';
		online_url = "https://github.com/VideoBotYT/Universe-Engine/releases/download/" + version.selectedLabel + '/FNF-Universe-Engine-windows.$fileEnd';
		trace("download url: " + online_url);

		if (!FileSystem.exists("./versions/" + version.selectedLabel + "/"))
		{
			trace("version folder not found, creating the directory...");
			FileSystem.createDirectory("./versions/" + version.selectedLabel + "/");
		}
		else
		{
			trace("version folder found");
		}
	}

	var fatalError:Bool = false;
	var httpHandler:Http;

	public function installGame()
	{
		trace("starting download process...");

		final url:String = requestUrl(online_url);
		if (url != null && url.indexOf('Not Found') != -1)
		{
			trace('File not found error!');
			fatalError = true;
		}

		zip.load(new URLRequest(online_url));
		if (fatalError)
		{
			// trace('File size is small! Assuming it couldn\'t find the url!');
			lime.app.Application.current.window.alert('Couldn\'t find the URL for the file! Cancelling download!');
			return;
		}
	}

	public function requestUrl(url:String):String
	{
		httpHandler = new Http(url);
		var r = null;
		httpHandler.onData = function(d)
		{
			r = d;
		}
		httpHandler.onError = function(e)
		{
			trace("error while downloading file, error: " + e);
			fatalError = true;
		}
		httpHandler.request(false);
		return r;
	}
	#end
}