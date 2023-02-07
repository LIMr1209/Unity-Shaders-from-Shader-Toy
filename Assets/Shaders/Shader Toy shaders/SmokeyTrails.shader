// https://www.shadertoy.com/view/3lVSWt
Shader "Unlit/SmokeyTrails"
{
    Properties
    {
         [Header(General)]
        [ToggleUI] _GammaCorrect ("Gamma Correction", Float) = 1
        _Resolution ("Resolution (Change if AA is bad)", Range(1, 1024)) = 1
        [ToggleUI] _ScreenEffect("ScreenEffect", Float) = 0
        
        [Header(Extracted)]
        _BackGroundColor("BackGroundColor", Color) = (.1,.01,.02,1)
        [HDR]_MainColor("MainColor", Color) = (.8,.4,.2, 1)
        _ShakeSpeed ("ShakeSpeed", Range(0.1,10)) = 1
        _UvSpeed ("UvSpeed", Range(0.1,10)) = 1
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

            fixed4 _BackGroundColor;
            fixed4 _MainColor;
            fixed _ShakeSpeed;
            fixed _UvSpeed;


            #define bpm 150.
            #define beat floor(_Time.y*bpm/60. * _ShakeSpeed)
            #define ttime _Time.y*bpm/60. * _ShakeSpeed

            fixed2x2 r(fixed a)
            {
                fixed c = cos(a), s = sin(a);
                return fixed2x2(c, -s, s, c);
            }

            fixed fig(fixed2 uv)
            {
                uv = mul(uv, r(-3.1415 * .9));
                return min(1., .1 / abs(
                               (atan2(uv.y, uv.x) / 2. * 3.1415) - sin(- ttime + (min(.6, length(uv))) * 3.1415 * 8.)));
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed2 uv = i.uv - 0.5;
                
                uv += fixed2(cos(_Time.y * .1 * _UvSpeed), sin(_Time.y * .1 * _UvSpeed));
                uv = mul(uv, r(_Time.y * .1));

                fixed3 col = fixed3(0.0, 0.0, 0.0);

                for (float y = -1.; y <= 1.; y++)
                {
                    for (float x = -1.; x <= 1.; x++)
                    {
                        fixed2 offset = fixed2(x, y);
                        fixed2 id = floor(mul((uv + offset), r(length(uv + offset))));
                        fixed2 gv = frac(mul((uv + offset), r(length(uv + offset)))) - 0.5;
                        gv = mul(gv, r(cos(length(id) * 10.)));

                        float d = fig(gv);
                        +fig(gv + fixed2(sin(ttime + length(id)) * .1, cos(_Time.y) * .1));
                        col += fixed3(d, d, d) / exp(length(gv) * 6.);
                    }
                }

                col = lerp(_BackGroundColor.rgb, _MainColor.rgb, col);
                if (_GammaCorrect) col.rgb = pow(col.rgb, 2.2);
                return fixed4(col, 1.0);
            }
            ENDCG
        }
    }
}