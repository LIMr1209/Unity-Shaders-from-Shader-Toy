// https://www.shadertoy.com/view/MdXSzS
Shader "Unlit/GalaxyOfUniverses"
{
    Properties
    {
        [Header(General)]
        [ToggleUI] _GammaCorrect ("Gamma Correction", Float) = 1
        _Resolution ("Resolution (Change if AA is bad)", Range(1, 1024)) = 1
        [ToggleUI] _ScreenEffect("ScreenEffect", Float) = 0

        [Header(Extracted)]
        _RotateSpeed("RotateSpeed",Range(0.1,10.0)) = 1.0
        _TwistSpeed("TwistSpeed",Range(0.1,10.0)) = 1.0
        _SpreadColorChangeSpeed("SpreadColorChangeSpeed", Range(0.1, 20)) = 1.0
        _DirectColorChangeSpeed("DirectColorChangeSpeed", Range(0.1, 20)) = 1.0

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
                fixed4 vertex : POSITION;
                fixed2 uv : TEXCOORD0;
            };

            struct v2f
            {
                fixed2 uv : TEXCOORD0;
                fixed4 vertex : SV_POSITION;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            // Built-in properties
            float _GammaCorrect;
            float _Resolution;
            float _ScreenEffect;

            // GLSL Compatability macros
            #define glsl_mod(x,y) (((x)-(y)*floor((x)/(y))))
            #define iResolution float3(_Resolution, _Resolution, _Resolution)


            fixed4 _MainColor;
            fixed _RotateSpeed;
            fixed _TwistSpeed;
            fixed _SpreadColorChangeSpeed;
            fixed _DirectColorChangeSpeed;


            fixed4 frag(v2f i) : SV_Target
            {
                float2 uv;
                if (_ScreenEffect)
                {
                    float2 fragCoord = i.uv * _ScreenParams;
                    uv = fragCoord.xy / _ScreenParams.xy - 0.5;
                    // uv.y *= _ScreenParams.y / _ScreenParams.x;
                    uv.x *= _ScreenParams.x / _ScreenParams.y;
                }
                else
                {
                    float2 fragCoord = i.uv * iResolution;
                    uv = fragCoord.xy / iResolution.xy - 0.5;
                    // uv.y *= iResolution.y / iResolution.x;
                    uv.x *= iResolution.x / iResolution.y;
                }

                float t = _Time.y * .1 + (.25 + .05 * sin(_Time.y * _RotateSpeed * .1)) / (length(uv.xy) + .07) * 2.2;
                float si = sin(t);
                float co = cos(t);
                float2x2 ma = float2x2(co, si, -si, co);

                float v1, v2, v3;
                v1 = v2 = v3 = 0.0;

                float s = 0.0;
                for (int i = 0; i < 90; i++)
                {
                    float3 p = s * float3(uv, 0.0);
                    // p.xy *= ma;
                    p.xy = mul(ma, p.xy);
                    p += float3(.22, .3, s - 1.5 - sin(_Time.y * _TwistSpeed * .13) * .1);
                    for (int i = 0; i < 8; i++) p = abs(p) / dot(p, p) - 0.659;
                    v1 += dot(p, p) * .0015 * (1.8 + sin(
                        length(uv.xy * 13.0) + .5 - _Time.y * _SpreadColorChangeSpeed * .2));
                    v2 += dot(p, p) * .0013 * (1.5 + sin(
                        length(uv.xy * 14.5) + 1.2 - _Time.y * _SpreadColorChangeSpeed * .3));
                    v3 += length(p.xy * 10.) * .0003;
                    s += .035;
                }

                float len = length(uv);
                v1 *= smoothstep(.7, .0, len);
                v2 *= smoothstep(.5, .0, len);
                v3 *= smoothstep(.9, .0, len);

                float3 col = float3(v3 * (1.5 + sin(_Time.y * _DirectColorChangeSpeed * .2) * .4),
                                    (v1 + v3) * .3,
                                    v2) + smoothstep(0.2, .0, len) * .85 + smoothstep(.0, .6, v3) * .3;

                float4 fragColor = float4(min(pow(abs(col), float3(1.2, 1.2, 1.2)), 1.0), 1.0);
                // if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}