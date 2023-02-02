// https://www.shadertoy.com/view/ttKGDt
Shader "Unlit/PhantomStarForCine"
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

            
            float2x2 rot(float a)
            {
                float c = cos(a), s = sin(a);
                return transpose(float2x2(c, s, -s, c));
            }

            static const float pi = acos(-1.);
            static const float pi2 = pi*2.;
            float2 pmod(float2 p, float r)
            {
                float a = atan2(p.x, p.y)+pi/r;
                float n = pi2/r;
                a = floor(a/n)*n;
                return mul(p,rot(-a));
            }

            float box(float3 p, float3 b)
            {
                float3 d = abs(p)-b;
                return min(max(d.x, max(d.y, d.z)), 0.)+length(max(d, 0.));
            }

            float ifsBox(float3 p)
            {
                for (int i = 0;i<5; i++)
                {
                    p = abs(p)-1.;
                    p.xy = mul(p.xy,rot(_Time.y*0.3));
                    p.xz = mul(p.xz,rot(_Time.y*0.1));
                }
                p.xz = mul(p.xz,rot(_Time.y));
                return box(p, float3(0.4, 0.8, 0.3));
            }

            float map(float3 p, float3 cPos)
            {
                float3 p1 = p;
                p1.x = glsl_mod(p1.x-5., 10.)-5.;
                p1.y = glsl_mod(p1.y-5., 10.)-5.;
                p1.z = glsl_mod(p1.z, 16.)-8.;
                p1.xy = pmod(p1.xy, 5.);
                return ifsBox(p1);
            }

            float4 frag (v2f i) : SV_Target
            {
                float2 fragCoord = i.uv * _Resolution;
                float2 p = (fragCoord.xy*2.-iResolution.xy)/min(iResolution.x, iResolution.y);
                float3 cPos = float3(0., 0., -3.*_Time.y);
                float3 cDir = normalize(float3(0., 0., -1.));
                float3 cUp = float3(sin(_Time.y), 1., 0.);
                float3 cSide = cross(cDir, cUp);
                float3 ray = normalize(cSide*p.x+cUp*p.y+cDir);
                float acc = 0.;
                float acc2 = 0.;
                float t = 0.;
                for (int i = 0;i<99; i++)
                {
                    float3 pos = cPos+ray*t;
                    float dist = map(pos, cPos);
                    dist = max(abs(dist), 0.02);
                    float a = exp(-dist*3.);
                    if (glsl_mod(length(pos)+24.*_Time.y, 30.)<3.)
                    {
                        a *= 2.;
                        acc2 += a;
                    }
                    
                    acc += a;
                    t += dist*0.5;
                }
                float3 col = float3(acc*0.01, acc*0.011+acc2*0.002, acc*0.012+acc2*0.005);
                float4 fragColor = float4(col, 1.-t*0.03);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}
