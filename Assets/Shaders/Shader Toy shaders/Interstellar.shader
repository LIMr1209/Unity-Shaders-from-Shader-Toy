// https://www.shadertoy.com/view/Xdl3D2
Shader "Unlit/Interstellar"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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

            sampler2D _MainTex;

            static const float tau = 6.2831855;
#define GAMMA (2.2)
            float3 ToLinear(in float3 col)
            {
                return pow(col, ((float3)GAMMA));
            }

            float3 ToGamma(in float3 col)
            {
                return pow(col, ((float3)1./GAMMA));
            }

            float4 Noise(in int2 x)
            {
                return tex2D(_MainTex, (((float2)x)+0.5)/256.);
            }

            float4 Rand(in int x)
            {
                float2 uv;
                uv.x = (float(x)+0.5)/256.;
                uv.y = (floor(uv.x)+0.5)/256.;
                return tex2D(_MainTex, uv);
            }

            float4 frag (v2f i) : SV_Target
            {
                float2 fragCoord = i.uv * _Resolution;
                float3 ray;
                ray.xy = 2.*(fragCoord.xy-iResolution.xy*0.5)/iResolution.x;
                ray.z = 1.;
                float offset = _Time.y*0.5;
                float speed2 = (cos(offset)+1.)*2.;
                float speed = speed2+0.1;
                offset += sin(offset)*0.96;
                offset *= 2.;
                float3 col = ((float3)0);
                float3 stp = ray/max(abs(ray.x), abs(ray.y));
                float3 pos = 2.*stp+0.5;
                for (int i = 0;i<20; i++)
                {
                    float z = Noise(((int2)pos.xy)).x;
                    z = frac(z-offset);
                    float d = 50.*z-pos.z;
                    float w = pow(max(0., 1.-8.*length(frac(pos.xy)-0.5)), 2.);
                    float3 c = max(((float3)0), float3(1.-abs(d+speed2*0.5)/speed, 1.-abs(d)/speed, 1.-abs(d-speed2*0.5)/speed));
                    col += 1.5*(1.-z)*c*w;
                    pos += stp;
                }
                float4 fragColor = float4(ToGamma(col), 1.);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}