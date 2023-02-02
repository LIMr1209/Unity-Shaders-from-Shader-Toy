// https://www.shadertoy.com/view/tttfR2
Shader "Unlit/JelloLights"
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

            #define PI 3.141592
            #define ORBS 20.

            float4 frag(v2f i) : SV_Target
            {
                float2 fragCoord = i.uv * _Resolution;
                float2 uv = (2. * fragCoord - iResolution.xy) / iResolution.y;
                uv *= 279.27;
                float4 fragColor = ((float4)0.);
                for (float i = 0.; i < ORBS; i++)
                {
                    uv.y -= i / 1000. * uv.x;
                    uv.x += i / 0.05 * sin(uv.x / 9.32 + _Time.y) * 0.21 * cos(uv.y / 16.92 + _Time.y / 3.) * 0.21;
                    float t = 5.1 * i * PI / float(ORBS) * (2. + 1.) + _Time.y / 10.;
                    float x = -1. * tan(t);
                    float y = sin(t / 3.5795);
                    float2 p = 115. * float2(x, y) / sin(PI * sin(uv.x / 14.28 + _Time.y / 10.));
                    float3 col = cos(float3(0, 1, -1) * PI * 2. / 3. + PI * (5. + i / 5.)) * 0.5 + 0.5;
                    fragColor += float4(i / 40. * 55.94 / length(uv - p * 0.9) * col, 3.57);
                }
                fragColor.xyz = pow(fragColor.xyz, ((float3)3.57));
                fragColor.w = 1.;
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}