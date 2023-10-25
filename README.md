This is a proof of concept for a Gopher client implemented using the [Textadept][1] editor and the [Textredux][2] module.

It is fully functional but may have some bugs and a limited set of features. After all, it's a Gopher client – what more did you expect? 😄

## Installation

In your `$HOME/.textadept/modules` directory, clone the repository:
```
$ git clone http://github.com/manipuladordedados/cratera.git cratera
```

Then in your `$HOME/.textadept/init.lua` file, add the following lines:
```lua
-- Load cratera plugin
local cratera = require("cratera")
```

**Shortcuts:**

- **Ctrl+Alt+g** = Open a Gopherhole address.
- **Ctrl+Alt+e** = Explore a list of pre-included addresses.
- **Ctrl+Alt+b** = Go back.
- **Ctrl+Alt+a** = Show the About message.
- **Ctrl+Alt+k** = Close the buffer.

You can also perform all of these actions through the menu bar.

**Controls:**

- You can move around with your arrow keys and use the Enter key to select items.
- Some Vi keys are supported as well.

[1]: http://foicica.com/textadept/
[2]: https://rgieseke.github.io/textredux/
