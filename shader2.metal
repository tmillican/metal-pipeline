using namespace metal;

struct Uniforms {
  int shouldInvertColor;
};

struct VertexIn {
  float4 position [[ attribute(0) ]];
  float4 color [[ attribute(1) ]];
  float2 tex0Coords [[ attribute(2) ]];
  float2 tex1Coords [[ attribute(3) ]];
  float2 tex2Coords [[ attribute(4) ]];
  float2 tex3Coords [[ attribute(5) ]];
};

struct VertexOut {
  float4 position [[ position ]];
  float4 color;
};

vertex VertexOut vertex_shader(
  const VertexIn vertexIn [[ stage_in ]],
  constant Uniforms &uniforms [[ buffer(1) ]])
{
  VertexOut vertexOut;
  vertexOut.position = vertexIn.position * 0.75;
  vertexOut.position[3] = 1;
  vertexOut.color = vertexIn.color;
  return vertexOut;
}

fragment half4 fragment_shader(
  VertexOut vertexOut [[ stage_in ]],
  constant Uniforms &uniforms [[ buffer(0) ]],
  texture2d<float> texture0 [[ texture(0) ]],
  texture2d<float> texture1 [[ texture(1) ]],
  texture2d<float> texture2 [[ texture(2) ]],
  texture2d<float> texture3 [[ texture(3) ]]
)
{
  if (uniforms.shouldInvertColor == 0) {
    return half4(vertexOut.color);
  } else {
    return half4(1, 1, 1, 2) - half4(vertexOut.color);
  }
}
