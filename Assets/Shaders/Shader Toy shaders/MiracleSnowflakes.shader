// https://www.shadertoy.com/view/Xsd3zf
Shader "Unlit/MiracleSnowflakes"
{
    Properties
    {
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

            #define iterations 15.
            #define depth 0.0125
            #define layers 8.
            #define layersblob 20
            #define step 1.
            #define far 10000.
            static float radius = 0.25;
            static float zoom = 4.;
            static float3 light = float3(0., 0., 1.);
            static float2 seed = float2(0., 0.);
            static float iteratorc = iterations;
            static float powr;
            static float res;
            static float4 NC0 = float4(0., 157., 113., 270.);
            static float4 NC1 = float4(1., 158., 114., 271.);

            float4 hash4(float4 n) { return frac(sin(n) * 1399763.5453123); }

            float noise2(float2 x)
            {
                float2 p = floor(x);
                float2 f = frac(x);
                f = f * f * (3.0 - 2.0 * f);
                float n = p.x + p.y * 157.0;
                float4 h = hash4((float4)n + float4(NC0.xy, NC1.xy));
                float2 s1 = lerp(h.xy, h.zw, f.xx);
                return lerp(s1.x, s1.y, f.y);
            }

            float noise222(float2 x, float2 y, float2 z)
            {
                float4 lx = float4(x * y.x, x * y.y);
                float4 p = floor(lx);
                float4 f = frac(lx);
                f = f * f * (3.0 - 2.0 * f);
                float2 n = p.xz + p.yw * 157.0;
                float4 h = lerp(hash4(n.xxyy + NC0.xyxy), hash4(n.xxyy + NC1.xyxy), f.xxzz);
                return dot(lerp(h.xz, h.yw, f.yw), z);
            }

            float noise3(float3 x)
            {
                float3 p = floor(x);
                float3 f = frac(x);
                f = f * f * (3.0 - 2.0 * f);

                float n = p.x + dot(p.yz, float2(157.0, 113.0));
                float4 s1 = lerp(hash4((float4)n + NC0), hash4((float4)n + NC1), f.xxxx);
                return lerp(lerp(s1.x, s1.y, f.y), lerp(s1.z, s1.w, f.y), f.z);
            }

            float2 noise3_2(float3 x) { return float2(noise3(x), noise3(x + 100.0)); }

            float map(float2 rad)
            {
                float a;
                if (res < 0.0015)
                {
                    //a = noise2(rad.xy*20.6)*0.9+noise2(rad.xy*100.6)*0.1;
                    a = noise222(rad.xy, float2(20.6, 100.6), float2(0.9, 0.1));
                }
                else if (res < 0.005)
                {
                    //float a1 = lerp(noise2(rad.xy*10.6),1.0,l);
                    //a = texture(iChannel0,rad*0.3).x;
                    a = noise2(rad.xy * 20.6);
                    //if (a1<a) a=a1;
                }
                else a = noise2(rad.xy * 10.3);
                return (a - 0.5);
            }

            float3 distObj(float3 pos, float3 ray, float r, float2 seed)
            {
                float rq = r * r;
                float3 dist = ray * far;

                float3 norm = float3(0.0, 0.0, 1.0);

                float invn = 1.0 / dot(norm, ray);

                float depthi = depth;
                if (invn < 0.0) depthi = - depthi;

                float ds = 2.0 * depthi * invn;
                float3 r1 = ray * (dot(norm, pos) - depthi) * invn - pos;
                float3 op1 = r1 + norm * depthi;

                float len1 = dot(op1, op1);
                float3 r2 = r1 + ray * ds;
                float3 op2 = r2 - norm * depthi;

                float len2 = dot(op2, op2);

                float3 n = normalize(cross(ray, norm));

                float mind = dot(pos, n);
                float3 n2 = cross(ray, n);

                float d = dot(n2, pos) / dot(n2, norm);

                float invd = 0.2 / depth;

                if ((len1 < rq || len2 < rq) || (abs(mind) < r && d <= depth && d >= -depth))
                {
                    float3 r3 = r2;

                    float len = len1;
                    if (len >= rq)
                    {
                        float3 n3 = cross(norm, n);

                        float a = rsqrt(rq - mind * mind) * abs(dot(ray, n3));
                        float3 dt = ray / a;
                        r1 = - d * norm - mind * n - dt;
                        if (len2 >= rq)
                        {
                            r2 = - d * norm - mind * n + dt;
                        }
                        ds = dot(r2 - r1, ray);
                    }
                    ds = (abs(ds) + 0.1) / (iterations);
                    ds = lerp(depth, ds, 0.2);
                    if (ds > 0.01) ds = 0.01;

                    float ir = 0.35 / r;
                    r *= zoom;
                    ray = ray * ds * 5.0;
                    for (float m = 0.0; m < iterations; m += 1.0)
                    {
                        if (m >= iteratorc) break;

                        float l = length(r1.xy); //inversesqrt(dot(r1.xy,r1.xy));
                        float2 c3 = abs(r1.xy / l);
                        if (c3.x > 0.5) c3 = abs(c3 * 0.5 + float2(-c3.y, c3.x) * 0.86602540);

                        float g = l + c3.x * c3.x; //*1.047197551;
                        l *= zoom;

                        float h = l - r - 0.1;
                        l = pow(l, powr) + 0.1;
                        h = max(h, lerp(map(c3 * l + seed), 1.0, abs(r1.z * invd))) + g * ir - 0.245;
                        //0.7*0.35=0.245 //*0.911890636
                        if ((h < res * 20.0) || abs(r1.z) > depth + 0.01) break;
                        r1 += ray * h;
                        ray *= 0.99;
                    }
                    if (abs(r1.z) < depth + 0.01) dist = r1 + pos;
                }
                return dist;
            }

            static float3 nray;
            static float3 nray1;
            static float3 nray2;
            static float mxc = 1.;

            float4 filterFlake(float4 color, float3 pos, float3 ray, float3 ray1, float3 ray2)
            {
                float3 d = distObj(pos, ray, radius, seed);
                float3 n1 = distObj(pos, ray1, radius, seed);
                float3 n2 = distObj(pos, ray2, radius, seed);

                float3 lq = float3(dot(d, d), dot(n1, n1), dot(n2, n2));
                if (lq.x < far || lq.y < far || lq.z < far)
                {
                    float3 n = normalize(cross(n1 - d, n2 - d));
                    if (lq.x < far && lq.y < far && lq.z < far)
                    {
                        nray = n; //normalize(nray+n);
                        //nray1 = normalize(ray1+n);
                        //nray2 = normalize(ray2+n);
                    }
                    float da = pow(abs(dot(n, light)), 3.0);
                    float3 cf = lerp(float3(0.0, 0.4, 1.0), color.xyz * 10.0, abs(dot(n, ray)));
                    cf = lerp(cf, (float3)2.0, da);
                    color.xyz = lerp(color.xyz, cf, mxc * mxc * (0.5 + abs(dot(n, ray)) * 0.5));
                }

                return color;
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 fragCoord;
                float2 p;
                if(_ScreenEffect)
                {
                    fragCoord = i.uv * _ScreenParams;
                    res = 1. / _ScreenParams.y;
                    p = (-_ScreenParams.xy + 2. * fragCoord.xy) * res;
                }else
                {
                    fragCoord = i.uv * iResolution;
                    res = 1. / iResolution.y;
                    p = (-iResolution.xy + 2. * fragCoord.xy) * res;
                }
                float time = _Time.y * 0.2;
                float3 rotate;
                float3x3 mr;
                float3 ray = normalize(float3(p, 2.));
                float3 ray1;
                float3 ray2;
                float3 pos = float3(0., 0., 1.);
                float4 fragColor = float4(0., 0., 0., 0.);
                nray = ((float3)0.);
                nray1 = ((float3)0.);
                nray2 = ((float3)0.);
                float4 refcolor = ((float4)0.);
                iteratorc = iterations - layers;
                float2 addrot = ((float2)0.);
                float mxcl = 1.;
                float3 addpos = ((float3)0.);
                pos.z = 1.;
                mxc = 1.;
                radius = 0.25;
                float mzd = (zoom - 0.1) / layers;
                for (int i = 0; i < layersblob; i++)
                {
                    float2 p2 = p - ((float2)0.25) + ((float2)0.1 * float(i));
                    ray = float3(p2, 2.) - nray * 2.;
                    ray1 = normalize(ray + float3(0., res * 2., 0.));
                    ray2 = normalize(ray + float3(res * 2., 0., 0.));
                    ray = normalize(ray);
                    float2 sb = ray.xy * length(pos) / dot(normalize(pos), ray) + float2(0., time);
                    seed = floor(sb + float2(0., pos.z)) + pos.z;
                    float3 seedn = float3(seed, pos.z);
                    sb = floor(sb);
                    if (noise3(seedn) > 0.2 && i < int(layers))
                    {
                        powr = noise3(seedn * 10.) * 1.9 + 0.1;
                        rotate.xy = sin((0.5 - noise3_2(seedn)) * time * 5.) * 0.3 + addrot;
                        rotate.z = (0.5 - noise3(seedn + float3(10., 3., 1.))) * time * 5.;
                        seedn.z += time * 0.5;
                        addpos.xy = sb + float2(0.25, 0.25 - time) + noise3_2(seedn) * 0.5;
                        float3 sins = sin(rotate);
                        float3 coss = cos(rotate);
                        mr = transpose(float3x3(float3(coss.x, 0., sins.x), float3(0., 1., 0.),
                                                float3(-sins.x, 0., coss.x)));
                        mr = mul(transpose(float3x3(float3(1., 0., 0.), float3(0., coss.y, sins.y),
                                                    float3(0., -sins.y, coss.y))), mr);
                        mr = mul(transpose(float3x3(float3(coss.z, sins.z, 0.), float3(-sins.z, coss.z, 0.),
                                                    float3(0., 0., 1.))), mr);


                        light = mul(normalize(float3(1., 0., 1.)), mr);
                        float4 cc = filterFlake(fragColor, mul(pos + addpos, mr), mul(ray, mr), mul(ray1, mr),
                                                mul(ray2, mr));
                        fragColor = lerp(cc, fragColor, min(1., fragColor.w));
                    }

                    seedn = float3(sb, pos.z) + float3(0.5, 1000., 300.);
                    if (noise3(seedn * 10.) > 0.4)
                    {
                        float raf = 0.3 + noise3(seedn * 100.);
                        addpos.xy = sb + float2(0.2, 0.2 - time) + noise3_2(seedn * 100.) * 0.6;
                        float l = length(ray * dot(ray, pos + addpos) - pos - addpos);
                        l = max(0., 1. - l * 10. * raf);
                        fragColor.xyzw += float4(1., 1.2, 3., 1.) * pow(l, 5.) * (pow(0.6 + raf, 2.) - 0.6) * mxcl;
                    }

                    mxc -= 1.1 / layers;
                    pos.z += step;
                    iteratorc += 2.;
                    mxcl -= 1.1 / float(layersblob);
                    zoom -= mzd;
                }
                float3 cr = lerp(((float3)0.), float3(0., 0., 0.4), (-0.55 + p.y) * 2.);
                fragColor.xyz += lerp((cr.xyz - fragColor.xyz) * 0.1, float3(0.2, 0.5, 1.),
                                      clamp((-p.y + 1.) * 0.5, 0., 1.));
                fragColor = min(((float4)1.), fragColor);
                fragColor.a = 1.;
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}