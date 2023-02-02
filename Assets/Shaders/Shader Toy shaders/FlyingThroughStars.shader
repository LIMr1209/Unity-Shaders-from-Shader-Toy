// https://www.shadertoy.com/view/DllXD8
Shader "Unlit/FlyingThroughStars"
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

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }


            #define R iResolution.xy
            #define T (_Time.y*0.25)
            #define M_PI (3.1416)
            #define TAU (M_PI*2.)
            #define ZERO (min(0, int(_Time.y)))

            float star(float2 uv, float3 p, float radius)
            {
                p.xy /= p.z;
                float dist = distance(uv, p.xy);
                return clamp(radius / max(0.0001, dist), 0., 1.);
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 fc = i.uv * _Resolution;
                float3 col = ((float3)0.);
                float2 uv = (fc - 0.5 * R.xy) / R.y;

                float FAR = 60.;
                int count = 100;
                for (int i = ZERO; i < count; i++)
                {
                    float v = float(i + 1) / float(count);
                    float rnd = frac(float(i) / 33.215 + (0.5 + v * TAU) * M_PI);
                    float rnd2 = frac(rnd * 10.20194);
                    float rnd3 = frac((rnd + rnd2) * 9.392815);
                    float x = cos(rnd * TAU + v) * (rnd + 1.) * M_PI;
                    float y = sin(rnd2 * TAU - v) * (rnd2 + rnd + 1.) * M_PI;
                    float z = frac(-(T * ((rnd + rnd2) / 2.)) * M_PI * (0.5 + v)) * (0.001 + v) * FAR;
                    float s = star(uv, float3(x, y, z), lerp(0.001, 0.009, rnd2));
                    s *= smoothstep(v, 0.25, abs(z / FAR));
                    float3 starColor = float3(rnd, rnd2, rnd3);
                    col += s * starColor;
                }
                float4 fragColor = float4(col, 1.);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}