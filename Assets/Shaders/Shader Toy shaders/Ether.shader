// https://www.shadertoy.com/view/MsjSW3
Shader "Unlit/Ether"
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
            #define iChannelResolution float4x4(                      \
                _MainTex_TexelSize.z,   _MainTex_TexelSize.w,   0, 0, \
                _SecondTex_TexelSize.z, _SecondTex_TexelSize.w, 0, 0, \
                _ThirdTex_TexelSize.z,  _ThirdTex_TexelSize.w,  0, 0, \
                _FourthTex_TexelSize.z, _FourthTex_TexelSize.w, 0, 0)

            // Global access to uv data
            static v2f vertex_output;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv =  v.uv;
                return o;
            }

            #define t _Time.y
            float2x2 m(float a)
            {
                float c = cos(a), s = sin(a);
                return transpose(float2x2(c, -s, s, c));
            }

            float map(float3 p)
            {
                p.xz = mul(p.xz,m(t*0.4));
                p.xy = mul(p.xy,m(t*0.3));
                float3 q = p*2.+t;
                return length(p+((float3)sin(t*0.7)))*log(length(p)+1.)+sin(q.x+sin(q.z+sin(q.y)))*0.5-1.;
            }

            float4 frag (v2f i) : SV_Target
            {
                float2 fragCoord = i.uv * _Resolution;
                float2 p = fragCoord.xy/iResolution.y-float2(0.9, 0.5);
                float3 cl = ((float3)0.);
                float d = 2.5;
                for (int i = 0;i<=5; i++)
                {
                    float3 q = float3(0, 0, 5.)+normalize(float3(p, -1.))*d;
                    float rz = map(q);
                    float f = clamp((rz-map(q+0.1))*0.5, -0.1, 1.);
                    float3 l = float3(0.1, 0.3, 0.4)+float3(5., 2.5, 3.)*f;
                    cl = cl*l+smoothstep(2.5, 0., rz)*0.7*l;
                    d += min(rz, 1.);
                }
                float4 fragColor = float4(cl, 1.);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}