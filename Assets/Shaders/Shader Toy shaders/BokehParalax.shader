// https://www.shadertoy.com/view/4s2yW1
Shader "Unlit/BokehParalax"
{
    Properties
    {
        [ToggleUI] _GammaCorrect ("Gamma Correction", Float) = 1
        _Resolution ("Resolution (Change if AA is bad)", Range(1, 1024)) = 1
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            // Built-in properties
            float _GammaCorrect;
            float _Resolution;

            // GLSL Compatability macros
            #define glsl_mod(x,y) (((x)-(y)*floor((x)/(y))))
            #define texelFetch(ch, uv, lod) tex2Dlod(ch, float4((uv).xy * ch##_TexelSize.xy + ch##_TexelSize.xy * 0.5, 0, lod))
            #define textureLod(ch, uv, lod) tex2Dlod(ch, float4(uv, 0, lod))
            #define iResolution float3(_Resolution, _Resolution, _Resolution)
            #define iFrame (floor(_Time.y / 60))
            #define iChannelTime float4(_Time.y, _Time.y, _Time.y, _Time.y)
            #define iDate float4(2020, 6, 18, 30)
            #define iSampleRate (44100)
            #define iChannelResolution float4x4(                      \
                _MainTex_TexelSize.z,   _MainTex_TexelSize.w,   0, 0, \
                _SecondTex_TexelSize.z, _SecondTex_TexelSize.w, 0, 0, \
                _ThirdTex_TexelSize.z,  _ThirdTex_TexelSize.w,  0, 0, \
                _FourthTex_TexelSize.z, _FourthTex_TexelSize.w, 0, 0)

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            static const float MATH_PI = float(3.1415927);

            void Rotate(inout float2 p, float a)
            {
                p = cos(a) * p + sin(a) * float2(p.y, -p.x);
            }

            float Circle(float2 p, float r)
            {
                return (length(p / r) - 1.) * r;
            }

            float Rand(float2 c)
            {
                return frac(sin(dot(c.xy, float2(12.9898, 78.233))) * 43758.547);
            }

            float saturate(float x)
            {
                return clamp(x, 0., 1.);
            }

            void BokehLayer(inout float3 color, float2 p, float3 c)
            {
                float wrap = 450.;
                if (glsl_mod(floor(p.y/wrap+0.5), 2.) == 0.)
                {
                    p.x += wrap * 0.5;
                }

                float2 p2 = glsl_mod(p+0.5*wrap, wrap) - 0.5 * wrap;
                float2 cell = floor(p / wrap + 0.5);
                float cellR = Rand(cell);
                c *= frac(cellR * 3.33 + 3.33);
                float radius = lerp(30., 70., frac(cellR * 7.77 + 7.77));
                p2.x *= lerp(0.9, 1.1, frac(cellR * 11.13 + 11.13));
                p2.y *= lerp(0.9, 1.1, frac(cellR * 17.17 + 17.17));
                float sdf = Circle(p2, radius);
                float circle = 1. - smoothstep(0., 1., sdf * 0.04);
                float glow = exp(-sdf * 0.025) * 0.3 * (1. - circle);
                color += c * (circle + glow);
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 fragCoord = i.uv * _Resolution;
                float2 uv = fragCoord.xy / iResolution.xy;
                float2 p = (2. * fragCoord - iResolution.xy) / iResolution.x * 1000.;
                float3 color = lerp(float3(0.3, 0.1, 0.3), float3(0.1, 0.4, 0.5), dot(uv, float2(0.2, 0.7)));
                float time = _Time.y - 15.;
                Rotate(p, 0.2 + time * 0.03);
                BokehLayer(color, p + float2(-50. * time + 0., 0.), 3. * float3(0.4, 0.1, 0.2));
                Rotate(p, 0.3 - time * 0.05);
                BokehLayer(color, p + float2(-70. * time + 33., -33.), 3.5 * float3(0.6, 0.4, 0.2));
                Rotate(p, 0.5 + time * 0.07);
                BokehLayer(color, p + float2(-60. * time + 55., 55.), 3. * float3(0.4, 0.3, 0.2));
                Rotate(p, 0.9 - time * 0.03);
                BokehLayer(color, p + float2(-25. * time + 77., 77.), 3. * float3(0.4, 0.2, 0.1));
                Rotate(p, 0. + time * 0.05);
                BokehLayer(color, p + float2(-15. * time + 99., 99.), 3. * float3(0.2, 0., 0.4));
                float4 fragColor = float4(color, 1.);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}