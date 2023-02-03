// https://www.shadertoy.com/view/7lt3D4
Shader "Unlit/PrismaticSynapse"
{
    Properties
    {
        [Header(General)]
        [ToggleUI] _GammaCorrect ("Gamma Correction", Float) = 1
        _Resolution ("Resolution (Change if AA is bad)", Range(1, 1024)) = 1
        _Mouse ("Mouse", Vector) = (0.5, 0.5, 0.5, 0.5)

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
            float4 _Mouse;

            // GLSL Compatability macros
            #define glsl_mod(x,y) (((x)-(y)*floor((x)/(y))))
            #define iResolution float3(_Resolution, _Resolution, _Resolution)

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }


            #define rot(a) transpose(float2x2(cos(a), sin(a), -sin(a), cos(a)))
            static float3 glw;

            float bx(float3 p, float3 s)
            {
                float3 q = abs(p) - s;
                return min(max(q.x, max(q.y, q.z)), 0.) + length(max(q, 0.));
            }

            float2 mp(float3 p)
            {
                float scl = 0.8;
                for (int i = 0; i < 3; i++)
                {
                    p.yz = mul(p.yz,rot(scl-0.3));
                    p.y = abs(p.y) - scl;
                    p.x += p.y * scl;
                    scl -= abs(p.y) * 0.2;
                    p.xz = mul(p.xz,rot(_Time.y*0.4));
                }
                float s = length(p - float3(0, 0, 2));
                float b = bx(p, ((float3)scl)) - 0.1;
                b *= 0.5;
                b = min(s, b);
                s *= 8.;
                glw += 0.01 / (0.01 * s * s) * normalize(p * p);
                return float2(b, 1);
            }

            float2 tr(float3 ro, float3 rd, float z)
            {
                float2 d = ((float2)0);
                for (int i = 0; i < 256; i++)
                {
                    float2 s = mp(ro + rd * d.x);
                    s.x *= z;
                    d.x += s.x;
                    d.y = s.y;
                    if (s.x < 0.0001 || d.x > 64.)
                        break;
                }
                return d;
            }

            float3 nm(float3 p)
            {
                float2 e = float2(0.001, 0);
                return normalize(mp(p).x - float3(mp(p - e.xyy).x, mp(p - e.yxy).x, mp(p - e.yyx).x));
            }

            float4 px(float2 h, float3 p, float3 n, float3 r)
            {
                float4 bg = float4(0.1, 0.1, 0.8, 0) + length(r * r) * 0.5;
                if (h.x > 64.)
                    return bg;

                float4 fc = float4(0.4, 0.4, 1, 1);
                float3 ld = normalize(float3(0.6, 0.4, 0.8));
                float diff = length(n * ld);
                float fres = abs(1. - length(n * r)) * 0.2;
                float spec = pow(max(dot(reflect(ld, n) * ld, -r), 0.), 6.);
                float ao = clamp(1. - mp(p + n * 0.1).x * 10., 0., 1.) * 0.1;
                float sss = smoothstep(0., 1., mp(p * ld * 3.).x) * 0.6;
                fc.rgb += fc.rgb * sss;
                fc *= diff;
                fc += spec;
                fc += fres;
                fc -= ao;
                return fc;
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 fragCoord = i.uv * _Resolution;
                float2 uv = float2(fragCoord.x / iResolution.x, fragCoord.y / iResolution.y);
                uv -= 0.5;
                uv /= float2(iResolution.y / iResolution.x, 1);
                float3 ro = float3(0, 0, -5), rd = normalize(float3(uv, 1));
                float3 cp, cn, cr, h = ((float3)1);
                float4 cc, fc = ((float4)1);
                float io = 1.4;
                for (int i = 0; i < 4 * 2; i++)
                {
                    h.xy = tr(ro, rd, h.z);
                    cp = ro + rd * h.x;
                    cn = nm(cp);
                    cr = rd;
                    ro = cp - cn * (0.01 * h.z);
                    rd = refract(cr, cn * h.z, h.z > 0. ? 1. / io : io);
                    if (dot(rd, rd) == 0.)
                        rd = reflect(cr, cn * h.z);

                    cc = px(h.xy, cp, cn, cr);
                    h.z *= -1.;
                    if (h.z < 0.)
                        fc.rgb = lerp(fc.rgb, cc.rgb, fc.a);

                    fc.a *= cc.a;
                    if (fc.a <= 0. || h.x > 64.)
                        break;
                }
                float4 fragColor = ((float4)fc + glw.rgbb);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}