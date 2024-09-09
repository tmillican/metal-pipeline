using namespace metal;

struct VertexIn {
  float3 position [[ attribute(0) ]];
  float3 color [[ attribute(1) ]];
};

struct FragmentIn {
  float4 position [[ position ]];
  float3 color;
};

vertex FragmentIn vertex_shader(const VertexIn vertexIn [[ stage_in ]])
{
  FragmentIn fragmentIn;
  fragmentIn.position = float4(vertexIn.position, 1.0);
  fragmentIn.color = vertexIn.color;
  return fragmentIn;
}

fragment half4 fragment_shader(FragmentIn fragmentIn [[ stage_in ]])
{
  return half4(fragmentIn.color.r, fragmentIn.color.g, fragmentIn.color.b, 1.0);
}
