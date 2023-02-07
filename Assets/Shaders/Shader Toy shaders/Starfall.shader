// https://www.shadertoy.com/view/XdSBD1
Shader "Unlit/Starfall"
{
    Properties
    {
        [Header(General)]
        [ToggleUI] _GammaCorrect ("Gamma Correction", Float) = 1
        _Resolution ("Resolution (Change if AA is bad)", Range(1, 1024)) = 1
        [ToggleUI] _ScreenEffect("ScreenEffect", Float) = 0


        [Header(Extracted)]
        [HDR]_MainColor("MainColor", Color) = (1, 1, 2, 0)
        _Iterations ("Iterations", Range(1,18)) = 18
        _Speed("Speed", range(0.1, 10)) = 1
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


            float4 _MainColor;
            float _Speed;
            float _Iterations;


            float4 frag(v2f i) : SV_Target
            {
                float4 f = 0;
                float2 u;
                if (_ScreenEffect)
                {
                    u = i.uv * _ScreenParams;
                    u /= _ScreenParams.y;
                }
                else
                {
                    u = i.uv * iResolution;
                    u /= iResolution.y;
                }
                float maxIterations = 0.1 + _Iterations * 0.04;
                for (float i = 0.1; i < maxIterations; i += 0.04)
                {
                    float3 p = float3(u + (_Time.y * _Speed / i - i) / float2(30, 10), i);
                    p = abs(1. - glsl_mod(p, 2.));
                    float a = length(p), b, c = 0.;
                    for (float i = 0.1; i < 0.9; i += 0.04)
                        p = abs(p) / a / a - 0.57, (b = length(p), (c += abs(a - b), a = b));
                    c *= c;
                    // f += c/30000. * float4(i, 1, 2, 0);
                    f += c / 30000. * _MainColor;
                }
                if (_GammaCorrect) f.rgb = pow(f.rgb, 2.2);
                return f;
            }
            ENDCG
        }
    }
}