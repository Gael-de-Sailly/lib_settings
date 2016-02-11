# Settings Library
A simple per-world settings interface for modders, to easily store variables.
The settings are saved in a file named `world.conf`, in the world directory.

## API
### libsettings.get_object
Constructs and returns a settings object, mod- and world-specific. Must be called at loading time, not in a callback.

```
mymod.world_settings = libsettings.get_object(name)
```
`name` is an optional argument defining the name of the settings object. Default to the mod name if omitted. When saved in the files, the settings are always preceeded by the `name`, as `name_flag = value`. Creating 2 objects with the same name don't cause major issues, but they both refer to the same variables.

### Settings object
It works somewhat like the core Settings object (except the `define` function), but is specific to the mod AND specific to the world.

### Settings:define(flag, default)
Search for a value in the settings object (preferably), and in `minetest.conf`, and return it. If not present, set it to the `default` value, and return it. `minetest.conf` is never modified.

Very often, you can do everything you need, with this only function.

Example:

```
local worldsettings = libsettings.get_object("mymod")
local height = worldsettings:define("height", 50)
```

The first time you load the game, this flag is set to `50`, and `50` is returned. You will find this in `world.conf`:

```
mymod_height = 50
```

The second time, the `50` is directly returned.

If you change it to `mymod_height = 60`, it will return `60` (`default` parameter not used if the flag is already present).

You could also add for example `mymod_height = 40` in `minetest.conf`. It will override the `default` value, but only for new worlds. Very useful for some flags that shouldn't be changed after the world is created.

The type of value is detected from the `default` value. A table is interpreted as noise parameters, so all other tables must be serialized.
