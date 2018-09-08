# 3ddemo

## No longer maintained
First commit builds with DMD 2.076.0 but not later versions.
Last commit builds with DMD 2.082.0 and might actually work, but no promises. I get an access violation error on loadSymbols() on Windows, and can't currently test on Linux. If you test and it works, let me know.

Written in [D](https://dlang.org).

### Dependencies
+ [GFM](https://github.com/d-gamedev-team/gfm) and [SDL](http://libsdl.org/) for window/input handling.
+ [assimp](https://github.com/assimp/assimp) for asset loading.

### Building
You need a D compiler to compile the program.

You can get one at [dlang.org](http://dlang.org/download.html)

You'll also need [DUB](https://github.com/D-Programming-Language/dub) for building.

Once all the required programs are installed,

run `dub build` in the root directory.

### Usage
1. Run the program
2. Hold the mouse and move around to orbit around the model
3. Scroll up/down to zoom in/out
