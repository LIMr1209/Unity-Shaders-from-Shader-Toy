// https://www.shadertoy.com/view/DljXDG


Shader "Unlit/ColorMercury"
{
    Properties
    {
        [Header(General)]
        [ToggleUI] _GammaCorrect ("Gamma Correction", Float) = 1
        _Resolution ("Resolution (Change if AA is bad)", Range(1, 1024)) = 1
        [ToggleUI] _ScreenEffect("ScreenEffect", Float) = 0

        [Header(Extracted)]
        _Speed("Speed", range(0.1,10)) = 1
    }
    SubShader
    {

        Tags
        {
            "RenderType"="Opaque"
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

            float2x2 rotate2D(float r)
            {
                return transpose(float2x2(cos(r), -sin(r), sin(r), cos(r)));
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 fragCoord;
                float2 r;
                if (_ScreenEffect)
                {
                    fragCoord = i.uv * _ScreenParams;
                    r = _ScreenParams.xy;
                }
                else
                {
                    fragCoord = i.uv * iResolution;
                    r = iResolution.xy;
                }

                float2 FC = fragCoord;
                float t = _Time.y * _Speed;
                float a = 15.;
                float R = 0.;
                float S = 3.;
                float2 n = ((float2)0);
                float2 q = n;
                float2 N = q;
                float2x2 m = ((float2x2)0);
                float2 uv = (FC - 0.5 * r) / r.x;
                for (float j = 0.; j < 8.; j++)
                {
                    m = rotate2D(5.5 * j);
                    n = mul(n, m);
                    q = mul(uv, m);
                    R = length(q + 0.1);
                    q = float2((log(R) * S * 0.5 - t) * 2., atan2(q.y, 1.));
                    q += n * 0.5 + q.y;
                    a += dot(sin(q), n);
                    q = sin(q * 1.3);
                    n += q * 1.56;
                    N += q / S;
                    N *= 0.6;
                    S /= 0.99;
                }
                float3 col = ((float3)0);
                col += (0.4 - a * 0.04 + 0.2 / length(N)) * sqrt(R) * (3.6 + sin(float3(2, 4, 5) + a * 0.1)) * 0.34;
                col.rg += uv * 0.8;
                float4 fragColor = float4(col, 1.);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}