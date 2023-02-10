Shader "Unlit/ColorFul"
{
    Properties
    {
        [Header(General)]
        [ToggleUI] _GammaCorrect ("Gamma Correction", Float) = 1
        _Resolution ("Resolution (Change if AA is bad)", Range(1, 1024)) = 1
        [ToggleUI] _ScreenEffect("ScreenEffect", Float) = 0

        [Header(Extracted)]
        _RotateSpeed("RotateSpeed", range(0.1,10)) = 1
        _ShakeSpeed("ShakeSpeed", range(0.1,10)) = 0.8
        _Tessellation("Tessellation", range(0.1,10)) = 2
        _Size("Size", range(0.1,10)) = 0.6
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


            float _RotateSpeed;
            float _ShakeSpeed;
            float _Tessellation;
            float _Size;

            #define PI 3.14159265358979

            // Convert HSL colorspace to RGB. http://en.wikipedia.org/wiki/HSL_and_HSV
            fixed3 HSLtoRGB(in fixed h, in fixed s, in fixed l)
            {
                fixed3 rgb = clamp(abs(fmod(h + fixed3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
                return l + s * (rgb - 0.5) * (1.0 - abs(2.0 * l - 1.0));
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed2 r = i.uv.xy / 1;
                fixed2 p = -1.0 + 2.0 * r;
                if(_ScreenEffect)
                {
                    p.x *= _ScreenParams.x / _ScreenParams.y;
                }else
                {
                    p.x *= iResolution.x / iResolution.y;
                }
                fixed fSin = sin(_Time.y * _RotateSpeed * 0.4);
                fixed fCos = cos(_Time.y * _RotateSpeed * 0.4);
                p = mul(p, fixed2x2(fCos, -fSin, fSin, fCos));
                fixed h = atan2(p.y, p.x) + PI;
                fixed x = distance(p,fixed2(0.0, 0.0));
                fixed a = -(_Size + 0.2 * sin(_Time.y * 3.1 + sin((_Time.y * _ShakeSpeed  + h * _Tessellation) * 10.0)) *
                    sin(_Time.y + h));
                fixed b = -(0.8 + 0.3 * sin(_Time.y * 1.7 + sin((_Time.y + h * 4.0))));
                fixed c = 1.25 + sin((_Time.y + sin((_Time.y + h) * 3.0)) * 1.3) * 0.15;
                fixed l = a * x * x + b * x + c;
                float4 fragColor = fixed4(HSLtoRGB(h * 3.0 / PI, 1.0, l), 1.0);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}