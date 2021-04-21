# adf-box

Raytracer on Adaptively Sampled Distance Fields.

Port of a [prototype in C#](https://github.com/InterplanetaryEngineer/SdfBox) to zig with Vulkan, [V-EZ](https://github.com/GPUOpen-LibrariesAndSDKs/V-EZ) and [zalgebra](https://github.com/kooparse/zalgebra). Works on Windows and Linux.

### Installation

Install the [Vulkan SDK](https://vulkan.lunarg.com) and [glfw](https://www.glfw.org)\*, clone this repo and run

```
cd adf-box
git submodule update --init --recursive
```
Then build V-EZ
```
cd V-EZ
cmake .
```
On Windows, build the resulting INSTALL.vcxproj in Release mode, on Linux `make`

And finally build adf-box
```
cd ..
zig build
```

\* On Windows, these should be in `C:\Program Files (x86)\GLFW\lib-vc2019\glfw3.lib` and `C:\VulkanSDK\[version]\Lib\vulkan-1.lib`.
On Linux, pkgconfig should be able to find them.

### Usage

```
./zig-cache/bin/adf-box <model> [<depth>]
```

(I have not yet figured out how to convince the zig build system to set a proper rpath, so on Linux you can only execute the binary from the project root folder like this.)

`<model>` should be a `.adf` (custom format, see below) or `.ply` file. When loading a `ply`, you can specify the `<depth>` of the generated ADF (making for a cell resolution of 1 / (3 x 2ᵈᵉᵖᵗʰ); default is 5). The ADF generation takes a time of roughly O(source polycount * depth) - a few seconds for reasonable models - but will emit a `.adf` file, which can be loaded directly.

The `ply` model must have a `vertex` element with six float properties, taken as position and normal. It is recommended to ensure (using e.g. [MeshLab](https://www.meshlab.net)) that the mesh is a closed 2-manifold. For best results, compute vertex normals weighed by angle. As an example, a touched-up [Stanford Bunny](https://graphics.stanford.edu/data/3Dscanrep/) is contained in the project as `bunny.ply`.

You can rotate the camera by clicking and moving the mouse, move with WASD/Shift/Ctrl, and move the light source in X/Y/Z with U/J, I/K and O/L.

### Literature
Sarah F. Frisken et al.: Adaptively sampled distance fields: A general representation of shape for computer graphics

Jakob A. Bærentzen and Henrik Aanæs: Signed distance computation using the angle weighted pseudonormal

Thiago Bastos and Waldemar Celes: Gpu-Accelerated Adaptively Sampled Distance Fields

### License

Copyright (c) 2021 Jonathan Hähne

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
