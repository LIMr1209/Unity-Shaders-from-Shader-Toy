// https://www.shadertoy.com/view/wlGXRD
Shader "Unlit/PsychedelicSakura"
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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv =  v.uv;
                return o;
            }

            float plot(float r, float pct)
            {
                return smoothstep(pct-0.2, pct, r)-smoothstep(pct, pct+0.2, r);
            }

            float3 pal(in float t, in float3 a, in float3 b, in float3 c, in float3 d)
            {
                return a+b*cos(6.28318*(c*t+d));
            }

            float4 frag (v2f i) : SV_Target
            {
                float2 fragCoord = i.uv * _Resolution;
                float2 uv = fragCoord/iResolution.xy;
                float3 col = ((float3)1.);
                float2 pos = ((float2)0.5)-uv;
                pos.x *= iResolution.x/iResolution.y;
                pos *= cos(_Time.y)*1.+1.5;
                float r = length(pos)*2.;
                float a = atan2(pos.y, pos.x);
                float f = abs(cos(a*2.5+_Time.y*0.5))*sin(_Time.y*2.)*0.698+cos(_Time.y)-4.;
                float d = f-r;
                col = (((float3)smoothstep(frac(d), frac(d)+-0.2, 0.16))-((float3)smoothstep(frac(d), frac(d)+-1.184, 0.16)))*pal(f, float3(0.725, 0.475, 0.44), float3(0.605, 0.587, 0.007), float3(1., 1., 1.), float3(0.31, 0.41, 0.154));
                float pct = plot(r*0.272, frac(d*(sin(_Time.y)*0.45+0.5)));
                col += pct*pal(r, float3(0.75, 0.36, 0.352), float3(0.45, 0.372, 0.271), float3(0.54, 0.442, 0.264), float3(0.038, 0.35, 0.107));
                float4 fragColor = float4(col, pct*0.3);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}
