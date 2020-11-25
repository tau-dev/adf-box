# adf-box

Raytracer on Adaptively Sampled Distance Fields.

Port of a [prototype in C#](https://github.com/InterplanetaryEngineer/SdfBox) to zig with Vulkan, [V-EZ](https://github.com/GPUOpen-LibrariesAndSDKs/V-EZ) and [zalgebra](https://github.com/kooparse/zalgebra). Should be fully cross-platform compatible.

### Installation

Install the [Vulkan SDK](https://vulkan.lunarg.com/) and [glfw](https://www.glfw.org/), clone this repo and run

```
cd adf-box
git submodule update --init --recursive
```
Then build V-EZ
```
cd V-EZ
cmake .
make
```
And finally build adf-box
```
cd ..
zig build
```

The executable and its resources (i.e. shaders) can then be found at `zig-cache/bin`.

### References
Sarah F. Frisken et al.: Adaptively sampled distance fields: A general representation of shape for computer graphics

Jakob A. Bærentzen and Henrik Aanæs: Signed distance computation using the angle weighted pseudonormal

Thiago Bastos and Waldemar Celes: Gpu-Accelerated Adaptively Sampled Distance Fields