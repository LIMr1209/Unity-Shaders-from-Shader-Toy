// https://www.shadertoy.com/view/clsXRH
Shader "Unlit/MidnightJam"
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


            #define PI 3.1415927
            #define TWO_PI 6.2831855
            #define NUM_OCTAVES 10
            #define FRC _Time.y*0.7
            #define MLS _Time.y*0.7

            float img2avg(float4 img)
            {
                return dot(img.rgb, ((float3)0.33333));
            }

            float img2avg(float3 img)
            {
                return dot(img.rgb, ((float3)0.33333));
            }

            float2 zr(float2 uv, float2 move, float zoom, float ang)
            {
                uv -= 0.5;
                uv = mul(uv, transpose(float2x2(cos(ang), -sin(ang), sin(ang), cos(ang))));
                uv *= zoom;
                uv -= move * zoom;
                uv -= move * (5. - zoom);
                return uv;
            }

            float random(float x)
            {
                return frac(sin(0.005387 + x) * 129878.44);
            }

            float random(float2 uv)
            {
                return frac(sin(0.387 + dot(uv.xy, float2(12.9, 78.2))) * 4.54);
            }

            float noise(float x)
            {
                float i = floor(x);
                float f = frac(x);
                float y = lerp(random(i), random(i + 1.), smoothstep(0., 1., f));
                return y;
            }

            float2 random2(float2 st)
            {
                st = float2(dot(st, float2(127.1, 311.7)), dot(st, float2(269.5, 183.3)));
                return -1. + 2. * frac(sin(st) * 43758.547);
            }

            float noise(float2 st)
            {
                float2 i = floor(st);
                float2 f = frac(st);
                float2 u;
                u = f * f * f * (f * (f * 6. - 15.) + 10.);
                return lerp(
                    lerp(dot(random2(i + float2(0., 0.)), f - float2(0., 0.)),
                         dot(random2(i + float2(1., 0.)), f - float2(1., 0.)), u.x),
                    lerp(dot(random2(i + float2(0., 1.)), f - float2(0., 1.)),
                         dot(random2(i + float2(1., 1.)), f - float2(1., 1.)), u.x), u.y);
            }

            float3 hsb2rgb(float3 c)
            {
                float4 K = float4(1., 2. / 3., 1. / 3., 3.);
                float3 p = abs(frac(c.xxx + K.xyz) * 6. - K.www);
                return c.z * lerp(K.xxx, clamp(p - K.xxx, 0., 1.), c.y);
            }

            float rect(float2 uv, float x, float y, float w, float h)
            {
                return step(x - w * 0.5, uv.x) * step(uv.x, x + w * 0.5) * step(y - h * 0.5, uv.y) * step(
                    uv.y, y + h * 0.5);
            }

            float circle(float2 uv, float x, float y, float d)
            {
                return step(distance(uv, float2(x, y)), d * 0.5);
            }

            float sphere2(float2 uv, float x, float y, float d)
            {
                float2 dist = uv - float2(x, y);
                return clamp(1. - dot(dist, dist) / (d / 8.), 0., 1.);
            }

            float fbm_noise(in float2 _st)
            {
                float2 i = floor(_st);
                float2 f = frac(_st);
                float a = random(i);
                float b = random(i + float2(1., 0.));
                float c = random(i + float2(0., 1.));
                float d = random(i + float2(1., 1.));
                float2 u = f * f * (3. - 2. * f);
                return lerp(a, b, u.x) + (c - a) * u.y * (1. - u.x) + (d - b) * u.x * u.y;
            }

            float fbm(in float2 _st)
            {
                float v = 0.;
                float a = 0.5;
                float2 shift = ((float2)100.);
                float2x2 rot = transpose(float2x2(cos(0.5), sin(0.5), -sin(0.5), cos(0.5)));
                for (int i = 0; i < NUM_OCTAVES; ++i)
                {
                    v += a * fbm_noise(_st);
                    _st = mul(rot, _st) * 2. + shift;
                    a *= 0.5;
                }
                return v;
            }

            float2 random3(float2 p)
            {
                return frac(sin(float2(dot(p, float2(127.1, 311.7)), dot(p, float2(269.5, 183.3)))) * 43758.547);
            }

            float map(float value, float min1, float max1, float min2, float max2)
            {
                return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
            }

            float2x2 rotate2d(float a)
            {
                return transpose(float2x2(cos(a), -sin(a), sin(a), cos(a)));
            }

            float2x2 scale(float2 s)
            {
                return transpose(float2x2(s.x, 0., 0., s.y));
            }

            float2 uv2wtr(float2 uv, float kx, float ky)
            {
                kx = kx * 2. + 0.01;
                float2 t1 = float2(kx, ky);
                float2 t2 = uv;
                for (int i = 1; i < 10; i++)
                {
                    t2.x += 0.3 / float(i) * sin(float(i) * 3. * t2.y + MLS * kx) + t1.x;
                    t2.y += 0.3 / float(i) * cos(float(i) * 3. * t2.x + MLS * kx) + t1.y;
                }
                float3 tc1;
                tc1.r = cos(t2.x + t2.y + 1.) * 0.5 + 0.5;
                tc1.g = sin(t2.x + t2.y + 1.) * 0.5 + 0.5;
                tc1.b = (sin(t2.x + t2.y) + cos(t2.x + t2.y)) * 0.5 + 0.5;
                uv = uv + (tc1.rb * ((float2)2.) - ((float2)1.)) * ky;
                return uv;
            }

            float nexto(float ch, float n)
            {
                float a;
                a = sin(n * ch);
                a = floor(a * 10000.) * 0.001;
                a = cos(a);
                a = floor(a * 8000.) * 0.001;
                return frac(a);
            }

            float2 uv2wav(float2 uv1, float kx, float ky, float sd)
            {
                float tx = kx;
                float ty = ky;
                float2 t1;
                float time = FRC * 0.;
                t1.y = cos(uv1.x * nexto(1., tx) * 10. + time * ceil(nexto(2., tx) * 10. - 5.)) * nexto(3., tx) * 1.15;
                t1.x = sin(uv1.y * nexto(1., ty) * 10. + time * ceil(nexto(2., ty) * 10. - 5.)) * nexto(3., ty) * 1.15;
                uv1 = uv1 + float2(t1.x, t1.y) * sd;
                t1.y = cos(uv1.x * nexto(4., tx) * 10. + time * ceil(nexto(5., tx) * 10. - 5.)) * nexto(6., tx) * 0.55;
                t1.x = sin(uv1.y * nexto(4., ty) * 10. + time * ceil(nexto(5., ty) * 10. - 5.)) * nexto(6., ty) * 0.55;
                uv1 = uv1 + float2(t1.x, t1.y) * sd;
                t1.y = cos(uv1.x * nexto(7., tx) * 10. + time * ceil(nexto(8., tx) * 10. - 5.)) * nexto(9., tx) * 0.15;
                t1.x = sin(uv1.y * nexto(7., ty) * 10. + time * ceil(nexto(8., ty) * 10. - 5.)) * nexto(9., ty) * 0.15;
                uv1 = uv1 + float2(t1.x, t1.y) * sd;
                return uv1;
            }

            float3 rgb2hsb(float3 c)
            {
                float4 K = float4(0., -1. / 3., 2. / 3., -1.);
                float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
                float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
                float d = q.x - min(q.w, q.y);
                float e = 0.0000000001;
                return float3(abs(q.z + (q.w - q.y) / (6. * d + e)), d / (q.x + e), q.x);
            }

            float3 rgb2ht(float3 img, float t)
            {
                img.rgb = rgb2hsb(img.rgb);
                img.r = img.r + t;
                return hsb2rgb(img.rgb);
            }

            float3 rgb2hr(float3 img, float t)
            {
                img.rgb = rgb2hsb(img.rgb);
                img.r = t;
                return hsb2rgb(img.rgb);
            }

            float3 rgb2st(float3 img, float t)
            {
                img.rgb = rgb2hsb(img.rgb);
                img.g = img.g + t;
                return hsb2rgb(img.rgb);
            }

            float3 rgb2sr(float3 img, float t)
            {
                img.rgb = rgb2hsb(img.rgb);
                img.g = t;
                return hsb2rgb(img.rgb);
            }

            float3 rgb2lt(float3 img, float t)
            {
                img.rgb = rgb2hsb(img.rgb);
                img.b = img.b + t;
                return hsb2rgb(img.rgb);
            }

            float3 rgb2lr(float3 img, float t)
            {
                img.rgb = rgb2hsb(img.rgb);
                img.b = t;
                return hsb2rgb(img.rgb);
            }

            float2 zoom(float2 uv, float2 m, float zmin, float zmax)
            {
                float zoom = map(sin(FRC), -1., 1., zmin, zmax);
                uv -= 0.5;
                uv *= zoom;
                uv -= m * zoom;
                uv -= m * (zmax - zoom);
                return uv;
            }

            float2 roto(float2 uv, float2 m, float ang)
            {
                uv -= 0.5;
                uv = mul(uv, transpose(float2x2(cos(ang), -sin(ang), sin(ang), cos(ang))));
                uv += 0.5;
                return uv;
            }

            float3 mod289(float3 x)
            {
                return x - floor(x * (1. / 289.)) * 289.;
            }

            float2 mod289(float2 x)
            {
                return x - floor(x * (1. / 289.)) * 289.;
            }

            float3 permute(float3 x)
            {
                return mod289((x * 34. + 1.) * x);
            }

            float snoise(float2 v)
            {
                const float4 C = float4(0.21132487, 0.36602542, -0.57735026, 0.024390243);
                float2 i = floor(v + dot(v, C.yy));
                float2 x0 = v - i + dot(i, C.xx);
                float2 i1 = ((float2)0.);
                i1 = x0.x > x0.y ? float2(1., 0.) : float2(0., 1.);
                float2 x1 = x0.xy + C.xx - i1;
                float2 x2 = x0.xy + C.zz;
                i = mod289(i);
                float3 p = permute(permute(i.y + float3(0., i1.y, 1.)) + i.x + float3(0., i1.x, 1.));
                float3 m = max(0.5 - float3(dot(x0, x0), dot(x1, x1), dot(x2, x2)), 0.);
                m = m * m;
                m = m * m;
                float3 x = 2. * frac(p * C.www) - 1.;
                float3 h = abs(x) - 0.5;
                float3 ox = floor(x + 0.5);
                float3 a0 = x - ox;
                m *= 1.7928429 - 0.85373473 * (a0 * a0 + h * h);
                float3 g = ((float3)0.);
                g.x = a0.x * x0.x + h.x * x0.y;
                g.yz = a0.yz * float2(x1.x, x2.x) + h.yz * float2(x1.y, x2.y);
                return 130. * dot(m, g);
            }

            float f2z(float f)
            {
                return f * 2. - 1.;
            }

            float z2f(float z)
            {
                return z * 0.5 + 0.5;
            }

            float f2f(float f)
            {
                return clamp(f, 0., 1.);
            }

            float z2z(float z)
            {
                return clamp(z, -1., 1.);
            }

            float f2rand(float x)
            {
                return frac(sin(0.005387 + x) * 129878.44);
            }

            float f2noise(float x)
            {
                return lerp(f2rand(floor(x)), f2rand(floor(x) + 1.), smoothstep(0., 1., frac(x)));
            }

            float f2slit(float f, float lvl, float len, float smt)
            {
                return smoothstep(lvl - len * 0.5 - smt, lvl - len * 0.5, f) - smoothstep(
                    lvl + len * 0.5, lvl + len * 0.5 + smt, f);
            }

            float f2m(float value, float min1, float max1, float min2, float max2)
            {
                return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
            }

            float sphere(float2 uv, float x, float y, float d, float2 l)
            {
                return (1. - distance(uv, float2(x, y) + l * d) * (1. / d)) * smoothstep(
                    d * 0.51, d * 0.49, distance(uv, float2(x, y)));
            }

            float cube(float2 uv, float x, float y, float s)
            {
                return step(x - s * 0.5, uv.x) * step(uv.x, x + s * 0.5) * step(y - s * 0.5, uv.y) * step(
                    uv.y, y + s * 0.5);
            }

            float sphere3(float2 uv, float x, float y, float d, float2 l)
            {
                return clamp(1. - distance(uv, float2(x, y) + l * d), 0., 1.);
            }

            float2 xy2md(float2 xy)
            {
                return float2(sqrt(pow(xy.x, 2.) + pow(xy.y, 2.)), atan2(xy.y, xy.x));
            }

            float2 md2xy(float2 md)
            {
                return float2(md.x * cos(md.y), md.x * sin(md.y));
            }

            float2 uv2brl(float2 uv, float pwr)
            {
                uv = md2xy(xy2md(uv - 0.5) + float2(pwr - 0.5, 0.)) + 0.5;
                return uv;
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 fragCoord = i.uv * _Resolution;
                float2 uv = fragCoord / iResolution.xy;
                float2 RES = iResolution.xy;
                float2 M = _Mouse.xy / iResolution.xy;
                M.y = 1. - M.y;
                const int n = 10;
                float thr = 0.85;
                float amt = 0.5;
                float2 uv0 = fragCoord.xy / RES.xy;
                uv0.y = 1. - uv0.y;
                uv0.x *= RES.x / RES.y;
                float2 uvc = uv0;
                uv0.x -= (RES.x - RES.y) / RES.y * 0.5;
                float angle = sin(MLS * 0.2);
                float zoom = 20. + 10. * sin(FRC * 0.5);
                float2 move = float2(FRC * 0.2, FRC * 0.7);
                uv0 = zr(uv0 + float2(abs(sin(M.x * PI * 0.5)), abs(sin(M.y * PI * 0.5))), move, zoom, angle);
                float3 layer;
                float3 stack;
                for (int i = n; i > 0; i--)
                {
                    float2 uv = uv0;
                    uv = zr(uv, ((float2)0.), 1. + float(n - i) * 0.3 + sin(FRC * 0.01) * 0.005,
                            PI * 2. * random(float(i) * 0.258));
                    float kx = 0.5 * sin(0.2 * PI * random(float(i) * 1087.4432) + 0.00001 * length(uv));
                    uv.y += sin(uv.x * kx);
                    uv.x += (frac(uv.y) - 0.5) * sin(uv.x * kx - PI * 0.5) * kx;
                    float dir = step(glsl_mod(uv.y, 2.), 1.);
                    float speed = (dir - 0.5) * 10. * (FRC + 2. * noise(FRC * 0.2 + floor(uv.y) + float(i) * 10.) * 2. -
                        1.);
                    float2 uvi = floor(uv);
                    float2 uvf = frac(uv);
                    float2 uvm = uv;
                    uvm.x += speed;
                    float2 mi = floor(uvm);
                    float2 mf = frac(uvm);
                    float car_vis = step(amt, random(mi.x + float(i) * 200.));
                    float CPR = car_vis * (1. - step(amt, random(mi.x - 1. + float(i) * 200.)));
                    float CNX = car_vis * (1. - step(amt, random(mi.x + 1. + float(i) * 200.)));
                    float CPR2 = (1. - car_vis) * step(amt, random(mi.x - 1. + float(i) * 200.));
                    float CNX2 = (1. - car_vis) * step(amt, random(mi.x + 1. + float(i) * 200.));
                    float3 c_lamp = ((float3)1.);
                    float3 c_red = float3(1., 0., 0.);
                    float3 c_yel = float3(1., 1., random(mi.x + float(i) * 300.));
                    float3 car_color = hsb2rgb(float3(random(mi.y) + random(mi.x * 10.1 + 5.5) * 0.3,
                                                      0.4 + 0.6 * random(mi.x + 10.), 1.));
                    float road_vis = step(thr, random(uvi.y + float(i) * 100.)) - 0.01;
                    float kl = 0.25;
                    float ka = 0.5;
                    float3 lamp = lerp(((float3)0.), c_lamp, pow(abs(snoise(uv / 6.5)), 5.) + 0.07) +
                        lerp(((float3)0.), c_red * ka, pow(abs(snoise((uvm + 137.) / 5.5)), 5.)) +
                        lerp(((float3)0.), c_yel * ka, pow(abs(snoise((uvm + 872.) / 5.5)), 5.)) + lerp(
                            ((float3)0.), lerp(c_yel, c_red, dir) * (0.6 + 0.4 * random(mi.x + float(i) * 13.4)),
                            CNX * sphere2(mf, 0.8, 0.7, 0.1) + CNX * sphere2(mf, 0.8, 0.3, 0.1)) + lerp(
                            ((float3)0.), lerp(c_red, c_yel, dir) * (0.6 + 0.4 * random(mi.x + float(i) * 73.7)),
                            CPR * sphere2(mf, 0.2, 0.7, 0.1) + CPR * sphere2(mf, 0.2, 0.3, 0.1));
                    +lerp(((float3)0.),
                          lerp(c_red * kl, car_color * kl, dir) * (0.6 + 0.4 * random(mi.x + float(i) * 73.7)),
                          +CNX2 * sphere2(mf - float2(0.5, 0.), 0.5, 0.5, 3.)) + lerp(
                        ((float3)0.),
                        lerp(car_color * kl, c_red * kl, dir) * (0.6 + 0.4 * random(mi.x + float(i) * 13.4)),
                        +CPR2 * sphere2(mf + float2(0.5, 0.), 0.5, 0.5, 3.)) + lerp(
                        ((float3)0.),
                        lerp(car_color * kl, c_red * kl, dir) * (0.6 + 0.4 * random(mi.x + float(i) * 73.7)),
                        +CNX * sphere2(mf - float2(0.5, 0.), 0.5, 0.5, 3.)) + lerp(
                        ((float3)0.),
                        lerp(c_red * kl, car_color * kl, dir) * (0.6 + 0.4 * random(mi.x + float(i) * 13.4)),
                        +CPR * sphere2(mf + float2(0.5, 0.), 0.5, 0.5, 3.));
                    lamp = clamp(lamp, ((float3)0.), ((float3)1.));
                    layer = ((float3)road_vis * float(i) / float(n) * lamp * (0.3 * rect(uvf, 0.5, 0.5, 1., 0.9) + 1. *
                        rect(uvf, 0.5, 0.5, 0.4, 0.1))) + lamp * 0.25;
                    layer *= 0.75 + 0.6 * pow(abs(snoise(uv * 8. + 131.)), 3.);
                    float fig = 0;
                    fig += random(mi.x + 0.01) * circle(mf, random(mi.x + 0.11), 0.5, 0.3 + 0.4 * random(mi + 0.21));
                    fig += random(mi.x + 0.02) * rect(mf, random(mi.x + 0.12), 0.5, 0.1 + 0.9 * random(mi + 0.22),
                                                      0.1 + 0.9 * random(mi + 0.32));
                    fig += random(mi.x + 0.05) * circle(mf, random(mi.x + 0.15), 0.5, 0.3 + 0.3 * random(mi + 0.25));
                    fig += random(mi.x + 0.06) * rect(mf, random(mi.x + 0.16), 0.5, 0.1 + 0.9 * random(mi + 0.26),
                                                      0.1 + 0.9 * random(mi + 0.36));
                    fig += random(mi.x + 0.07) * rect(mf, random(mi.x + 0.17), 0.5, 0.1 + 0.9 * random(mi + 0.27),
                                                      0.1 + 0.9 * random(mi + 0.37));
                    fig *= 0.75 + pow(abs(snoise(uvm + 725.)), 2.5);
                    layer = lerp(layer, car_color * fig * lamp, car_vis * step(0.05, fig));
                    stack = lerp(stack, layer, road_vis + 0.01);
                    if (length(stack) > 0.)
                        break;
                }
                float3 color = hsb2rgb(float3(noise(uv0 * 0.002) * PI, 0.3, 1.));
                float cloud = pow(fbm(float2(fbm(uv0 * 0.1), fbm(uv0 * 0.1 + ((float2)10.) + float2(FRC * 0.4, 0.)))),
                                  7.) * 10. * map(zoom, 10., 30., 0.3, 1.);
                cloud = clamp(cloud, 0., 0.8);
                stack = lerp(stack, color, cloud);
                float4 img = float4(stack, 1.);
                float4 fragColor = img;
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}