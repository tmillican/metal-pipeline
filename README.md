# Dynamic Metal Pipeline in Objecive-C

This is a demonstration of how to set up a Metal renderer with a dynamic
(per-frame) source for the various rendering inputs. This includes:

- Shaders
- Integer and floating point shader uniforms ("constants" in Metal parlance)
- Textures
- Vertex data

# Build/Run Instructions

Run `make`.

The output binary will be `./build/MyApp`

You can also run `sh go.sh` to build and run.

# General Overview

Vertex and fragment functions in Metal have an argument table for different
resource types. Namely:

- buffers (arbitrary data)
- textures
- samplers

What GLSL calls "uniforms", Metal calls "constants" -- somewhat confusingly
since you can also declare constant values in your shader, which are constant
for the shader's lifetime. Metal constants are only constant per render pass
and can be altered by the CPU between passes if desired.

Constants/uniforms are passed to the shader as a buffer of arbitrary data,
bound to a `[[ buffer(n) ]]` slot of the vertex/fragment function argument
table. They are only distinct from any other buffer by the `constant` specifier
in the shader argument list, which informs Metal that the buffer contents won't
change during a render pass, presumably enabling some optimizations.

Textures are passed in a similar manner, differing only in that they bind
to the `[[ texture(n) ]]` slots of the argument table, and in their default
access, CPU caching, storage mode, etc. In principle, you could manually
populate a buffer with texture data and pass a texture as a buffer.

Metal is agnostic to the format or content of data in a buffer. You could
pass your uniforms using one buffer per variable/field, or as a single buffer
to which you write an entire struct. So long as the size, type and buffer
bindings in the function's argument list match the binary layout of the data
written into the buffers on the Objecive-C side (be they constants/uniforms or
not), everything will work.

# Caveats

## Vertex data structure

The format of vertex data is expected to be static, but it would fairly
trivial to extend the sort of descriptor logic used by the `UniformsHandler`
to make this dynamic as well.

## Buffer sizes

The size of the vertex data, vertex index, and uniforms buffer are fixed at
compile time. In a real-world setting, they may need to be dynamically sized
and periodically reallocated.

# Useful Resources

- [MSL Specification](https://developer.apple.com/metal/Metal-Shading-Language-Specification.pdf)
- [Vertex Data and Vertex Descriptors](https://metalbyexample.com/vertex-descriptors/)
