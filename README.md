# tetris_in_assembly

Fully featured Tetris made entirely in x86 Assembly, using the Canvas Library.

## Prerequisites

- A CPU with x86_64 architecture that is able to operate in 32-bit mode.

## Installation

A pre-built binary can be found in the [releases page](https://github.com/stancualex/tetris_in_assembly/releases/tag/v0.1.0).

### Building from source

1. Clone this repository:

```cmd
git clone https://github.com/stancualex/tetris_in_assembly
```

2. Open up a new command prompt, `cd` into the source directory and run the following command:
    - 32-bit MASM must be installed and on path.

```cmd
ml.exe tetris.asm /link /subsystem:console /entry:start msvcrt.lib && del *.obj *.lnk
```

## Usage

Run `tetris.exe` to play the game.

Keybindings:

- `a`, `s`, `d` - Move left, down and right respectively
- `w` - Drop the piece
- `q`, `e` - Rotate left and right respectively
- Upon game over, press `r` to restart

The game saves your high score automatically once you beat it, and remembers it even when you close the session.
