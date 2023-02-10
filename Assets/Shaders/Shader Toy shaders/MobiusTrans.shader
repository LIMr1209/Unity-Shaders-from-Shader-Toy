// https://www.shadertoy.com/view/4scfR2
Shader "Unlit/MobiusTrans"
{
    Properties
    {
        [Header(General)]
        _MainTex ("iChannel0", 2D) = "white" {}
        [ToggleUI] _GammaCorrect ("Gamma Correction", Float) = 1
        _Resolution ("Resolution (Change if AA is bad)", Range(1, 1024)) = 1
        [ToggleUI] _ScreenEffect("ScreenEffect", Float) = 0
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
            float _ScreenEffect;
            sampler2D _MainTex;   float4 _MainTex_TexelSize;

            // GLSL Compatability macros
            #define glsl_mod(x,y) (((x)-(y)*floor((x)/(y))))
            #define texelFetch(ch, uv, lod) tex2Dlod(ch, float4((uv).xy * ch##_TexelSize.xy + ch##_TexelSize.xy * 0.5, 0, lod))
            #define iResolution float3(_Resolution, _Resolution, _Resolution)

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            #define PI 3.1415927
            #define E_ 2.7182817
            #define AA 1
            #define MIN_TRACE_DIST 0.01
            #define MAX_TRACE_STEPS 255
            #define PRECISION 0.00001
            #define FAR 100.
            #define anim_speed (_Time.y*0.5)
            #define hue_speed (_Time.y*0.3)
            static const float2 polar_grid = float2(0.4, PI / 7.);
            static const float2 cone_angle = normalize(float2(1.5, 1.));
            static const float intensity_divisor = 40000.;
            static const float intensity_factor_max = 7.2;
            static const float center_intensity = 12.;
            static const float dist_factor = 3.;
            static const float ppow = 1.9;
            static const float center_hue = 0.5;
            static const float center_sat = 0.18;
            static const float strong_factor = 7.;
            static const float weak_factor = 1.;
            static const float2 star_hv_factor = float2(30, 1);
            static const float2 star_diag_factor = float2(30, 1);
            static bool b_apply = true;
            static bool b_elliptic = true;
            static bool b_hyperbolic = true;
            static bool b_riemann = true;
            static bool b_parabolic, b_loxodromic;

            float3 hsv2rgb(float3 hsv)
            {
                const float3 p = float3(0., 2. / 3., 1. / 3.);
                hsv.yz = clamp(hsv.yz, 0., 1.);
                return hsv.z * (0.63 * hsv.y * (cos(2. * PI * (hsv.x + p)) - 1.) + 1.);
            }

            float eucToHyp(float d)
            {
                return log(d);
            }

            float hypToEuc(float d)
            {
                return pow(E_, d);
            }

            float2 rot2d(float2 p, float a)
            {
                return cos(a) * p + sin(a) * float2(p.y, -p.x);
            }

            float grid1d(float x, float size)
            {
                return glsl_mod(x+0.5*size, size) - 0.5 * size;
            }

            float2 grid2d(float2 p, float2 size)
            {
                return glsl_mod(p+0.5*size, size) - 0.5 * size;
            }

            float2 polarGrid(float2 p, float2 size)
            {
                float theta = atan2(p.y, p.x);
                float r = eucToHyp(length(p));
                return grid2d(float2(r, theta), size);
            }

            float2 cmul(float2 z, float2 w)
            {
                return float2(z.x * w.x - z.y * w.y, z.x * w.y + z.y * w.x);
            }

            float2 cdiv(float2 z, float2 w)
            {
                return float2(z.x * w.x + z.y * w.y, -z.x * w.y + z.y * w.x) / dot(w, w);
            }

            float2 csqrt(float2 z)
            {
                float r2 = dot(z, z);
                float r = sqrt(sqrt(r2));
                float angle = atan2(z.y, z.x);
                return r * float2(cos(angle / 2.), sin(angle / 2.));
            }

            float4 qmul(float4 p, float4 q)
            {
                return float4(p.x * q.x - dot(p.yzw, q.yzw), p.x * q.yzw + q.x * p.yzw + cross(p.yzw, q.yzw));
            }

            float4 qdiv(float4 p, float4 q)
            {
                return qmul(p, float4(q.x, -q.yzw) / dot(q, q));
            }

            struct Mobius
            {
                float2 A, B, C, D;
            };


            static const Mobius mob = {-1, 0, 1.2, 0, -1, 0, -1.2, 0};

            float2 applyMobius(float2 z)
            {
                float2 z1 = cmul(mob.A, z) + mob.B;
                float2 z2 = cmul(mob.C, z) + mob.D;
                return cdiv(z1, z2);
            }

            float4 applyMobius(float4 p)
            {
                float4 p1 = qmul(float4(mob.A, 0., 0.), p) + float4(mob.B, 0., 0.);
                float4 p2 = qmul(float4(mob.C, 0., 0.), p) + float4(mob.D, 0., 0.);
                return qdiv(p1, p2);
            }

            float applyMobius(inout float3 p)
            {
                if (!b_apply)
                    return 1.;

                p = applyMobius(float4(p, 0)).xyz;
                float scale = length(p);
                return scale > 1. ? 1. / scale : scale;
            }

            void trans_hyperbolic(inout float2 p)
            {
                float d = eucToHyp(length(p)) - anim_speed * polar_grid.x;
                d = grid1d(d, polar_grid.x);
                p = normalize(p) * hypToEuc(d);
            }

            void trans_elliptic(inout float2 p)
            {
                p = rot2d(p, anim_speed * polar_grid.y);
            }

            void trans_parabolic(inout float2 p)
            {
                p.x += _Time.y * polar_grid.x / 3.;
            }

            float sdSphere(float3 p, float r)
            {
                p.y -= r;
                return length(p) - r;
            }

            float sdPlane(float3 p)
            {
                return p.y;
            }

            float sdPlane(float3 p, float c)
            {
                return p.y - c;
            }

            float sdCone(float3 p)
            {
                float t = 1.;
                if (b_apply)
                {
                    t = applyMobius(p);
                    p = normalize(p);
                }

                float q = length(p.xz);
                return dot(cone_angle, float2(q, -p.y)) * t;
            }

            float sdScene1(float3 p)
            {
                return b_apply ? min(sdPlane(p), sdSphere(p, 1.)) : sdPlane(p, 0.5);
            }

            float sdScene2(float3 p)
            {
                if (b_riemann)
                    return min(sdPlane(p), sdSphere(p, 1.));

                return min(sdPlane(p), sdCone(p));
            }

            float3 getColor(float2 p, float pint)
            {
                float sat = 0.75 / pow(pint, 2.5) + center_sat;
                float hue2 = b_parabolic ? hue_speed - length(p.y) / 5. : hue_speed - eucToHyp(length(p)) / 7.;
                float hue = center_hue + hue2;
                return hsv2rgb(float3(hue, sat, pint)) + pint / 3.;
            }

            float getIntensity1(float2 p)
            {
                float dist = length(p);
                float disth = length(p * star_hv_factor);
                float distv = length(p * star_hv_factor.yx);
                float2 q = 0.7071 * float2(dot(p, ((float2)1.)), dot(p, float2(1., -1.)));
                float dist1 = length(q * star_diag_factor);
                float dist2 = length(q * star_diag_factor.yx);
                float pint1 = 0.5 / (dist * dist_factor + 0.015) + strong_factor / (distv * dist_factor + 0.01) +
                    weak_factor / (disth * dist_factor + 0.01) + weak_factor / (dist1 * dist_factor + 0.01) +
                    weak_factor / (dist2 * dist_factor + 0.01);
                return center_intensity * intensity_factor_max * pow(pint1, ppow) / intensity_divisor;
            }

            float getIntensity2(float2 p)
            {
                float angle = atan2(polar_grid.x, polar_grid.y);
                float dist = length(p);
                float disth = length(p * star_hv_factor);
                float distv = length(p * star_hv_factor.yx);
                float2 q1 = rot2d(p, angle);
                float dist1 = length(q1 * star_diag_factor);
                float2 q2 = rot2d(p, -angle);
                float dist2 = length(q2 * star_diag_factor);
                float pint1 = 1. / (dist * dist_factor + 0.5);
                if (b_loxodromic)
                {
                    pint1 = strong_factor / (dist2 * dist_factor + 0.01) + weak_factor / (dist1 * dist_factor + 0.01) +
                        weak_factor / (disth * dist_factor + 0.01) + weak_factor / (distv * dist_factor + 0.01);
                }
                else if (b_elliptic)
                {
                    pint1 += weak_factor / (distv * dist_factor + 0.01) + strong_factor / (disth * dist_factor + 0.01) +
                        weak_factor / (dist1 * dist_factor + 0.01) + weak_factor / (dist2 * dist_factor + 0.01);
                }
                else
                {
                    pint1 += weak_factor / (disth * dist_factor + 1.) + strong_factor / (distv * dist_factor + 0.01) +
                        weak_factor / (dist1 * dist_factor + 0.01) + weak_factor / (dist2 * dist_factor + 0.01);
                }
                return intensity_factor_max * pow(pint1, ppow) / intensity_divisor * center_intensity * 3.;
            }

            float map(float3 pos)
            {
                return b_parabolic ? sdScene1(pos) : sdScene2(pos);
            }

            float3 getNormal(float3 p)
            {
                float2 e = float2(0.003, 0);
                float d1 = map(p + e.xyy), d2 = map(p - e.xyy);
                float d3 = map(p + e.yxy), d4 = map(p - e.yxy);
                float d5 = map(p + e.yyx), d6 = map(p - e.yyx);
                float d = map(p) * 2.;
                return normalize(float3(d1 - d2, d3 - d4, d5 - d6));
            }

            float softShadow(float3 ro, float3 rd, float tmin, float tmax, float k)
            {
                const int maxShadeIterations = 20;
                float res = 1.;
                float t = tmin;
                for (int i = 0; i < maxShadeIterations; i++)
                {
                    float h = map(ro + rd * t);
                    res = min(res, smoothstep(0., 1., k * h / t));
                    t += clamp(h, 0.01, 0.2);
                    if (abs(h) < 0.0001 || t > tmax)
                        break;
                }
                return clamp(res + 0.15, 0., 1.);
            }

            float calcAO(float3 p, float3 n)
            {
                float occ = 0.;
                float sca = 1.;
                for (int i = 0; i < 5; i++)
                {
                    float h = 0.01 + 0.15 * float(i) / 4.;
                    float d = map(p + h * n);
                    occ += (h - d) * sca;
                    sca *= 0.7;
                }
                return clamp(1. - 3. * occ, 0., 1.);
            }

            float trace(float3 ro, float3 rd, out float2 p, out float pint)
            {
                pint = 0;
                p = 0;
                float depth = MIN_TRACE_DIST;
                float dist;
                float3 pos;
                for (int i = 0; i < MAX_TRACE_STEPS; i++)
                {
                    pos = ro + rd * depth;
                    dist = map(pos);
                    if (dist < PRECISION || depth >= FAR)
                        break;

                    depth += dist;
                }
                if (b_parabolic)
                {
                    if (b_apply)
                        pos /= dot(pos, pos);

                    p = pos.xz;
                    trans_parabolic(pos.xz);
                    pos.xz = grid2d(pos.xz, ((float2)polar_grid.x / 2.));
                    pint = getIntensity1(pos.xz);
                }
                else
                {
                    applyMobius(pos);
                    p = pos.xz;
                    if (b_hyperbolic)
                        trans_hyperbolic(pos.xz);

                    if (b_elliptic)
                        trans_elliptic(pos.xz);

                    pos.xz = polarGrid(pos.xz, polar_grid);
                    pint = getIntensity2(pos.xz);
                }
                return depth;
            }

            float3 tonemap(float3 color)
            {
                const float A = 2.51;
                const float B = 0.03;
                const float C = 2.43;
                const float D = 0.59;
                const float E = 0.14;
                return color * (A * color + B) / (color * (C * color + D) + E);
            }

            static const int CHAR_1 = 49;
            static const int CHAR_2 = 50;
            static const int CHAR_3 = 51;
            static const int CHAR_4 = 52;

            bool keypress(int code)
            {
                return texelFetch(_MainTex, int2(code, 2), 0).x != 0.;
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 fragCoord = i.uv * _Resolution;
                b_apply = !keypress(CHAR_1);
                b_elliptic = !keypress(CHAR_2);
                b_hyperbolic = !keypress(CHAR_3);
                b_riemann = keypress(CHAR_4);
                b_parabolic = !(b_elliptic || b_hyperbolic);
                b_loxodromic = b_elliptic && b_hyperbolic;
                float3 ro = float3(-2.4, 4.8, 7.);
                ro.xz = rot2d(ro.xz, _Time.y * 0.3);
                float3 lookat = float3(0., 0.6, 0.);
                float3 up = float3(0., 1., 0.);
                float3 f = normalize(lookat - ro);
                float3 r = normalize(cross(f, up));
                float3 u = normalize(cross(r, f));
                float3 tot = ((float3)0);
                float3 lp = ro + float3(0.2, 0.8, -0.2);
                for (int ii = 0; ii < AA; ii++)
                {
                    for (int jj = 0; jj < AA; jj++)
                    {
                        float2 offset = float2(float(ii), float(jj)) / float(AA);
                        float2 uv = (fragCoord + offset) / iResolution.xy;
                        uv = 2. * uv - 1.;
                        uv.x *= iResolution.x / iResolution.y;
                        float3 rd = normalize(uv.x * r + uv.y * u + 4. * f);
                        float2 p;
                        float pint;
                        float t = trace(ro, rd, p, pint);
                        if (t >= 0.)
                        {
                            float3 col = tonemap(4. * getColor(p, pint));
                            float3 pos = ro + rd * t;
                            float3 nor = getNormal(pos);
                            float3 ld = lp - pos;
                            float dist = max(length(ld), 0.001);
                            ld /= dist;
                            float at = 2.2 / (1. + dist * 0.1 + dist * dist * 0.05);
                            float ao = calcAO(pos, nor);
                            float sh = softShadow(pos, ld, 0.04, dist, 8.);
                            float diff = clamp(dot(nor, ld), 0., 1.);
                            float spec = max(0., dot(reflect(-ld, nor), -rd));
                            spec = pow(spec, 50.);
                            tot += diff * 2.5 * col + float3(0.6, 0.8, 0.8) * spec * 2.;
                            tot *= ao * sh * at;
                        }

                        if (t >= FAR)
                            lp = normalize(lp - ro - rd * FAR);

                        float3 bg = lerp(float3(0.5, 0.7, 1), float3(1, 0.5, 0.6), 0.5 - 0.5 * lp.y) * 0.3;
                        tot = lerp(clamp(tot, 0., 1.), bg, smoothstep(0., FAR - 2., t));
                    }
                }
                tot /= float(AA * AA);
                float4 fragColor = float4(sqrt(clamp(tot, 0., 1.)), 1.);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}