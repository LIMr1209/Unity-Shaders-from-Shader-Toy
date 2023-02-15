// https://www.shadertoy.com/view/MdjyRm
Shader "Unlit/RaymarchingBasic"
{
    Properties
    {
        [Header(General)]
        [ToggleUI] _GammaCorrect ("Gamma Correction", Float) = 1
        _Resolution ("Resolution (Change if AA is bad)", Range(1, 1024)) = 1
        [ToggleUI] _ScreenEffect("ScreenEffect", Float) = 0
        
        [Header(Extracted)]
        _Speed("Speed", Range(0.1, 10)) = 1
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
            float _ScreenEffect;

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


            float _Speed;
            float map(float3 p)
            {
                float3 n = float3(0, 1, 0);
                float k1 = 1.9;
                float k2 = (sin(p.x * k1) + sin(p.z * k1)) * 0.8;
                float k3 = (sin(p.y * k1) + sin(p.z * k1)) * 0.8;
                float w1 = 4. - dot(abs(p), normalize(n)) + k2;
                float w2 = 4. - dot(abs(p), normalize(n.yzx)) + k3;
                float s1 = length(glsl_mod(p.xy+float2(sin((p.z+p.x)*2.)*0.3, cos((p.z+p.x)*1.)*0.5), 2.) - 1.) - 0.2;
                float s2 = length(glsl_mod(0.5+p.yz+float2(sin((p.z+p.x)*2.)*0.3, cos((p.z+p.x)*1.)*0.3), 2.) - 1.) -
                    0.2;
                return min(w1, min(w2, min(s1, s2)));
            }

            float2 rot(float2 p, float a)
            {
                return float2(p.x * cos(a) - p.y * sin(a), p.x * sin(a) + p.y * cos(a));
            }

            float4 frag(v2f i) : SV_Target
            {
                float time = _Time.y * _Speed;
                float2 uv;
                if (_ScreenEffect)
                {
                    float2 fragCoord = i.uv * _ScreenParams;
                    uv = fragCoord.xy / _ScreenParams.xy * 2. - 1.;
                    uv.x *= _ScreenParams.x / _ScreenParams.y;
                }
                else
                {
                    float2 fragCoord = i.uv * iResolution;
                    uv = fragCoord.xy / iResolution.xy * 2. - 1.;
                    uv.x *= iResolution.x / iResolution.y;
                }
                float3 dir = normalize(float3(uv, 1.));
                dir.xz = rot(dir.xz, time * 0.23);
                dir = dir.yzx;
                dir.xz = rot(dir.xz, time * 0.2);
                dir = dir.yzx;
                float3 pos = float3(0, 0, time);
                float3 col = ((float3)0.);
                float t = 0.;
                float tt = 0.;
                for (int i = 0; i < 100; i++)
                {
                    tt = map(pos + dir * t);
                    if (tt < 0.001)
                        break;

                    t += tt * 0.45;
                }
                float3 ip = pos + dir * t;
                col = ((float3)t * 0.1);
                col = sqrt(col);
                float4 fragColor = float4(0.05 * t + abs(dir) * col + max(0., map(ip - 0.1) - tt), 1.);
                fragColor.a = 1. / (t * t * t * t);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}