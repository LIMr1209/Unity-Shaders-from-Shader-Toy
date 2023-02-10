// https://www.shadertoy.com/view/tdyBRt
Shader "Unlit/Viscosity"
{
    Properties
    {
        [Header(General)]
        [ToggleUI] _GammaCorrect ("Gamma Correction", Float) = 1
        _Resolution ("Resolution (Change if AA is bad)", Range(1, 1024)) = 1
        [ToggleUI] _ScreenEffect("ScreenEffect", Float) = 0

        [Header(Extracted)]
        _Speed("Speed", range(0.1,10)) = 1
        _Scale("Scale", range(0.1,10)) = 1
        _Blur("Blur", range(0.1,10)) = 1
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
            float _Scale;
            float _Blur;
            #define PI 3.1415927

            float2 rot(float2 p, float a)
            {
                float c = cos(a * 15.83);
                float s = sin(a * 15.83);
                return mul(p, transpose(float2x2(s, c, c, -s)));
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 uv;
                if (_ScreenEffect)
                {
                    uv = i.uv * _ScreenParams;
                    uv /= _ScreenParams.xx;
                }
                else
                {
                    uv = i.uv * iResolution;
                    uv /= iResolution.xx;
                }
                uv = float2(0.125, 0.75) + (uv - float2(0.125, 0.75)) * 0.03;
                float T = _Time.y * 0.25 * _Speed;
                float3 c = clamp(1. - 0.7 * float3(length(uv - float2(0.1, 0)), length(uv - float2(0.9, 0)),
                                                   length(uv - float2(0.5, 1))), 0., 1.) * 2. - 1.;
                float3 c0 = ((float3)0);
                float w0 = 0.;
                const float N = 16.;
                for (float i = 0.; i < N; i++)
                {
                    float wt = (i * i / N / N - 0.2) * 0.3;
                    float wp = 0.5 * _Scale + (i + 1.) * (i + 1.5) * 0.001;
                    float wb = 0.05 * _Blur + i / N * 0.1;
                    c.zx = rot(c.zx, 1.6 + T * 0.65 * wt + (uv.x + 0.7) * 23. * wp);
                    c.xy = rot(c.xy, c.z * c.x * wb + 1.7 + T * wt + (uv.y + 1.1) * 15. * wp);
                    c.yz = rot(
                        c.yz, c.x * c.y * wb + 2.4 - T * 0.79 * wt + (uv.x + uv.y * (frac(i / 2.) - 0.25) * 4.) * 17. *
                        wp);
                    c.zx = rot(c.zx, c.y * c.z * wb + 1.6 - T * 0.65 * wt + (uv.x + 0.7) * 23. * wp);
                    c.xy = rot(c.xy, c.z * c.x * wb + 1.7 - T * wt + (uv.y + 1.1) * 15. * wp);
                    float w = 1.5 - i / N;
                    c0 += c * w;
                    w0 += w;
                }
                c0 = c0 / w0 * 2. + 0.5;
                c0 *= 0.5 + dot(c0, float3(1, 1, 1)) / sqrt(3.) * 0.5;
                c0 += pow(length(sin(c0 * PI * 4.)) / sqrt(3.) * 1., 20.) * (0.3 + 0.7 * c0);
                float4 fragColor = float4(c0, 1.);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}