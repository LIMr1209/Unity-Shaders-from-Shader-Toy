﻿// https://www.shadertoy.com/view/4sXBRn
Shader "Unlit/Luminescence"
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

            #define INVERTMOUSE -1.
            #define MAX_STEPS 100.
            #define VOLUME_STEPS 8.
            #define MIN_DISTANCE 0.1
            #define MAX_DISTANCE 100.
            #define HIT_DISTANCE 0.01
            #define S(x, y, z) smoothstep(x, y, z)
            #define B(x, y, z, w) S(x-z, x+z, w)*S(y+z, y-z, w)
            #define sat(x) clamp(x, 0., 1.)
            #define SIN(x) sin(x)*0.5+0.5
            static const float3 lf = float3(1., 0., 0.);
            static const float3 up = float3(0., 1., 0.);
            static const float3 fw = float3(0., 0., 1.);
            static const float halfpi = 1.5707964;
            static const float pi = 3.1415927;
            static const float twopi = 6.2831855;
            static float3 accentColor1 = float3(1., 0.1, 0.5);
            static float3 secondColor1 = float3(0.1, 0.5, 1.);
            static float3 accentColor2 = float3(1., 0.5, 0.1);
            static float3 secondColor2 = float3(0.1, 0.5, 0.6);
            static float3 bg;
            static float3 accent;
            float N1(float x)
            {
                return frac(sin(x)*5346.1763);
            }

            float N2(float x, float y)
            {
                return N1(x+y*23414.324);
            }

            float N3(float3 p)
            {
                p = frac(p*0.3183099+0.1);
                p *= 17.;
                return frac(p.x*p.y*p.z*(p.x+p.y+p.z));
            }

            struct ray 
            {
                float3 o;
                float3 d;
            };
            struct camera 
            {
                float3 p;
                float3 forward;
                float3 left;
                float3 up;
                float3 center;
                float3 i;
                ray ray;
                float3 lookAt;
                float zoom;
            };
            struct de 
            {
                float d;
                float m;
                float3 uv;
                float pump;
                float3 id;
                float3 pos;
            };
            struct rc 
            {
                float3 id;
                float3 h;
                float3 p;
            };
            rc Repeat(float3 pos, float3 size)
            {
                rc o;
                o.h = size*0.5;
                o.id = floor(pos/size);
                o.p = glsl_mod(pos, size)-o.h;
                return o;
            }

            static camera cam;
            void CameraSetup(float2 uv, float3 position, float3 lookAt, float zoom)
            {
                cam.p = position;
                cam.lookAt = lookAt;
                cam.forward = normalize(cam.lookAt-cam.p);
                cam.left = cross(up, cam.forward);
                cam.up = cross(cam.forward, cam.left);
                cam.zoom = zoom;
                cam.center = cam.p+cam.forward*cam.zoom;
                cam.i = cam.center+cam.left*uv.x+cam.up*uv.y;
                cam.ray.o = cam.p;
                cam.ray.d = normalize(cam.i-cam.p);
            }

            float3 N31(float p)
            {
                float3 p3 = frac(((float3)p)*float3(0.1031, 0.11369, 0.13787));
                p3 += dot(p3, p3.yzx+19.19);
                return frac(float3((p3.x+p3.y)*p3.z, (p3.x+p3.z)*p3.y, (p3.y+p3.z)*p3.x));
            }

            float smin(float a, float b, float k)
            {
                float h = clamp(0.5+0.5*(b-a)/k, 0., 1.);
                return lerp(b, a, h)-k*h*(1.-h);
            }

            float smax(float a, float b, float k)
            {
                float h = clamp(0.5+0.5*(b-a)/k, 0., 1.);
                return lerp(a, b, h)+k*h*(1.-h);
            }

            float sdSphere(float3 p, float3 pos, float s)
            {
                return length(p-pos)-s;
            }

            float2 pModPolar(inout float2 p, float repetitions, float fix)
            {
                float angle = twopi/repetitions;
                float a = atan2(p.y, p.x)+angle/2.;
                float r = length(p);
                float c = floor(a/angle);
                a = glsl_mod(a, angle)-angle/2.*fix;
                p = float2(cos(a), sin(a))*r;
                return p;
            }

            float Dist(float2 P, float2 P0, float2 P1)
            {
                float2 v = P1-P0;
                float2 w = P-P0;
                float c1 = dot(w, v);
                float c2 = dot(v, v);
                if (c1<=0.)
                    return length(P-P0);
                    
                float b = c1/c2;
                float2 Pb = P0+b*v;
                return length(P-Pb);
            }

            float3 ClosestPoint(float3 ro, float3 rd, float3 p)
            {
                return ro+max(0., dot(p-ro, rd))*rd;
            }

            float2 RayRayTs(float3 ro1, float3 rd1, float3 ro2, float3 rd2)
            {
                float3 dO = ro2-ro1;
                float3 cD = cross(rd1, rd2);
                float v = dot(cD, cD);
                float t1 = dot(cross(dO, rd2), cD)/v;
                float t2 = dot(cross(dO, rd1), cD)/v;
                return float2(t1, t2);
            }

            float DistRaySegment(float3 ro, float3 rd, float3 p1, float3 p2)
            {
                float3 rd2 = p2-p1;
                float2 t = RayRayTs(ro, rd, p1, rd2);
                t.x = max(t.x, 0.);
                t.y = clamp(t.y, 0., length(rd2));
                float3 rp = ro+rd*t.x;
                float3 sp = p1+rd2*t.y;
                return length(rp-sp);
            }

            float2 sph(float3 ro, float3 rd, float3 pos, float radius)
            {
                float3 oc = pos-ro;
                float l = dot(rd, oc);
                float det = l*l-dot(oc, oc)+radius*radius;
                if (det<0.)
                    return ((float2)MAX_DISTANCE);
                    
                float d = sqrt(det);
                float a = l-d;
                float b = l+d;
                return float2(a, b);
            }

            float3 background(float3 r)
            {
                float x = atan2(r.x, r.z);
                float y = pi*0.5-acos(r.y);
                float3 col = bg*(1.+y);
                float t = _Time.y;
                float a = sin(r.x);
                float beam = sat(sin(10.*x+a*y*5.+t));
                beam *= sat(sin(7.*x+a*y*3.5-t));
                float beam2 = sat(sin(42.*x+a*y*21.-t));
                beam2 *= sat(sin(34.*x+a*y*17.+t));
                beam += beam2;
                col *= 1.+beam*0.05;
                return col;
            }

            float remap(float a, float b, float c, float d, float t)
            {
                return (t-a)/(b-a)*(d-c)+c;
            }

            de map(float3 p, float3 id)
            {
                float t = _Time.y*2.;
                float N = N3(id);
                de o;
                o.m = 0.;
                float x = (p.y+N*twopi)*1.+t;
                float r = 1.;
                float pump = cos(x+cos(x))+sin(2.*x)*0.2+sin(4.*x)*0.02;
                x = t+N*twopi;
                p.y -= (cos(x+cos(x))+sin(2.*x)*0.2)*0.6;
                p.xz *= 1.+pump*0.2;
                float d1 = sdSphere(p, float3(0., 0., 0.), r);
                float d2 = sdSphere(p, float3(0., -0.5, 0.), r);
                o.d = smax(d1, -d2, 0.1);
                o.m = 1.;
                if (p.y<0.5)
                {
                    float sway = sin(t+p.y+N*twopi)*S(0.5, -3., p.y)*N*0.3;
                    p.x += sway*N;
                    p.z += sway*(1.-N);
                    float3 mp = p;
                    mp.xz = pModPolar(mp.xz, 6., 0.);
                    float d3 = length(mp.xz-float2(0.2, 0.1))-remap(0.5, -3.5, 0.1, 0.01, mp.y);
                    if (d3<o.d)
                        o.m = 2.;
                        
                    d3 += (sin(mp.y*10.)+sin(mp.y*23.))*0.03;
                    float d32 = length(mp.xz-float2(0.2, 0.1))-remap(0.5, -3.5, 0.1, 0.04, mp.y)*0.5;
                    d3 = min(d3, d32);
                    o.d = smin(o.d, d3, 0.5);
                    if (p.y<0.2)
                    {
                        float3 op = p;
                        op.xz = pModPolar(op.xz, 13., 1.);
                        float d4 = length(op.xz-float2(0.85, 0.))-remap(0.5, -3., 0.04, 0., op.y);
                        if (d4<o.d)
                            o.m = 3.;
                            
                        o.d = smin(o.d, d4, 0.15);
                    }
                    
                }
                
                o.pump = pump;
                o.uv = p;
                o.d *= 0.8;
                return o;
            }

            float3 calcNormal(de o)
            {
                float3 eps = float3(0.01, 0., 0.);
                float3 nor = float3(map(o.pos+eps.xyy, o.id).d-map(o.pos-eps.xyy, o.id).d, map(o.pos+eps.yxy, o.id).d-map(o.pos-eps.yxy, o.id).d, map(o.pos+eps.yyx, o.id).d-map(o.pos-eps.yyx, o.id).d);
                return normalize(nor);
            }

            de CastRay(ray r)
            {
                float d = 0.;
                float dS = MAX_DISTANCE;
                float3 pos = float3(0., 0., 0.);
                float3 n = ((float3)0.);
                de o, s;
                float dC = MAX_DISTANCE;
                float3 p;
                rc q;
                float t = _Time.y;
                float3 grid = float3(6., 30., 6.);
                for (float i = 0.;i<MAX_STEPS; i++)
                {
                    p = r.o+r.d*d;
#ifdef SINGLE
                    s = map(p, ((float3)0.));
#else
                    p.y -= t;
                    p.x += t;
                    q = Repeat(p, grid);
                    float3 rC = ((2.*step(0., r.d)-1.)*q.h-q.p)/r.d;
                    dC = min(min(rC.x, rC.y), rC.z)+0.01;
                    float N = N3(q.id);
                    q.p += (N31(N)-0.5)*grid*float3(0.5, 0.7, 0.5);
                    if (Dist(q.p.xz, r.d.xz, ((float2)0.))<1.1)
                    s = map(q.p, q.id);
                    else s.d = dC;
#endif
                    if (s.d<HIT_DISTANCE||d>MAX_DISTANCE)
                        break;
                        
                    d += min(s.d, dC);
                }
                if (s.d<HIT_DISTANCE)
                {
                    o.m = s.m;
                    o.d = d;
                    o.id = q.id;
                    o.uv = s.uv;
                    o.pump = s.pump;
#ifdef SINGLE
                    o.pos = p;
#else
                    o.pos = q.p;
#endif
                }
                
                return o;
            }

            float VolTex(float3 uv, float3 p, float scale, float pump)
            {
                p.y *= scale;
                float s2 = 5.*p.x/twopi;
                float id = floor(s2);
                s2 = frac(s2);
                float2 ep = float2(s2-0.5, p.y-0.6);
                float ed = length(ep);
                float e = B(0.35, 0.45, 0.05, ed);
                float s = SIN(s2*twopi*15.);
                s = s*s;
                s = s*s;
                s *= S(1.4, -0.3, uv.y-cos(s2*twopi)*0.2+0.3)*S(-0.6, -0.3, uv.y);
                float t = _Time.y*5.;
                float mask = SIN(p.x*twopi*2.+t);
                s *= mask*mask*2.;
                return s+e*pump*2.;
            }

            float4 JellyTex(float3 p)
            {
                float3 s = float3(atan2(p.x, p.z), length(p.xz), p.y);
                float b = 0.75+sin(s.x*6.)*0.25;
                b = lerp(1., b, s.y*s.y);
                p.x += sin(s.z*10.)*0.1;
                float b2 = cos(s.x*26.)-s.z-0.7;
                b2 = S(0.1, 0.6, b2);
                return ((float4)b+b2);
            }

            float3 render(float2 uv, ray camRay, float depth)
            {
                bg = background(cam.ray.d);
                float3 col = bg;
                de o = CastRay(camRay);
                float t = _Time.y;
                float3 L = up;
                if (o.m>0.)
                {
                    float3 n = calcNormal(o);
                    float lambert = sat(dot(n, L));
                    float3 R = reflect(camRay.d, n);
                    float fresnel = sat(1.+dot(camRay.d, n));
                    float trans = (1.-fresnel)*0.5;
                    float3 ref = background(R);
                    float fade = 0.;
                    if (o.m==1.)
                    {
                        float density = 0.;
                        for (float i = 0.;i<VOLUME_STEPS; i++)
                        {
                            float sd = sph(o.uv, camRay.d, ((float3)0.), 0.8+i*0.015).x;
                            if (sd!=MAX_DISTANCE)
                            {
                                float2 intersect = o.uv.xz+camRay.d.xz*sd;
                                float3 uv = float3(atan2(intersect.x, intersect.y), length(intersect.xy), o.uv.z);
                                density += VolTex(o.uv, uv, 1.4+i*0.03, o.pump);
                            }
                            
                        }
                        float4 volTex = float4(accent, density/VOLUME_STEPS);
                        float3 dif = JellyTex(o.uv).rgb;
                        dif *= max(0.2, lambert);
                        col = lerp(col, volTex.rgb, volTex.a);
                        col = lerp(col, ((float3)dif), 0.25);
                        col += fresnel*ref*sat(dot(up, n));
                        fade = max(fade, S(0., 1., fresnel));
                    }
                    else if (o.m==2.)
                    {
                        float3 dif = accent;
                        col = lerp(bg, dif, fresnel);
                        col *= lerp(0.6, 1., S(0., -1.5, o.uv.y));
                        float prop = o.pump+0.25;
                        prop *= prop*prop;
                        col += pow(1.-fresnel, 20.)*dif*prop;
                        fade = fresnel;
                    }
                    else if (o.m==3.)
                    {
                        float3 dif = accent;
                        float d = S(100., 13., o.d);
                        col = lerp(bg, dif, pow(1.-fresnel, 5.)*d);
                    }
                    
                    fade = max(fade, S(0., 100., o.d));
                    col = lerp(col, bg, fade);
                    if (o.m==4.)
                        col = float3(1., 0., 0.);
                        
                }
                else col = bg;
                return col;
            }

            float4 frag (v2f i) : SV_Target
            {
                float2 fragCoord = i.uv * _Resolution;
                float t = _Time.y*0.04;
                float2 uv = fragCoord.xy/iResolution.xy;
                uv -= 0.5;
                uv.y *= iResolution.y/iResolution.x;
                float2 m = _Mouse.xy/iResolution.xy;
                if (m.x<0.05||m.x>0.95)
                {
                    m = float2(t*0.25, SIN(t*pi)*0.5+0.5);
                }
                
                accent = lerp(accentColor1, accentColor2, SIN(t*15.456));
                bg = lerp(secondColor1, secondColor2, SIN(t*7.345231));
                float turn = (0.1-m.x)*twopi;
                float s = sin(turn);
                float c = cos(turn);
                float3x3 rotX = transpose(float3x3(c, 0., s, 0., 1., 0., s, 0., -c));
#ifdef SINGLE
                float camDist = -10.;
#else
                float camDist = -0.1;
#endif
                float3 lookAt = float3(0., -1., 0.);
                float3 camPos = mul(float3(0., INVERTMOUSE*camDist*cos(m.y*pi), camDist),rotX);
                CameraSetup(uv, camPos+lookAt, lookAt, 1.);
                float3 col = render(uv, cam.ray, 0.);
                col = pow(col, ((float3)lerp(1.5, 2.6, SIN(t+pi))));
                float d = 1.-dot(uv, uv);
                col *= d*d*d+0.1;
                float4 fragColor = float4(col, 1.);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}