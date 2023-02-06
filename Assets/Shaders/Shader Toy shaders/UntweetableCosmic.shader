// https://www.shadertoy.com/view/mtlGzr
Shader "Unlit/UntweetableCosmic"
{
    Properties
    {
        [Header(General)]
        [ToggleUI] _GammaCorrect ("Gamma Correction", Float) = 1
        _Resolution ("Resolution (Change if AA is bad)", Range(1, 1024)) = 1
        [ToggleUI] _ScreenEffect("ScreenEffect", Float) = 0
        
        [Header(Extracted)]
        _Speed("Speed",Range(0.1,10.0)) = 1.0
        _OverSample("OverSample", float) = 4.0
        _RingDistance("RingDistance", float) = 0.075
        _NoOfRings("NoOfRings", float) = 20
        _GlowFactor("GlowFactor", float) = 0.05
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
        }
        LOD 100

        Pass
        {

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"


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

            #define PI          3.141592654
            #define PI_2        (0.5*PI)
            #define TAU         (2.0*PI)

            float _OverSample;
            float _RingDistance;
            float _NoOfRings;
            float _GlowFactor;
            float _Speed;

            // License: MIT, author: Pascal Gilcher, found: https://www.shadertoy.com/view/flSXRV
            float atan_approx(float y, float x)
            {
                float cosatan2 = x / (abs(x) + abs(y));
                float t = PI_2 - cosatan2 * PI_2;
                return y < 0.0 ? -t : t;
            }

            // License: CC0, author: Mårten Rånge, found: https://github.com/mrange/glsl-snippets
            float2 toPolar(float2 p)
            {
                return float2(length(p), atan_approx(p.y, p.x));
            }

            // License: MIT OR CC-BY-NC-4.0, author: mercury, found: https://mercury.sexy/hg_sdf/
            float mod1(inout float p, float size)
            {
                float halfsize = size * 0.5;
                float c = floor((p + halfsize) / size);
                // p = mod(p + halfsize, size) - halfsize;
                p = glsl_mod(p + halfsize, size) - halfsize;
                // p = p + halfsize - size * floor((p + halfsize) / size) - halfsize;
                return c;
            }

            // License: Unknown, author: Unknown, found: don't remember
            float hash(float co)
            {
                return frac(sin(co * 12.9898) * 13758.5453);
            }

            float3 glow(float2 pp, float h)
            {
                float hh = frac(h * 8677.0);
                float b = TAU * h + 0.5 * _Time.y * _Speed * (hh > 0.5 ? 1.0 : -1.0);
                float a = pp.y + b;
                float d = max(abs(pp.x) - 0.001, 0.00125);
                return
                    smoothstep(0.667 * _RingDistance, 0.2 * _RingDistance, d)
                    * smoothstep(0.1, 1.0, cos(a))
                    * _GlowFactor
                    * _RingDistance
                    / d
                    * (cos(a + b + float3(0, 1, 2)) + float3(1.0, 1.0, 1.0));
            }

            float3 effect(float2 p)
            {
                p += -0.1;
                // Didn't really understand how the original Cosmic produced the fake projection.
                // Took part of the code and tinkered
                // p = (p * float2x2(1, -1, 2, 2));
                p = mul(float2x2(1, -1, 2, 2), p);
                p += float2(0.0, 0.33) * length(p);
                float2 pp = toPolar(p);

                float3 col = float3(0, 0, 0);
                float h = 1.0;
                const float nr = 1.0 / _OverSample;

                for (float i = 0.0; i < _OverSample; ++i)
                {
                    float2 ipp = pp;
                    ipp.x -= _RingDistance * (nr * i);
                    float rn = mod1(ipp.x, _RingDistance);
                    h = hash(rn + 123.0 * i);
                    col += glow(ipp, h) * step(rn, _NoOfRings);
                }

                col += 0.01 * float3(1.0, 0.25, 0.0) / length(p);

                return col;
            }


            fixed4 frag(v2f i) : SV_Target
            {
                float2 q = i.uv;
                float2 p = -1. + 2. * q;  // uv -1 1
                if(_ScreenEffect)
                {
                    p.x *= _ScreenParams.x / _ScreenParams.y;
                }
                else
                {
                    p.x *= iResolution.x / iResolution.y;
                }
                
                float3 col;
                col = effect(p);
                col = sqrt(col);
                float4 fragColor = float4(col, 1.0);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}