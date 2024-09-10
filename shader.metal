using namespace metal;

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
  const texture2d<float> texture0 [[ texture(0) ]])
{
  VertexOut vertexOut;
  vertexOut.position = vertexIn.position;
  vertexOut.color = vertexIn.color;
  vertexOut.tex0Coords = vertexIn.tex0Coords;
  vertexOut.tex1Coords = vertexIn.tex1Coords;
  vertexOut.tex2Coords = vertexIn.tex2Coords;
  vertexOut.tex3Coords = vertexIn.tex3Coords;
  return vertexOut;
}

fragment half4 fragment_shader(
  VertexOut vertexOut [[ stage_in ]],
  texture2d<float> texture0 [[ texture(0) ]])
{
  constexpr sampler defaultSampler;
  float4 tex0Color = texture0.sample(defaultSampler, vertexOut.tex0Coords);
  return half4((tex0Color + vertexOut.color) / 2);
}
