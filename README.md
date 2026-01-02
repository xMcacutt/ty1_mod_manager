# Ty the Tasmanian Tiger Mod Manager

## Setup

To get started using the Ty Mod Manager, simply head to the [releases page](http://github.com/xMcacutt/ty_mod_manager/releases) and download the most recent mod manager zip.

Extract the zip anywhere and run the executable. On your first time loading the mod manager, you'll be asked if you would like to automatically set up a directory for your modded Ty. If yes, you should select your vanilla Ty directory (usually steamapps/common/Ty the Tasmanian Tiger). If no, you should go to the settings tab to set the directory manually.

## Codes

The codes tab allows you to have global pieces of code modifying the game across mods. To add codes to the list, make a pull request on github to the [codes.json](http://github.com/xMcacutt/ty_mod_manager/blob/master/resource/codes.json) file.

## Installing Mods

To install a mod, first check the `mod directory` page in the mod manager. If you cannot find the mod in the directory, you might need to install it manually. Find and download the mod's zip file and select it from the `add custom` button on the `my mods` page.

## Launch Arguments

As of v2.0.1, the mod manager now supports command line arguments allowing you to launch installed mods and codes without opening the UI.
Before explaining the arguments, it must be noted that using command line arguments bypasses the update checking for the mod manager.

Any errors that are generated when using the command line args will be in the ty_mod_manager.log file in %Temp%.

To use direct mode, provide --direct along with the short game name.

```ty_mod_manager.exe --direct ty2```

This will bypass the mod manager and launch the game. 

If the --mods argument is not provided, this will launch the last mods that you selected in the UI.

If --mods is provided, you must then provide a list of comma separated mod names to load (use "s to escape spaces). The names must match those seen in the UI mods list.

```ty_mod_manager.exe --direct ty1 --mods "Archipelago Client","Discord Rich Presence"```

If you also want to inject the codes that you last had selected then provide `--codes`  

```ty_mod_manager.exe --direct ty3 --mods "Ty3 AP Client" --codes```

When the mod manager is added to steam, these arguments can be provided as launch options to make steam listings for each individual mod.

## Adding Mods

### FOR MOD DEVELOPERS ONLY

If you wish to add a mod you've created to this project, you'll need to reformat your release structure.

A mod is defined as a combination of a patch file and/or dll file. The patch file is used to modify the files belonging to the game and the dll file is used to modify the behaviour of the game. 

### Mod Info

Mods require a `mod_info.json` file which defines the information displayed in the mod directory on each listing.

Below is a list of the fields which should be defined in the json.

| Property       | Description                                                                                                                                                                                                                                     | Required? |
| -------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- |
| `name`         | visual display name for the mod                                                                                                                                                                                                                 | Yes       |
| `description`  | description of the mod's function                                                                                                                                                                                                               | Yes       |
| `dll_name`     | name of the dll if it exists without the extension                                                                                                                                                                                              | No        |
| `version`      | version of the mod (must be updated with the mod)                                                                                                                                                                                               | Yes       |
| `dependencies` | A list of dependency objects. The dependency object definition can be found below.                                                                                                                                                              | No        |
| `conflicts`    | A list of strings. Each string is the name of another mod which is known to conflict. The conflict does not prevent launching. Instead it warns the user on launch. This may change in the future with the introduction of RKV bundling.        | Yes       |
| `author`       | Your name or psuedonym                                                                                                                                                                                                                          | Yes       |
| `download_url` | The url to download the zip file containing the mod files listed below. This must link directly to the download.                                                                                                                                | Yes       |
| `icon_url`     | A link to a `.ico` file. It is recommended that the ico file uploaded as part of the mod's git repo. The raw github link should be used to avoid unnecessary api calls. If no icon is provided, the mod will show up with a question mark icon. | No        |
| `last_updated` | The date of last update. This should be kept in YYYY-MM-DD format. Please stick to this format and update with the mod                                                                                                                          | Yes       |
| `website`      | A web url which can be accessed from the right click context menu in `my mods`. Readme link usually goes here                                                                                                                                   | No        |
| `games`        | A list of games 'Ty 1', 'Ty 2', or 'Ty 3' which defaults to Ty 1 when left ommitted                                                                                                                                                             | No        |

#### Dependencies

Dependencies come in two forms. Internal dependencies are dependencies required for functions specific to the mod. These dependecies can be added to a Dependencies directory in the mod zip.

External dependencies should be used when the dependency may apply to multiple mods. These dlls can be added to your mod_info as long as they can be downloaded from a link you provide. The following properties must be defined on all dependency objects

Note that internal dependencies do not need specifying in mod_info.json

| Property   | Description                                                                                                                                                                                                                  |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `dep_name` | The name of the dll dependency without the extension                                                                                                                                                                         |
| `dep_ver`  | The version of the dependency required. This must use semantic versioning. Note that if two mods use the same dependency with different version references, the most recent version will be used. This may create conflicts. |
| `dep_url`  | A direct download link to the dependency                                                                                                                                                                                     |

### Example mod_info.json

```json
{
  "name": "Collectible Tracker",
  "dll_name": "Ty Collectible Tracker Plugin",
  "description": "Tool to view current and total collectible counts overlaid onto the game.",
  "version": "1.1.1",
  "website": "",
  "dependencies": [
    {
      "dep_name": "TygerMemory",
      "dep_version": "1.0.3",
      "dep_url": "https://github.com/xMcacutt/TygerMemory1/releases/download/1.0.3/TygerMemory.dll"
    }
  ],
  "conflicts": [
    "Archipelago Client",
    "Tyger Utility"
  ],
  "author": "xMcacutt",
  "download_url": "https://github.com/xMcacutt/Ty-Collectible-Tracker-Plugin/releases/latest/Ty.Collectible.Tracker.Plugin.zip",
  "last_updated": "2025-03-02"
}
```

### The Mod Directory

Once the `mod_info.json` file has been created, you'll need to upload it preferably as a a part of your mod's repository and add it to [mod_directory.json](http://github.com/xMcacutt/ty_mod_manager/blob/master/mod_directory.json). You should create a pull request and add a name for your mod as well as the raw link to the mod_info file you uploaded. When the mod_directory is accessed in the mod manager, the mod_directory.json file will be accessed to look up each mod's mod_info before creating the listings based on the information you provide. Please ensure your json is valid before creating a pull request.

### Releasing Your Mods

When creating a release on github or any file host, you'll need to provide the mod as a zip file. The zip file should contain the `mod_info.json` file you should already have created; either a `Patch_PC.rkv` file or a `dll` file for you mod or both; and a `favico.ico` file which is used when displaying the mod in the installed mods list. If no `favico.ico` file is added, the `icon_url` from `mod_info.json` will be used instead;

These files will be extracted to the AppData/Roaming/io.mcacutt/mods directory upon installation.


