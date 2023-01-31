// https://www.shadertoy.com/view/DlB3WG
Shader "Unlit/MindFlowers "
{
    Properties
    {

    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            #define PI          3.141592654
            #define PI_2        (0.5*PI)
            #define TAU         (2.0*PI)
            #define BPM         (157.0/4.0)
            #define PCOS(a)     0.5*(cos(a)+1.0)

            const float planeDist = 1.0 - 0.80;
            const int furthest = 16;
            // #define fadeFrom max(furthest - 4, 0)
            const int fadeFrom = 12;
            // #define fadeDist planeDist * float(furthest - fadeFrom)
            const float fadeDist = 0.8;

            const float overSample = 4.0;
            // #define ringDistance 0.075 * overSample / 4.0
            const float ringDistance = 0.075;
            // #define noOfRings 20.0 * 4.0 / overSample
            const float noOfRings = 20.0;
            const float glowFactor = 0.05;
            


            float4 alphaBlend(float4 back, float4 front)
            {
                float w = front.w + back.w * (1.0 - front.w);
                float3 xyz = (front.xyz * front.w + back.xyz * back.w * (1.0 - front.w)) / w;
                return w > 0.0 ? float4(xyz, w) : float4(0,0,0,0);
            }

            // License: Unknown, author: Unknown, found: don't remember
            float3 alphaBlend(float3 back, float4 front)
            {
                return lerp(back, front.xyz, front.w);
            }

            // License: Unknown, author: Unknown, found: don't remember
            float tanh_approx(float x)
            {
                //  Found this somewhere on the interwebs
                //  return tanh(x);
                float x2 = x * x;
                return clamp(x * (27.0 + x2) / (27.0 + 9.0 * x2), -1.0, 1.0);
            }

            // License: Unknown, author: Unknown, found: don't remember
            float hash(float co)
            {
                return frac(sin(co * 12.9898) * 13758.5453);
            }

            float3 offset(float z)
            {
                float a = z;
                float2 p = -0.15 * (float2(cos(a), sin(a * sqrt(2.0))) + float2(cos(a * sqrt(0.75)), sin(a * sqrt(0.5))));
                return float3(p, z);
            }

            float3 doffset(float z)
            {
                float eps = 0.05;
                return 0.5 * (offset(z + eps) - offset(z - eps)) / (2.0 * eps);
            }

            float3 ddoffset(float z)
            {
                float eps = 0.05;
                return 0.5 * (doffset(z + eps) - doffset(z - eps)) / (2.0 * eps);
            }

            float3 skyColor(float3 ro, float3 rd)
            {
                return float3(0,0,0);
            }

            // License: MIT OR CC-BY-NC-4.0, author: mercury, found: https://mercury.sexy/hg_sdf/
            float fmod1(inout float p, float size)
            {
                float halfsize = size * 0.5;
                float c = floor((p + halfsize) / size);
                p = fmod(p + halfsize, size) - halfsize;
                return c;
            }

            // License: MIT, author: Pascal Gilcher, found: https://www.shadertoy.com/view/flSXRV
            float atan_approx(float y, float x)
            {
                float cosatan2 = x / (abs(x) + abs(y));
                float t = PI_2 - cosatan2 * PI_2;
                return y < 0.0 ? -t : t;
            }


            // License: CC0, author: Mårten Rånge, found: https://github.com/mrange/glsl-snippets
            float2 toPolar(float2 p)
            {
                return float2(length(p), atan_approx(p.y, p.x));
            }

            float3 glow(float2 pp, float h)
            {
                float hh = frac(h * 8677.0);
                float b = TAU * h + 0.5 * _Time.y * (hh > 0.5 ? 1.0 : -1.0);
                float a = pp.y + b;
                float d = max(abs(pp.x) - 0.001, 0.00125);
                return
                    (smoothstep(0.667 * ringDistance, 0.2 * ringDistance, d)
                        * smoothstep(0.1, 1.0, cos(a))
                        * glowFactor
                        * ringDistance
                        / d
                    )
                    * (cos(a + b + float3(0, 1, 2)) + float3(1,1,1));
            }

            float3 glowRings(float2 p, float hh)
            {
                float2 pp = toPolar(p);

                //  pp.y += TAU*hh;
                float3 col = float3(0,0,0);
                float h = 1.0;
                const float nr = 1.0 / overSample;

                for (float i = 0.0; i < overSample; ++i)
                {
                    float2 ipp = pp;
                    ipp.x -= ringDistance * (nr * i);
                    float rn = fmod1(ipp.x, ringDistance);
                    h = hash(rn + 123.0 * i);
                    col += glow(ipp, h) * step(rn, noOfRings);
                }

                col += (0.01 * float3(1.0, 0.25, 0.0)) / length(p);

                return col;
            }

            float4 plane(float3 ro, float3 rd, float3 pp, float3 off, float aa, float n)
            {
                float h = hash(n + 123.4);

                float3 hn;
                float2 p = (pp - off * float3(1.0, 1.0, 0.0)).xy;
                float l = length(p);
                float fade = smoothstep(0.1, 0.15, l);
                if (fade < 0.1) return float4(0,0,0,0);
                float4 col = float4(0,0,0,0);

                col.xyz = glowRings(p * lerp(0.5, 4.0, h), h);
                float i = max(max(col.x, col.y), col.z);

                col.w = (tanh_approx(0.5 + max((i), 0.0)) * fade);
                return col;
            }

            float3 color(float3 ww, float3 uu, float3 vv, float3 ro, float2 p)
            {
                float lp = length(p);
                float2 np = p + 1.0 / _ScreenParams.xy;
                const float rdd_per = 10.0;
                float rdd = (1.75 + 0.75 * pow(lp, 1.5) *
                    tanh_approx(lp + 0.9 * PCOS(rdd_per*p.x) * PCOS(rdd_per*p.y)));
                //  float rdd = 2.0;

                float3 rd = normalize(p.x * uu + p.y * vv + rdd * ww);
                float3 nrd = normalize(np.x * uu + np.y * vv + rdd * ww);

                float nz = floor(ro.z / planeDist);

                float3 skyCol = skyColor(ro, rd);


                float4 acol = float4(0,0,0,0);
                const float cutOff = 0.95;
                bool cutOut = false;

                float maxpd = 0.0;

                // Steps from nearest to furthest plane and accumulates the color 
                for (int i = 1; i <= furthest; ++i)
                {
                    float pz = planeDist * nz + planeDist * float(i);

                    float pd = (pz - ro.z) / rd.z;

                    if (pd > 0.0 && acol.w < cutOff)
                    {
                        float3 pp = ro + rd * pd;
                        maxpd = pd;
                        float3 npp = ro + nrd * pd;

                        float aa = 3.0 * length(pp - npp);

                        float3 off = offset(pp.z);

                        float4 pcol = plane(ro, rd, pp, off, aa, nz + float(i));

                        float nz = pp.z - ro.z;
                        float fadeIn = smoothstep(planeDist * float(furthest), planeDist * float(fadeFrom), nz);
                        float fadeOut = smoothstep(0.0, planeDist * 0.1, nz);
                        pcol.w *= fadeOut * fadeIn;
                        pcol = clamp(pcol, 0.0, 1.0);

                        acol = alphaBlend(pcol, acol);
                    }
                    else
                    {
                        cutOut = true;
                        acol.w = acol.w > cutOff ? 1.0 : acol.w;
                        break;
                    }
                }

                float3 col = alphaBlend(skyCol, acol);
                // To debug cutouts due to transparency  
                //  col += cutOut ? float3(1.0, -1.0, 0.0) : float3(0.0);
                return col;
            }

            float3 effect(float2 p)
            {
                float tm = planeDist * _Time.y * BPM / 60.0;
                float3 ro = offset(tm);
                float3 dro = doffset(tm);
                float3 ddro = ddoffset(tm);

                float3 ww = normalize(dro);
                float3 uu = normalize(cross(normalize(float3(0.0, 1.0, 0.0) + ddro), ww));
                float3 vv = cross(ww, uu);

                float3 col = color(ww, uu, vv, ro, p);

                // Random color tweaks
                col -= 0.075 * float3(2.0, 3.0, 1.0);
                col *= sqrt(2.0);
                col = clamp(col, 0.0, 1.0);
                col = sqrt(col);
                return col;
            }


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

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            #define bpm 150.
            #define beat floor(_Time.y*bpm/60.)
            #define ttime _Time.y*bpm/60.

            fixed2x2 r(fixed a)
            {
                fixed c = cos(a), s = sin(a);
                return fixed2x2(c, -s, s, c);
            }

            fixed fig(fixed2 uv)
            {
                uv = mul(uv, r(-3.1415 * .9));
                return min(1., .1 / abs(
                               (atan2(uv.y, uv.x) / 2. * 3.1415) - sin(- ttime + (min(.6, length(uv))) * 3.1415 * 8.)));
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float2 fragCoord = float2(i.uv.x * _ScreenParams.x, i.uv.y * _ScreenParams.y);
                float2 q = fragCoord / _ScreenParams.xy;
                float2 p = -1. + 2. * q;
                p.x *= _ScreenParams.x / _ScreenParams.y;

                float3 col = effect(p);
                return float4(col, 1.0);
            }
            ENDCG
        }
    }
}