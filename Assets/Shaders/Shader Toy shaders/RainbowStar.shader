﻿// https://www.shadertoy.com/view/DtsXRj
Shader "Unlit/RainbowStar"
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


            float4 frag(v2f __vertex_output) : SV_Target
            {
                float4 O = 0;
                float2 u = __vertex_output.uv * _Resolution;
                float2 r = iResolution.xy;
                u += u - r;
                float i = 0.;
                for (O *= i; i++ < 100.; O += pow(
                         0.005 / length(u / r.y + i * (sin(_Time.y) * 0.5 + 0.5) * 0.007 - 0.5) * (sin(
                             0.1 * i + float4(1, 2, 3, 0)) + 1.), O - O + 1.3))
                    u = mul(
                        u, ((float2x2)sin(float4(0, 33, 11, 0) + (i < 2. ? _Time.y : sin(_Time.y / 1.) * 0.1 + 0.2))));
                if (_GammaCorrect) O.rgb = pow(O.rgb, 2.2);
                return O;
            }
            ENDCG
        }
    }
}