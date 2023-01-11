// https://www.shadertoy.com/view/DlXGWs
Shader "Unlit/PsychedelicSnowflake "
{
    Properties
    {
        _Speed("Speed",Range(0.1,10.0)) = 1.0
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Transparent" "Queue" = "Transparent"
        }
        LOD 100

        Pass
        {
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"


            const int maxstps = 100;
            const float maxdst = 100.0;
            const float mindst = 0.001;
            const float pi = 3.1415927410125732421875;
            const float tau = 6.283185482025146484375;
            const float IOR = 1.45;
            const float den = 0.2;
            const float i3 = 1.0 / 3.0;
            const float sFac = 0.0003;
            const float bgprd = 4.0;
            const float sq32 = sqrt(3.0) * 0.5;
            const float negs15 = -sqrt(2.0) * 0.25 * (sqrt(3.0) - 1.0);
            const float negc15 = sqrt(2.0) * 0.25 * (sqrt(3.0) + 1.0);

            #define fudge mindst * 3.0
            #define invIOR 1.0 / IOR
            #define pii3  pi * i3
            #define tFac  1.0 * tau / 6.0
            #define negi3Rot float2x2(0.5, sq32,-sq32, 0.5)
            #define negi3Rot2 float2x2(0.5, -sq32,sq32, 0.5)
            #define halfnegi3Rot float2x2(sq32, 0.5,-0.5, sq32)
            #define neg15Rot float2x2(negc15, -negs15,negs15, negc15)

            float2x2 tRot;

            float2x2 rot2D(float a)
            {
                float s = sin(a), c = cos(a);
                return float2x2(c, -s,
                                s, c);
            }

            // Huge thanks to iq for this smoothing function! https://iquilezles.org/articles/functions/
            float2 smoothabs(float2 x, float k)
            {
                return sqrt(x * x + k);
            }

            // And also thanks to iq for the geo functions and ops
            float sdHexagram(float2 p, float r)
            {
                const float4 k = float4(-0.5, 0.8660254038, 0.5773502692, 1.7320508076);
                p = abs(p);
                p -= 2.0 * min(dot(k.xy, p), 0.0) * k.xy;
                p -= 2.0 * min(dot(k.yx, p), 0.0) * k.yx;
                p -= float2(clamp(p.x, r * k.z, r * k.w), r);
                return length(p) * sign(p.y);
            }

            float opExtrusion(float3 p, float d, float h)
            {
                float2 w = float2(d, abs(p.z) - h);
                return min(max(w.x, w.y), 0.0) + length(max(w, 0.0));
            }

            // Fold a hexagram prism one plane at a time.
            float snowflake(float3 p)
            {
                p = p.zyx;
                p.yz = smoothabs(p.yz, sFac);
                p.yz = mul(negi3Rot2, p.yz);
                p.yz = smoothabs(p.yz, sFac);
                p.yz = mul(negi3Rot, p.yz);;
                p.y -= 1.0;
                p.xy = smoothabs(p.xy, sFac);
                p.y -= 0.5;
                p.xy = smoothabs(p.xy, sFac);
                p.xy = mul(negi3Rot * tRot, p.xy);
                p.xy -= 0.25;
                p.xy = smoothabs(p.xy, sFac);
                p.xy = mul(negi3Rot2 * tRot, p.xy);
                p.xy = smoothabs(p.xy, sFac);
                p.xy = mul(halfnegi3Rot, p.xy);
                p.yz = smoothabs(p.yz, sFac);
                p.yz = mul(halfnegi3Rot * tRot, p.yz);
                p.yz = smoothabs(p.yz, sFac);
                p.yz = mul(neg15Rot, p.yz);
                float d = opExtrusion(p.xzy, sdHexagram(p.xz, 0.5), 3.0);
                return d - 0.025;
            }

            float3 bg(float3 rn)
            {
                float at = atan2(rn.z, rn.x);
                return float3(cos(at * bgprd), cos((at + i3 * tau) * bgprd),
                              cos((at + 2.0 * i3 * tau) * bgprd)) * 0.5 + 0.5;
            }

            float map(float3 pos)
            {
                float d0 = snowflake(pos);
                return d0;
            }

            float rayMarch(float3 ro, float3 rd, float side)
            {
                float dO = 0.0;

                for (int i = 0; i < maxstps; i++)
                {
                    float3 p = ro + rd * dO;
                    float dS = map(p) * side;
                    dO += dS;
                    if (dO > maxdst || abs(dS) < mindst) break;
                }

                return dO;
            }

            float3 getNormal(float3 p)
            {
                float2 e = float2(.001, 0.0);
                float3 n = map(p) -
                    float3(map(p - e.xyy), map(p - e.yxy), map(p - e.yyx));

                return normalize(n);
            }

            // I know this isn't the best way to do it,
            // but it was easier for me to keep track
            // of what was going on here.
            float3 rflrm(float3 ro, float3 rd0)
            {
                float3 col = bg(rd0);

                float d0 = rayMarch(ro, rd0, 1.0);

                if (d0 < maxdst)
                {
                    float3 h0 = ro + rd0 * d0;
                    float3 n0 = getNormal(h0);
                    float frsn0 = pow(1.0 + dot(rd0, n0), 5.0);
                    float3 rd1 = reflect(rd0, n0);
                    float3 reflbg = bg(rd1);
                    float3 rd2 = refract(rd0, n0, invIOR);

                    float3 h0offs = h0 - n0 * fudge;
                    float d1 = rayMarch(h0offs, rd2, -1.0);

                    float3 h1 = h0offs + rd2 * d1;
                    float3 n1 = -getNormal(h1);

                    float3 refrbg = bg(rd1);


                    float3 rd3 = refract(rd2, n1, IOR);
                    rd3 = (dot(rd3, rd3) == 0.0) ? reflect(rd2, n1) : rd3;
                    refrbg = bg(rd3);

                    float optDst = exp(-d1 * den);
                    refrbg = refrbg * optDst;

                    col = lerp(refrbg, reflbg, frsn0);
                }

                return col;
            }

            struct appdata
            {
                fixed4 vertex : POSITION;
                fixed2 uv : TEXCOORD0;
            };

            struct v2f
            {
                fixed2 uv : TEXCOORD0;
                fixed4 vertex : SV_POSITION;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }


            fixed _Speed;


            fixed4 frag(v2f i) : SV_Target
            {
                tRot = rot2D(_Time.y * tFac);
                float2 fragCoord = float2(i.uv.x * _ScreenParams.x, i.uv.y * _ScreenParams.y);
                float2 uv = (fragCoord - 0.5 * _ScreenParams.xy) / _ScreenParams.y;
                float2 m = float2(0.5, 0.5);
                float2x2 rmxz = float2x2(0, 0, 0, 0);
                float2x2 rmyz = float2x2(0, 0, 0, 0);

                // if (iMouse.z > 0.0)
                // {
                //     m = -iMouse.xy / iResolution.xy;
                //     rmxz = rot2D(m.x * tau);
                //     rmyz = rot2D(m.y * tau + pi);
                // }
                // else
                // {
                //     rmxz = rot2D(m.x * tau + sin(_Time.y * tFac) * 0.5);
                //     rmyz = rot2D(m.y * tau + 2.7);
                // }

                rmxz = rot2D(m.x * tau + sin(_Time.y * tFac) * 0.5);
                rmyz = rot2D(m.y * tau + 2.7);

                float3 ro = float3(0.0, 3.3, -7.7);
                ro.yz = mul(rmyz, ro.yz);
                ro.xz = mul(rmxz, ro.xz);
                float3 rd0 = normalize(float3(uv.x, uv.y, 1.0));
                rd0.yz = mul(rot2D(0.42), rd0.yz);
                rd0.yz = mul(rmyz, rd0.yz);
                rd0.xz = mul(rmxz, rd0.xz);

                float3 col = bg(rd0);

                float d0 = rayMarch(ro, rd0, 1.0);

                if (d0 < maxdst)
                {
                    float3 h0 = ro + rd0 * d0;
                    float3 n0 = getNormal(h0);
                    float frsn0 = pow(1.0 + dot(rd0, n0), 5.0);
                    float3 rd1 = reflect(rd0, n0);
                    float3 reflbg = rflrm(h0, rd1);
                    float3 rd2 = refract(rd0, n0, invIOR);

                    float3 h0offs = h0 - n0 * fudge;
                    float d1 = rayMarch(h0offs, rd2, -1.0);

                    float3 h1 = h0offs + rd2 * d1;
                    float3 n1 = -getNormal(h1);

                    float3 h1offs = h1 - n1 * fudge;

                    float3 refrbg = bg(rd1);

                    float3 rd3 = refract(rd2, n1, IOR);

                    float d2 = 0.0;
                    if (dot(rd3, rd3) == 0.0)
                    {
                        rd3 = reflect(rd2, n1);
                        d2 = rayMarch(h1, rd3, -1.0);
                        float3 h2 = h1 + rd3 * d2;

                        // Should this be flipped?
                        float3 n2 = -getNormal(h2);

                        float3 rd4 = refract(h2, n2, IOR);
                        rd4 = (dot(rd4, rd4) == 0.0) ? reflect(rd3, n2) : rd4;
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


                col = pow(col, float3(0.4545, 0.4545, 0.4545));

                return float4(col, 1.0);
            }
            ENDCG
        }
    }
}