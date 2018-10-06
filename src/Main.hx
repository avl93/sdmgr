package;

import haxe.Json;
import haxe.Template;
import haxe.io.Bytes;
import sys.FileSystem;
import sys.io.File;

/**
 * ...
 * @author AVL
 */
class Main
{
	static var startCommand : Template = new Template('start-stop-daemon -CSbvmp ::id::.pid -d ::dir:: -x ::file:: -- ::params:: > logs/::id::_$(date +%Y_%m_%d_%H_%M_%S).txt 2>&1');
	static var killCommand : Template = new Template("start-stop-daemon -Kp ::id::.pid");
	static var checkCommand : Template = new Template("kill -0 $(cat ::id::.pid)");

	static var config :Array< {file:String, params:String, id:String, dir: String}>;
	static var state : Array<Bool>;

	static var debug : Bool = false;

	static function main()
	{
		if (!FileSystem.exists("logs")){
			FileSystem.createDirectory("logs");
		}
		readConfig();

		if (Sys.args().length > 1)
		{
			var cmd : UserCommand = {command:Sys.args()[0], param:Sys.args()[1]};
			executeCommand(cmd);
			return;
		}
		while (true)
		{
			var userCommand = printAll();
			if (executeCommand(userCommand))
			{
				break;
			}
		}

	}

	static function executeCommand(userCommand:Dynamic) : Bool
	{
		switch (userCommand.command)
		{
			case "u":
				readConfig();
			case "r":
				run(userCommand.param);
			case "k":
				stop(userCommand.param);
			case "c":
				check();
			case "x":
				return true;
		}
		return false;
	}

	static function run(param:String)
	{
		if (param == "a")
		{
			for (i in 0...config.length)
			{
				execute(startCommand.execute(config[i]));
			}
		}
		else
		{
			var index : Int = Std.parseInt(param);
			if (index == null)
			{
				for (i in 0...config.length)
				{
					if (config[i].id == param)
					{
						index = i;
					}
				}
			}
			execute(startCommand.execute(config[index]));
		}
	}
	static function stop(param:String)
	{
		if (param == "a")
		{
			for (i in 0...config.length)
			{
				execute(killCommand.execute(config[i]));
			}
		}
		else
		{
			execute(killCommand.execute(config[Std.parseInt(param)]));
		}
	}

	static function execute(command:String) : Int
	{

		if (Sys.systemName() == "Windows")
		{
			Sys.stdout().write(Bytes.ofString(command + "\n"));
			return 0;
		}
		else
		{
			if (debug)
			{
				Sys.stdout().write(Bytes.ofString(command + "\n"));
			}
			return Sys.command(command);
		}
	}

	static function check()
	{
		for (i in 0...config.length)
		{
			state[i] = execute(checkCommand.execute(config[i])) == 0;
		}
	}

	static function readConfig()
	{
		var configTxt : String = File.getContent("dmns.json");
		config = Json.parse(configTxt);
		state = new Array<Bool>();
		for (i in 0...config.length)
		{
			state.push(false);
		}
		trace(state.length, config.length);

	}

	static function printAll(): UserCommand
	{
		Sys.stdout().write(Bytes.ofString("\n"));
		check();
		for (i in 0...config.length)
		{
			Sys.stdout().write(Bytes.ofString( (state[i] ? "+" : " ") +i + " " + config[i].id +"\n"));
		}
		var userCommand : String = Sys.stdin().readLine();
		var commandSplit :Array<String> = userCommand.split(" ");
		debug = false;
		if (commandSplit.length == 3)
		{
			switch (commandSplit[2])
			{
				case "v":
					debug = true;
			}
		}
		return {command:commandSplit[0], param:commandSplit[1]};
	}

}

typedef UserCommand = {command:String, param:String}