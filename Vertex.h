typedef struct {
  float position[3];
  float color[3];

  // The reason for not using float[n][2] here is that we're using
  // a `MTLVertexDescriptor` to simplify things. Metal, in general
  // doesn't care what/how you write data to your buffers, but
  // vertex descriptor attributes in particular only have "primitive"
  // types like float2.
  //
  // For more details of how/why you should use a vertex descriptor,
  // despite this limitation, see the comments in
  // `Renderer.buildVertexDescriptor`.
  float tex0Coords[2];
  float tex1Coords[2];
  float tex2Coords[2];
  float tex3Coords[2];
  // ...etc
  // For the sake of brevity, this illustration only provides 4
  // texture slots, but you can have arbitrarily many. Metal is
  // agnostic as to how you encode data in your buffers.
} Vertex;
