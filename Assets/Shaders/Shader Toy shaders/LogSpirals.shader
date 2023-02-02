// https://www.shadertoy.com/view/mlsSzs
Shader "Unlit/LogSpirals"
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

            float4 frag(v2f i) : SV_Target
            {
                float2 XY = i.uv * _Resolution;
                float3 c, u, v;
                float2 R = iResolution.xy, m = _Mouse.xy / R * 4. - 2., o;
                float p = 2., t = (_Time.y - 10.) / 5., a;
                if (_Mouse.z < 1.)
                    m = float2(sin(t / 2.) * 0.2, sin(t) * 0.1);

                for (int k = 0; k < int(p * p); k++)
                {
                    o = float2(k % 2, k / 2) / p;
                    u = normalize(float3((XY - 0.5 * R + o) / R.y, 1));
                    u.yz = mul(u.yz,RT(y)), u.xz = mul(u.xz,RT(x));
                    a = atan2(u.y, u.x) / 2.;
                    u.xy = tan(log(length(u.xy)) + float2(a * 2., -a * 5.));
                    v = min(1. - abs(sin((u - t) * 3.1416)), 1. / abs(u));
                    c += H(u.x-t) * min(v.x, v.y) / min(max(v.x, v.y), 1. - v.x) * 0.5;
                }
                c /= p * p;
                float4 fragColor = float4(c + c * c, 1.);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}