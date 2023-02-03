// https://www.shadertoy.com/view/tllfRX
Shader "Unlit/StarFieldPractice"
{
    Properties
    {
        [Header(General)]
        [ToggleUI] _GammaCorrect ("Gamma Correction", Float) = 1
        _Resolution ("Resolution (Change if AA is bad)", Range(1, 1024)) = 1
        _Mouse ("Mouse", Vector) = (0.5, 0.5, 0.5, 0.5)


        [Header(Extracted)]
        NUM_LAYERS ("NUM_LAYERS", Float) = 6
    }
    SubShader
    {
        Pass
        {
            Cull Off

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
            float4 _Mouse;

            // GLSL Compatability macros
            #define glsl_mod(x,y) (((x)-(y)*floor((x)/(y))))
            #define iResolution float3(_Resolution, _Resolution, _Resolution)

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }


            float NUM_LAYERS;
            #define TAU 6.28318
            #define PI 3.141592

            float2x2 Rot(float a)
            {
                float s = sin(a), c = cos(a);
                return transpose(float2x2(c, -s, s, c));
            }

            float Star(float2 uv, float flare)
            {
                float d = length(uv);
                float m = 0.025 / d;
                float rays = max(0., 1. - abs(uv.x * uv.y * 1000.));
                m += rays * flare * 2.;
                uv = mul(uv, Rot(PI / 4.));
                rays = max(0., 1. - abs(uv.x * uv.y * 1000.));
                m *= smoothstep(1., 0.2, d);
                return m;
            }

            float Hash21(float2 p)
            {
                p = frac(p * float2(123.34, 456.21));
                p += dot(p, p + 45.32);
                return frac(p.x * p.y);
            }

            float3 StarLayer(float2 uv)
            {
                float3 col = ((float3)0);
                float2 gv = frac(uv) - 0.5;
                float2 id = floor(uv);
                for (int y = -1; y <= 1; y++)
                {
                    for (int x = -1; x <= 1; x++)
                    {
                        float2 offs = float2(x, y);
                        float n = Hash21(id + offs);
                        float size = frac(n * 45.32);
                        float star = Star(gv - offs - float2(n, frac(n * 34.)) + 0.5,
                                          smoothstep(0.8, 0.9, size) * 0.46);
                        float3 color = sin(float3(0.2, 0.3, 0.9) * frac(n * 2345.2) * TAU) * 0.25 + 0.75;
                        color = color * float3(0.9, 0.59, 0.9 + size);
                        star *= sin(_Time.y * 3. + n * TAU) * 0.25 + 0.5;
                        col += star * size * color;
                    }
                }
                return col;
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 fragCoord = i.uv * _Resolution;
                float2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
                float2 M = (_Mouse.xy - iResolution.xy * 0.5) / iResolution.y;
                float t = _Time.y * 0.0162;
                uv = mul(uv, Rot(t));
                float3 col = ((float3)0);
                for (float i = 0.; i < 1.; i += 1. / NUM_LAYERS)
                {
                    float depth = frac(i + t);
                    float scale = lerp(20., 0.5, depth);
                    float fade = depth * smoothstep(1., 0.9, depth);
                    col += StarLayer(uv * scale + i * 453.2 - _Time.y * 0.05 - M) * fade;
                }
                float4 fragColor = float4(col, 1.);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}