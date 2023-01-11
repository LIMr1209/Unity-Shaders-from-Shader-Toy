// https://www.shadertoy.com/view/cll3WH
Shader "Unlit/DreamyStarField"
{
    Properties
    {
        _Speed("Speed",Range(0.1,10.0)) = 1.0
        _NoiseTex ("NoiseTex", 2D) = "white" {}
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Transparent" "Queue" = "Transparent"
        }
        LOD 100

        Pass
        {
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            #define TWOPI 6.2831852
            #define LAYERS 8.0
            #define MAXOFFSET 0.8
            #define HALF_SQRT2 0.7071

            float3 pal(in float t, in float3 a, in float3 b, in float3 c, in float3 d)
            {
                return a + b * cos(TWOPI * (c * t + d));
            }

            float2x2 rot(float angle)
            {
                return float2x2(cos(angle), sin(angle), -sin(angle), cos(angle));
            }

            // feature need to have return value 0 for r>=1.0 and max value =1.0
            float feature(float2 r_theta)
            {
                float feature = max(1.0 - r_theta.x, 0.0);
                feature -= 0.25 * pow(cos(r_theta.y * 5.0) + 2.8, r_theta.x * 2.0);
                return pow(max(feature, 0.0), 1.0);
            }

            struct appdata
            {
                fixed4 vertex : POSITION;
                fixed2 uv : TEXCOORD0;
            };

            struct v2f
            {
                fixed2 uv : TEXCOORD0;
                fixed4 vertex : SV_POSITION;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }


            fixed _Speed;
            sampler2D _NoiseTex;
            float4 _NoiseTex_ST;


            fixed4 frag(v2f i) : SV_Target
            {
                float2 uv = i.uv;
                uv = uv * 2.0 - 1.0;
                uv.y /= _ScreenParams.x / _ScreenParams.y;

                // now screen space should have u in range [-1, 1]

                float3 sum = float3(0,0,0);
                float scale = 1.0;

                for (float i = 0.0; i < LAYERS; ++i)
                {
                    float2 _uv = uv * 0.50 / HALF_SQRT2; // scaled to make corner-center dist <= 1.0 (when rotate 45°)
                    _uv = mul(rot(i * 2.0), uv)  + float2(0.03, 0.04) * i; // rotate for every layer
                    scale = fmod(i - _Time.y * 0.3, LAYERS); // compute scale for every layer
                    _uv *= scale; // apply scale to each layer
                    float2 idx = trunc(_uv + float2(LAYERS, LAYERS)); // get ID for each tile
                    _uv = fmod(_uv, 1.0); // make local uv in range [0,1] again by tiling
                    _uv = _uv * 2.0 - 1.0;

                    //now _uv should in range [-1.0, 1.0]


                    // noise is in range [-1.0, 1.0]
                    float3 noise = 2.0 * tex2D(_NoiseTex, (idx + i) * 0.07).rgb - 1.0;
                    //noise = float3(0.0);

                    // limited to MAXOFFSET
                    noise.xy *= MAXOFFSET;

                    // compute the scale limit
                    float2 margin = float2(1,1) - abs(noise.xy);
                    float zoomScale = min(margin.x, margin.y);
                    zoomScale = lerp(0.3, zoomScale * 0.5, (noise.z + 1.0) * 0.5);

                    float2 local_uv = (_uv + noise.xy) / zoomScale;

                    // get polar coordinate
                    float2 r_theta = float2(length(local_uv), atan2(local_uv.x, local_uv.y));
                    r_theta.y += sin(_Time.y * _Speed * noise.z + noise.y * 5.0) * noise.x * 20.0;

                    // get color
                    float3 color = pal((idx.x * idx.y / 10.0 + _Time.y * noise.z * 3.0), float3(0.5, 0.5, 0.5),
                                     float3(0.5, 0.5, 0.5), float3(1.0, 1.0, 1.0), float3(0.0, 0.10, 0.20));
                    sum += feature(r_theta) * color * (LAYERS - scale) / LAYERS * (noise.x + 3.0);
                }

                return float4(pow(sum * 1.5, float3(1.8 / 2.2, 1.8 / 2.2, 1.8 / 2.2)), 1.0);
            }
            ENDCG
        }
    }
}