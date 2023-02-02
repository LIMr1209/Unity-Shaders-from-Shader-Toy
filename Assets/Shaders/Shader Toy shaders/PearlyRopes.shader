// https://www.shadertoy.com/view/DtlXWB
Shader "Unlit/PearlyRopes"
{
    Properties
    {
        [ToggleUI] _GammaCorrect ("Gamma Correction", Float) = 1
        _Resolution ("Resolution (Change if AA is bad)", Range(1, 1024)) = 1
        _Mouse ("Mouse", Vector) = (0.5, 0.5, 0.5, 0.5)
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
            float4 _Mouse;

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


            #define H(a) sin(float3(0, 1.047, 2.094)+((float3)a*6.2832))*0.5+0.5
            #define RT(a) ((float2x2)cos(m.a*1.5708+float4(0, -1.5708, 1.5708, 0)))

            float gt(float x, float t, bool b)
            {
                if (b)
                    t *= sign(abs(x) - 1.), x = max(abs(x), 1. / abs(x)) * sign(x);

                return (1. - abs(sin((x - t) * 3.1416))) * min(1., 1. / abs(x));
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 XY = i.uv * _Resolution;
                float3 c, u, v;
                float2 R = iResolution.xy, m = _Mouse.xy / R * 4. - 2., o;
                float p = 2., t = (_Time.y - 10.) / 5., T = 6.2832, a, r;
                bool b = true;
                if (_Mouse.z < 1.)
                    m = float2(sin(t / 2.) * 0.2, sin(t) * 0.1);

                for (int k = 0; k < int(p * p); k++)
                {
                    o = float2(k % 2, k / 2) / p;
                    u = normalize(float3((XY - 0.5 * R + o) / R.y, 1)) * 8.;
                    u.yz = mul(u.yz,RT(y)), u.xz = mul(u.xz,RT(x));
                    a = atan2(u.y, u.x) / 2.;
                    r = length(u.xy);
                    u.xy = tan(log(r) + float2(a, -a * 3.));
                    v = max(H(u.x*T-t), H(T/u.x+t)) * gt(u.x, t, b);
                    v = max(v, 0.5 * max(H(u.y*T-t), H(T/u.y+t)) * gt(u.y, t, b));
                    v = min(v, H(r*T-t*4.) * gt(r, t * 4., b) + 0.25) + pow(v, ((float3)5.));
                    c += v;
                }
                c /= p * p;
                float4 fragColor = float4(c + c * c * 4., 1.);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}