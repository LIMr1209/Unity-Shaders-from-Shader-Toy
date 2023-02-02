// https://www.shadertoy.com/view/XdSBD1
Shader "Unlit/Starfall"
{
    Properties
    {
        [Header(General)]
        [ToggleUI] _GammaCorrect ("Gamma Correction", Float) = 1
        _Resolution ("Resolution (Change if AA is bad)", Range(1, 1024)) = 1

    }
    SubShader
    {
        Pass
        {
            Cull Off

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

            
            #define F for(float i = .1; i <.9; i+=.04)


            float4 frag (v2f i) : SV_Target
            {
                float4 f = 0;
                float2 u = i.uv * _Resolution;
                u /= iResolution.y;
                f -= f;
                for (float i = 0.1;i<0.9; i += 0.04)
                {
                    float3 p = float3(u+(_Time.y/i-i)/float2(30, 10), i);
                    p = abs(1.-glsl_mod(p, 2.));
                    float a = length(p), b, c = 0.;
                    for (float i = 0.1;i<0.9; i += 0.04)
                    p = abs(p)/a/a-0.57, (b = length(p), (c += abs(a-b), a = b));
                    c *= c;
                    f += c*float4(i, 1, 2, 0)/30000.;
                }
                if (_GammaCorrect) f.rgb = pow(f.rgb, 2.2);
                return f;
            }
            
            ENDCG
        }
    }
}
