// https://www.shadertoy.com/view/DlXGWs
Shader "Unlit/PsychedelicSnowflake"
{
    Properties
    {
        _Mouse ("Mouse", Vector) = (0.5, 0.5, 0.5, 0.5)
        [ToggleUI] _GammaCorrect ("Gamma Correction", Float) = 1
        _Resolution ("Resolution (Change if AA is bad)", Range(1, 1024)) = 1
        [ToggleUI] _ScreenEffect("ScreenEffect", Float) = 0

        [Header(Extracted)]
        bgprd ("bgprd", Float) = 4
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
            float4 _Mouse;
            float _GammaCorrect;
            float _Resolution;
            float _ScreenEffect;

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

            #define pi 3.1415927
            #define tau 6.2831855

            static const int maxstps = 100;
            static const float maxdst = 100.;
            static const float mindst = 0.001;
            static const float fudge = mindst * 3.;
            static const float IOR = 1.45;
            static const float invIOR = 1. / IOR;
            static const float den = 0.2;
            static const float i3 = 1. / 3.;
            static const float pii3 = pi * i3;
            static const float tFac = 1. * tau / 6.;
            static const float sFac = 0.0003;
            const float bgprd = 4.;
            static const float sq32 = sqrt(3.) * 0.5;
            static const float negs15 = -sqrt(2.) * 0.25 * (sqrt(3.) - 1.);
            static const float negc15 = sqrt(2.) * 0.25 * (sqrt(3.) + 1.);
            static const float2x2 negi3Rot = transpose(float2x2(0.5, sq32, -sq32, 0.5));
            static const float2x2 negi3Rot2 = transpose(float2x2(0.5, -sq32, sq32, 0.5));
            static const float2x2 halfnegi3Rot = transpose(float2x2(sq32, 0.5, -0.5, sq32));
            static const float2x2 neg15Rot = transpose(float2x2(negc15, -negs15, negs15, negc15));
            static float2x2 tRot;

            float2x2 rot2D(float a)
            {
                float s = sin(a), c = cos(a);
                return transpose(float2x2(c, -s, s, c));
            }

            float2 smoothabs(float2 x, float k)
            {
                return sqrt(x * x + k);
            }

            float sdHexagram(float2 p, float r)
            {
                const float4 k = float4(-0.5, 0.8660254, 0.57735026, 1.7320508);
                p = abs(p);
                p -= 2. * min(dot(k.xy, p), 0.) * k.xy;
                p -= 2. * min(dot(k.yx, p), 0.) * k.yx;
                p -= float2(clamp(p.x, r * k.z, r * k.w), r);
                return length(p) * sign(p.y);
            }

            float opExtrusion(float3 p, float d, float h)
            {
                float2 w = float2(d, abs(p.z) - h);
                return min(max(w.x, w.y), 0.) + length(max(w, 0.));
            }

            float snowflake(float3 p)
            {
                p = p.zyx;
                p.yz = smoothabs(p.yz, sFac);
                p.yz = mul(p.yz, negi3Rot2);
                p.yz = smoothabs(p.yz, sFac);
                p.yz = mul(p.yz, negi3Rot);
                p.y -= 1.;
                p.xy = smoothabs(p.xy, sFac);
                p.y -= 0.5;
                p.xy = smoothabs(p.xy, sFac);
                p.xy = mul(mul(negi3Rot, tRot), p.xy);
                p.xy -= 0.25;
                p.xy = smoothabs(p.xy, sFac);
                p.xy = mul(mul(negi3Rot2, tRot), p.xy);
                p.xy = smoothabs(p.xy, sFac);
                p.xy = mul(p.xy, halfnegi3Rot);
                p.yz = smoothabs(p.yz, sFac);
                p.yz = mul(mul(halfnegi3Rot, tRot), p.yz);
                p.yz = smoothabs(p.yz, sFac);
                p.yz = mul(p.yz, neg15Rot);
                float d = opExtrusion(p.xzy, sdHexagram(p.xz, 0.5), 3.);
                return d - 0.025;
            }

            float3 bg(float3 rn)
            {
                float at = atan2(rn.x, rn.z);
                return float3(cos(at * bgprd), cos((at + i3 * tau) * bgprd),
                              cos((at + 2. * i3 * tau) * bgprd)) * 0.5 + 0.5;
            }

            float map(float3 pos)
            {
                float d0 = snowflake(pos);
                return d0;
            }

            float rayMarch(float3 ro, float3 rd, float side)
            {
                float dO = 0.;
                for (int i = 0; i < maxstps; i++)
                {
                    float3 p = ro + rd * dO;
                    float dS = map(p) * side;
                    dO += dS;
                    if (dO > maxdst || abs(dS) < mindst)
                        break;
                }
                return dO;
            }

            float3 getNormal(float3 p)
            {
                float2 e = float2(0.001, 0.);
                float3 n = map(p) - float3(map(p - e.xyy), map(p - e.yxy), map(p - e.yyx));
                return normalize(n);
            }

            float3 rflrm(float3 ro, float3 rd0)
            {
                float3 col = bg(rd0);
                float d0 = rayMarch(ro, rd0, 1.);
                if (d0 < maxdst)
                {
                    float3 h0 = ro + rd0 * d0;
                    float3 n0 = getNormal(h0);
                    float frsn0 = pow(1. + dot(rd0, n0), 5.);
                    float3 rd1 = reflect(rd0, n0);
                    float3 reflbg = bg(rd1);
                    float3 rd2 = refract(rd0, n0, invIOR);
                    float3 h0offs = h0 - n0 * fudge;
                    float d1 = rayMarch(h0offs, rd2, -1.);
                    float3 h1 = h0offs + rd2 * d1;
                    float3 n1 = -getNormal(h1);
                    float3 refrbg = bg(rd1);
                    float3 rd3 = refract(rd2, n1, IOR);
                    rd3 = dot(rd3, rd3) == 0. ? reflect(rd2, n1) : rd3;
                    refrbg = bg(rd3);
                    float optDst = exp(-d1 * den);
                    refrbg = refrbg * optDst;
                    col = lerp(refrbg, reflbg, frsn0);
                }

                return col;
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 fragCoord;
                float2 uv;
                if (_ScreenEffect)
                {
                    fragCoord = i.uv * _ScreenParams;
                    uv = (fragCoord - 0.5 * _ScreenParams.xy) / _ScreenParams.y;
                }
                else
                {
                    fragCoord = i.uv * iResolution;
                    uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
                }
                tRot = rot2D(_Time.y * tFac);
                float2 m = ((float2)0.5);
                float2x2 rmxz = ((float2x2)0.);
                float2x2 rmyz = ((float2x2)0.);
                if (_Mouse.z > 0.)
                {
                    if (_ScreenEffect)
                    {
                        m = -_Mouse.xy / _ScreenParams.xy;
                    }
                    else
                    {
                        m = -_Mouse.xy / iResolution.xy;
                    }
                    rmxz = rot2D(m.x * tau);
                    rmyz = rot2D(m.y * tau + pi);
                }
                else
                {
                    rmxz = rot2D(m.x * tau + sin(_Time.y * tFac) * 0.5);
                    rmyz = rot2D(m.y * tau + 2.7);
                }
                float3 ro = float3(0., 3.3, -7.7);
                ro.yz = mul(ro.yz, rmyz);
                ro.xz = mul(ro.xz, rmxz);
                float3 rd0 = normalize(float3(uv.x, uv.y, 1.));
                rd0.yz = mul(rd0.yz, rot2D(0.42));
                rd0.yz = mul(rd0.yz, rmyz);
                rd0.xz = mul(rd0.xz, rmxz);
                float3 col = bg(rd0);
                float d0 = rayMarch(ro, rd0, 1.);
                if (d0 < maxdst)
                {
                    float3 h0 = ro + rd0 * d0;
                    float3 n0 = getNormal(h0);
                    float frsn0 = pow(1. + dot(rd0, n0), 5.);
                    float3 rd1 = reflect(rd0, n0);
                    float3 reflbg = rflrm(h0, rd1);
                    float3 rd2 = refract(rd0, n0, invIOR);
                    float3 h0offs = h0 - n0 * fudge;
                    float d1 = rayMarch(h0offs, rd2, -1.);
                    float3 h1 = h0offs + rd2 * d1;
                    float3 n1 = -getNormal(h1);
                    float3 h1offs = h1 - n1 * fudge;
                    float3 refrbg = bg(rd1);
                    float3 rd3 = refract(rd2, n1, IOR);
                    float d2 = 0.;
                    if (dot(rd3, rd3) == 0.)
                    {
                        rd3 = reflect(rd2, n1);
                        d2 = rayMarch(h1, rd3, -1.);
                        float3 h2 = h1 + rd3 * d2;
                        float3 n2 = -getNormal(h2);
                        float3 rd4 = refract(h2, n2, IOR);
                        rd4 = dot(rd4, rd4) == 0. ? reflect(rd3, n2) : rd4;
                        refrbg = bg(rd4);
                    }
                    else
                    {
                        refrbg = rflrm(h1offs, rd3);
                    }
                    float optDst = exp(-d1 * den);
                    refrbg = refrbg * optDst;
                    col = lerp(refrbg, reflbg, frsn0);
                }

                col = pow(col, ((float3)0.4545));
                float4 fragColor = float4(col, 1.);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}