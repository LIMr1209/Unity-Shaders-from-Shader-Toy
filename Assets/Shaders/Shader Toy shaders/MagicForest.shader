// https://www.shadertoy.com/view/dtX3zl


Shader "Unlit/MagicForest "
{
    Properties
    {
        _Mouse ("Mouse", Vector) = (0.5, 0.5, 0.5, 0.5)
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
            float4 _Mouse;
            float _GammaCorrect;
            float _Resolution;

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

            float hash12(float2 p)
            {
                float3 p3 = frac(((float3)p.xyx) * 0.1031);
                p3 += dot(p3, p3.yzx + 33.33);
                return frac((p3.x + p3.y) * p3.z);
            }

            float hash13(float3 p3)
            {
                p3 = frac(p3 * 0.1031);
                p3 += dot(p3, p3.zyx + 31.32);
                return frac((p3.x + p3.y) * p3.z);
            }

            float2 hash22(float2 p)
            {
                float3 p3 = frac(((float3)p.xyx) * float3(0.1031, 0.103, 0.0973));
                p3 += dot(p3, p3.yzx + 33.33);
                return frac((p3.xx + p3.yz) * p3.zy);
            }

            float3 hash32(float2 p)
            {
                float3 p3 = frac(((float3)p.xyx) * float3(0.1031, 0.103, 0.0973));
                p3 += dot(p3, p3.yxz + 33.33);
                return frac((p3.xxy + p3.yzz) * p3.zyx);
            }

            float noise12(float2 p)
            {
                float2 fl = floor(p);
                float2 fr = frac(p);
                fr = fr * fr * (3. - 2. * fr);
                return lerp(lerp(hash12(fl), hash12(fl + float2(1, 0)), fr.x),
                            lerp(hash12(fl + float2(0, 1)), hash12(fl + float2(1, 1)), fr.x), fr.y);
            }

            float noise13(float3 p)
            {
                const float2 u = float2(1, 0);
                float3 q = floor(p);
                float3 r = frac(p);
                return lerp(
                    lerp(lerp(hash13(q + u.yyy), hash13(q + u.xyy), r.x),
                         lerp(hash13(q + u.yxy), hash13(q + u.xxy), r.x), r.y),
                    lerp(lerp(hash13(q + u.yyx), hash13(q + u.xyx), r.x),
                         lerp(hash13(q + u.yxx), hash13(q + u.xxx), r.x), r.y), r.z);
            }

            float noise12(float2 id, float t)
            {
                float2 h = hash22(id);
                t = 3. * h.y * t + h.x;
                float3 q = float3(id, t);
                return noise13(q);
            }

            static const float pi = 3.114159;
            #define STEPS 1000
            #define FAR 50.
            static const float fov = 35.;
            static const int FLOOR = 0;
            static const int TREES = 1;
            static const int LEAVES = 2;
            static const int MUSHROOMS = 3;
            static const int FLIES = 4;
            static float time;

            float3 closestTree(float2 p)
            {
                p.x = p.x > 0. ? max(p.x, 2.5) : min(p.x, -2.5);
                p = 2. * round(0.5 * p);
                float r = 0.1 + 0.3 * hash12(p);
                p += hash22(p) - 0.5;
                return float3(p, r);
            }

            float sdBranches(float3 p)
            {
                p.y += 0.3;
                float d = length(float2(abs(0.1 * dot(sin(4. * p), cos(4. * p.yzx))),
                                        abs(0.1 * dot(sin(4.8 * p), cos(4. * p)))));
                d += 0.05 * (2. - p.y) - 0.012;
                return d;
            }

            float sdTrees(float3 p)
            {
                float3 c = closestTree(p.xz);
                float r = c.z;
                r += 0.01 * (sin(5. * p.y + c.x) + cos(7.8 * p.y + c.y));
                r += 0.02 * p.y * p.y * p.y;
                c.xy += 0.05 * (sin(3. * p.y + c.y) + cos(4.7 * p.y - c.x));
                float t = 0.5 * min(length(p.xz - c.xy) - r + 0.03 * noise12(float2(60, 20) * p.xy), 0.7);
                return t;
                float b = sdBranches(p);
                return min(t, b);
            }

            float sdFlies(float3 p, float j)
            {
                float3 c;
                const float2x2 m = transpose(float2x2(0.8, 0.6, -0.6, 0.8));
                float2 shift = 0.3 * lerp(float2(0.5, -1.8), float2(-0.3, -0.4), j) * time;
                float2 id = floor(mul(m, p.xz - shift));
                c.xz = mul(transpose(float2x2(0.8, -0.6, 0.6, 0.8)), id + 0.5) + shift;
                c.y = 0.5 + hash12(id + 123.4) + 0.2 * noise12(id, time);
                return length(p - c) - 0.01;
            }

            float sdFlies(float3 p)
            {
                return min(sdFlies(0.5 * p, 0.), sdFlies(0.45 * p, 1.));
            }

            float sdFlies(float3 p, float j, out float3 color)
            {
                color = 0;
                float3 c;
                const float2x2 m = transpose(float2x2(0.8, 0.6, -0.6, 0.8));
                float2 shift = 0.3 * lerp(float2(0.5, -1.8), float2(-0.3, -0.4), j) * time;
                float2 id = floor(mul(m, p.xz - shift));
                color = float3(1, 0.5, 0.2) + 0.4 * hash32(id) - 0.2;
                c.xz = mul(transpose(float2x2(0.8, -0.6, 0.6, 0.8)), id + 0.5) + shift;
                c.y = 0.5 + hash12(id + 123.4) + 0.2 * noise12(id, time);
                return length(p - c) - 0.01;
            }

            float sdFlies(float3 p, out float3 color)
            {
                color = 0;
                float3 c1, c2;
                float d1 = sdFlies(0.5 * p, 0., c1);
                float d2 = sdFlies(0.45 * p, 1., c2);
                color = d1 < d2 ? c1 : c2;
                return min(d1, d2);
            }

            float floorHeight(float2 p)
            {
                float3 c = closestTree(p);
                p -= c.xy;
                return 0.3 * exp(-0.1 * dot(p, p) / (c.z * c.z));
            }

            float sdFloor(float3 p)
            {
                return p.y - floorHeight(p.xz);
            }

            float3 closestMushroom(float3 p)
            {
                float3 c = p;
                float shift = c.x > 0. ? 1.5 : -1.5;
                c.x = c.x > 0. ? max(c.x - shift, 0.) : min(c.x - shift, 0.);
                c.xz = 2. * round(0.5 * c.xz);
                c.x += shift;
                c.xz += hash22(c.xz) - 0.5;
                c.y = floorHeight(p.xz);
                return c;
            }

            float sdMushrooms(float3 p)
            {
                p -= closestMushroom(p);
                p.y *= 0.5;
                float head = max(length(p) - 0.2, 0.1 - p.y);
                float r = 0.02 + 0.02 * sin(20. * p.y);
                float foot = max(length(p.xz) - r, p.y - 0.11);
                return min(foot, head);
            }

            float3 closestMushroom(float3 p, out float3 color)
            {
                color = 0;
                float3 c = p;
                float shift = c.x > 0. ? 1.5 : -1.5;
                c.x = c.x > 0. ? max(c.x - shift, 0.) : min(c.x - shift, 0.);
                c.xz = 2. * round(0.5 * c.xz);
                c.x += shift;
                color = float3(0.7, 0.8, 0.9) + float3(0.1, 0.2, 0.1) * (2. * hash32(c.xz) - 1.);
                c.xz += hash22(c.xz) - 0.5;
                c.y = floorHeight(p.xz);
                return c;
            }

            float sdMushrooms(float3 p, out float3 color)
            {
                color = 0;
                p -= closestMushroom(p, color);
                p.y *= 0.5;
                float head = max(length(p) - 0.2, 0.1 - p.y);
                float r = 0.02 + 0.02 * sin(20. * p.y);
                float foot = max(length(p.xz) - r, p.y - 0.11);
                return min(foot, head);
            }

            float sd(float3 p, out int id)
            {
                id = 0;
                float d, minD = 1000000.;
                float2 pos, dir;
                d = sdFloor(p);
                if (d < minD)
                {
                    id = FLOOR;
                    minD = d;
                }

                d = sdTrees(p);
                if (d < minD)
                {
                    id = TREES;
                    minD = d;
                }

                d = sdBranches(p);
                if (d < minD)
                {
                    id = LEAVES;
                    minD = d;
                }

                d = sdMushrooms(p);
                if (d < minD)
                {
                    id = MUSHROOMS;
                    minD = d;
                }

                d = sdFlies(p);
                if (d < minD)
                {
                    id = FLIES;
                    minD = d;
                }

                return minD;
            }

            float march(float3 start, float3 dir, out int id, out float3 glow)
            {
                glow = 0;
                id = 0;
                float total = 0., d;
                float epsilon = 0.2 / iResolution.y;
                int i = 0;
                glow = ((float3)0);
                float3 color;
                for (; i < STEPS; i++)
                {
                    float3 p = start + total * dir;
                    d = sd(p, id);
                    if (d < epsilon * total || total > FAR)
                        break;

                    float dm = sdMushrooms(p, color);
                    glow += color * exp(-10. * dm);
                    dm = sdFlies(p, color);
                    glow += color * exp(-18. * dm);
                    total += d;
                }
                if (total > FAR || i == STEPS)
                    id = -100;

                return total;
            }

            float3 rayColor(float3 start, float3 dir)
            {
                int id;
                float3 glow;
                float d = march(start, dir, id, glow);
                float3 color = 0.1 * glow;
                float3 p = start + d * dir;
                float3 c;
                if (id == MUSHROOMS)
                {
                    closestMushroom(p, c);
                    color += c;
                }
                else if (id == FLIES)
                {
                    sdFlies(p, c);
                    color += c;
                }

                return lerp(float3(0.01, 0.1, 0.3), color, exp(-0.05 * d));
            }

            float3x3 setupCamera(float3 forward, float3 up)
            {
                float3 w = -normalize(forward);
                float3 u = normalize(cross(up, w));
                float3 v = cross(w, u);
                return transpose(float3x3(u, v, w));
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 fragCoord = i.uv * _Resolution;
                time = _Time.y;
                float3 forward = float3(0, 0, -1);
                float3 cam = float3(0, 1, -0.5 * time);
                cam.y += 0.02 * pow(abs(cos(4. * time)), 3.);
                if (_Mouse.z > 0.)
                {
                    float a = pi * (2. * _Mouse.x / iResolution.x - 1.);
                    float b = 0.5 * pi * (-0.2 + 1.2 * _Mouse.y / iResolution.y);
                    forward = float3(sin(a) * cos(b), sin(b), -cos(a) * cos(b));
                }

                float3x3 m = setupCamera(forward, float3(0, 1, 0));
                float3 color = ((float3)0.);
                float2 uv;
                #ifdef AA
                for (float i = -0.25;i<0.5; i += 0.5)
                {
                    for (float j = -0.25;j<0.5; j += 0.5)
                    {
                        uv = 2.*(fragCoord+float2(i, j)-0.5*iResolution.xy)/iResolution.y;
                        float3 pix = float3(tan(0.5*fov*0.01745)*uv, -1.);
                        float3 dir = normalize(mul(m,pix));
                        cam += 0.5*hash12(fragCoord)*dir;
                        color += rayColor(cam, dir);
                    }
                }
                color /= 4.;
                #else
                uv = 2. * (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
                float3 pix = float3(tan(0.5 * fov * 0.01745) * uv, -1.);
                float3 dir = normalize(mul(m, pix));
                cam += 0.5 * hash12(fragCoord) * dir;
                color = rayColor(cam, dir);
                #endif
                color = sqrt(color);
                uv = fragCoord.xy / iResolution.xy;
                uv *= 1. - uv.yx;
                color *= pow(uv.x * uv.y * 15., 0.25);
                float4 fragColor = float4(color, 1.);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}