using namespace metal;

struct Uniforms {
  float scale;
  float uDisplacement;
  int textureSelector;
};

// See comments in `Renderer.buildVertexDescriptor`. This struct does not
// need to have the same layout as the obj-c Vertex that I wrote into
// [[ buffer(0) ]]. The types here can also be different, subject to certain
// conversion limitations.
struct VertexIn {
  float4 position [[ attribute(0) ]];
  float4 color [[ attribute(1) ]];
  float2 tex0Coords [[ attribute(2) ]];
  float2 tex1Coords [[ attribute(3) ]];
  float2 tex2Coords [[ attribute(4) ]];
  float2 tex3Coords [[ attribute(5) ]];
};

struct VertexOut {
  // When returning a struct from the vertex_shader, you need to identify
  // which field is the position by tagging it with the [[ position ]]
  // attribute.
  float4 position [[ position ]];
  float4 color;
  float2 tex0Coords;
  float2 tex1Coords;
  float2 tex2Coords;
  float2 tex3Coords;
};

vertex VertexOut vertex_shader(
  const VertexIn vertexIn [[ stage_in ]],
  constant Uniforms &uniforms [[ buffer(1) ]])
{
  VertexOut vertexOut;
  float4 scaledPosition = vertexIn.position * uniforms.scale;
  scaledPosition[3] = 1.0;
  vertexOut.position = scaledPosition;
  vertexOut.color = vertexIn.color;
  vertexOut.tex0Coords = vertexIn.tex0Coords;
  vertexOut.tex1Coords = vertexIn.tex1Coords;
  vertexOut.tex2Coords = vertexIn.tex2Coords;
  vertexOut.tex3Coords = vertexIn.tex3Coords;
  return vertexOut;
}

// NOTE: unlike the vertex function, the [[ stage_in ]] argument doesn't
// consume buffer(0).
fragment half4 fragment_shader(
  VertexOut vertexOut [[ stage_in ]],
  constant Uniforms &uniforms [[ buffer(0) ]],
  texture2d<float> texture0 [[ texture(0) ]],
  texture2d<float> texture1 [[ texture(1) ]],
  texture2d<float> texture2 [[ texture(2) ]],
  texture2d<float> texture3 [[ texture(3) ]]
)
{
  float2 baseCoords; 
  if (uniforms.textureSelector == 0) {
    baseCoords = vertexOut.tex0Coords;
  } else {
    baseCoords = vertexOut.tex1Coords;
  }
  float2 displacedCoords = baseCoords;
  displacedCoords[0] += uniforms.uDisplacement;
  // I don't know if/how texture clamping works in Metal, but whatever.
  // I'll just do the wrap-around sampling myself.
  if (displacedCoords[0] > 1.0) displacedCoords[0] -= 1.0;

  constexpr sampler defaultSampler;
  float4 texColor;
  if (uniforms.textureSelector == 0) {
    texColor = texture0.sample(defaultSampler, displacedCoords);
  } else {
    texColor = texture1.sample(defaultSampler, displacedCoords);
  }
  texColor = texColor * 0.8;
  float4 vertexColor = vertexOut.color * 0.2;
  float4 mixedColor = texColor + vertexColor;
  return half4(mixedColor);
}
