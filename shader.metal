using namespace metal;

vertex float4 vertex_shader()
{
  return float4(0.0, 0.0, 0.0, 1.0);
}


fragment half4 fragment_shader()
{
  return half4(1.0, 0.0, 0.0, 1.0);
}
