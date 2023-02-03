// https://www.shadertoy.com/view/NslGRN
Shader "Unlit/CubeLines"
{
    Properties
    {
        _MainTex ("iChannel0", 2D) = "white" {}
        [Header(General)]
        [ToggleUI] _GammaCorrect ("Gamma Correction", Float) = 1
        _Resolution ("Resolution (Change if AA is bad)", Range(1, 1024)) = 1
        _Mouse ("Mouse", Vector) = (0.5, 0.5, 0.5, 0.5)
        
        [Header(Extracted)]
        ROTATION_SPEED ("ROTATION_SPEED", Float) = 0.8999
        tshift ("tshift", Float) = 53
        ANGLE_loops ("ANGLE_loops", Float) = 0
        FDIST ("FDIST", Float) = 0.7
        PI ("PI", Float) = 3.1415925
        GROUNDSPACING ("GROUNDSPACING", Float) = 0.5
        GROUNDGRID ("GROUNDGRID", Float) = 0.05
        BOXDIMS ("BOXDIMS", Vector) = (0.75,0.75,1.25)
        IOR ("IOR", Float) = 1.33
        color_blue ("color_blue", Vector) = (0.5,0.65,0.8)
        color_red ("color_red", Vector) = (0.99,0.2,0.1)

    }
    SubShader
    {
        Pass
        {
            Cull Off

            CGPROGRAM
// Upgrade NOTE: excluded shader from DX11 because it uses wrong array syntax (type[size] name)
#pragma exclude_renderers d3d11
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
            sampler2D _MainTex;   float4 _MainTex_TexelSize;
            float4 _Mouse;
            float _GammaCorrect;
            float _Resolution;

            // GLSL Compatability macros
            #define glsl_mod(x,y) (((x)-(y)*floor((x)/(y))))
            #define texelFetch(ch, uv, lod) tex2Dlod(ch, float4((uv).xy * ch##_TexelSize.xy + ch##_TexelSize.xy * 0.5, 0, lod))
            #define textureLod(ch, uv, lod) tex2Dlod(ch, float4(uv, 0, lod))
            #define iResolution float3(_Resolution, _Resolution, _Resolution)

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }


            float ROTATION_SPEED;
            const float3 color_blue;
            const float3 color_red;
float tshift;
#define MOUSE_control 
float ANGLE_loops;
float FDIST;
float PI;
float GROUNDSPACING;
float GROUNDGRID;
float3 BOXDIMS;
float IOR;
            float3x3 rotx(float a)
            {
                float s = sin(a);
                float c = cos(a);
                return transpose(float3x3(float3(1., 0., 0.), float3(0., c, s), float3(0., -s, c)));
            }

            float3x3 roty(float a)
            {
                float s = sin(a);
                float c = cos(a);
                return transpose(float3x3(float3(c, 0., s), float3(0., 1., 0.), float3(-s, 0., c)));
            }

            float3x3 rotz(float a)
            {
                float s = sin(a);
                float c = cos(a);
                return transpose(float3x3(float3(c, s, 0.), float3(-s, c, 0.), float3(0., 0., 1.)));
            }

            float3 fcos(float3 x)
            {
                float3 w = fwidth(x);
                float lw = length(w);
                if (lw==0.||isnan(lw)||isinf(lw))
                {
                    float3 tc = ((float3)0.);
                    for (int i = 0;i<8; i++)
                    tc += cos(x+x*float(i-4)*(0.01*400./iResolution.y));
                    return tc/8.;
                }
                
                return cos(x)*smoothstep(3.14*2., 0., w);
            }

            float3 fcos2(float3 x)
            {
                return cos(x);
            }

            float3 getColor(float3 p)
            {
                p = abs(p);
                p *= 1.25;
                p = 0.5*p/dot(p, p);
#ifdef ANIM_COLOR
                p += 0.072*_Time.y;
#endif
                float t = 0.13*length(p);
                float3 col = float3(0.3, 0.4, 0.5);
                col += 0.12*fcos(6.28318*t*1.+float3(0., 0.8, 1.1));
                col += 0.11*fcos(6.28318*t*3.1+float3(0.3, 0.4, 0.1));
                col += 0.1*fcos(6.28318*t*5.1+float3(0.1, 0.7, 1.1));
                col += 0.1*fcos(6.28318*t*17.1+float3(0.2, 0.6, 0.7));
                col += 0.1*fcos(6.28318*t*31.1+float3(0.1, 0.6, 0.7));
                col += 0.1*fcos(6.28318*t*65.1+float3(0., 0.5, 0.8));
                col += 0.1*fcos(6.28318*t*115.1+float3(0.1, 0.4, 0.7));
                col += 0.1*fcos(6.28318*t*265.1+float3(1.1, 1.4, 2.7));
                col = clamp(col, 0., 1.);
                return col;
            }

            void calcColor(float3 ro, float3 rd, float3 nor, float d, float len, int idx, bool si, float td, out float4 colx, out float4 colsi)
            {
                colsi = 0;
                colx = 0;
                float3 pos = ro+rd*d;
#ifdef DEBUG
                float a = 1.-smoothstep(len-0.15, len+0.00001, length(pos));
                if (idx==0)
                    colx = float4(1., 0., 0., a);
                    
                if (idx==1)
                    colx = float4(0., 1., 0., a);
                    
                if (idx==2)
                    colx = float4(0., 0., 1., a);
                    
                if (si)
                {
                    pos = ro+rd*td;
                    float ta = 1.-smoothstep(len-0.15, len+0.00001, length(pos));
                    if (idx==0)
                        colsi = float4(1., 0., 0., ta);
                        
                    if (idx==1)
                        colsi = float4(0., 1., 0., ta);
                        
                    if (idx==2)
                        colsi = float4(0., 0., 1., ta);
                        
                }
                
#else
                float a = 1.-smoothstep(len-0.15*0.5, len+0.00001, length(pos));
                float3 col = getColor(pos);
                colx = float4(col, a);
                if (si)
                {
                    pos = ro+rd*td;
                    float ta = 1.-smoothstep(len-0.15*0.5, len+0.00001, length(pos));
                    col = getColor(pos);
                    colsi = float4(col, ta);
                }
                
#endif
            }

            bool iBilinearPatch(in float3 ro, in float3 rd, in float4 ps, in float4 ph, in float sz, out float t, out float3 norm, out float si, out float tsi, out float3 normsi, out float fade, out float fadesi)
            {
                fadesi = 0;
                fade = 0;
                normsi = 0;
                tsi = 0;
                si = 0;
                norm = 0;
                t = 0;
                float3 va = float3(0., 0., ph.x+ph.w-ph.y-ph.z);
                float3 vb = float3(0., ps.w-ps.y, ph.z-ph.x);
                float3 vc = float3(ps.z-ps.x, 0., ph.y-ph.x);
                float3 vd = float3(ps.xy, ph.x);
                t = -1.;
                tsi = -1.;
                si = 0;
                fade = 1.;
                fadesi = 1.;
                norm = float3(0., 1., 0.);
                normsi = float3(0., 1., 0.);
                float tmp = 1./(vb.y*vc.x);
                float a = 0.;
                float b = 0.;
                float c = 0.;
                float d = va.z*tmp;
                float e = 0.;
                float f = 0.;
                float g = (vc.z*vb.y-vd.y*va.z)*tmp;
                float h = (vb.z*vc.x-va.z*vd.x)*tmp;
                float i = -1.;
                float j = (vd.x*vd.y*va.z+vd.z*vb.y*vc.x)*tmp-(vd.y*vb.z*vc.x+vd.x*vc.z*vb.y)*tmp;
                float p = dot(float3(a, b, c), rd.xzy*rd.xzy)+dot(float3(d, e, f), rd.xzy*rd.zyx);
                float q = dot(float3(2., 2., 2.)*ro.xzy*rd.xyz, float3(a, b, c))+dot(ro.xzz*rd.zxy, float3(d, d, e))+dot(ro.yyx*rd.zxy, float3(e, f, f))+dot(float3(g, h, i), rd.xzy);
                float r = dot(float3(a, b, c), ro.xzy*ro.xzy)+dot(float3(d, e, f), ro.xzy*ro.zyx)+dot(float3(g, h, i), ro.xzy)+j;
                if (abs(p)<0.000001)
                {
                    float tt = -r/q;
                    if (tt<=0.)
                        return false;
                        
                    t = tt;
                    float3 pos = ro+t*rd;
                    if (length(pos)>sz)
                        return false;
                        
                    float3 grad = ((float3)2.)*pos.xzy*float3(a, b, c)+pos.zxz*float3(d, d, e)+pos.yyx*float3(f, e, f)+float3(g, h, i);
                    norm = -normalize(grad);
                    return true;
                }
                else 
                {
                    float sq = q*q-4.*p*r;
                    if (sq<0.)
                    {
                        return false;
                    }
                    else 
                    {
                        float s = sqrt(sq);
                        float t0 = (-q+s)/(2.*p);
                        float t1 = (-q-s)/(2.*p);
                        float tt1 = min(t0<0. ? t1 : t0, t1<0. ? t0 : t1);
                        float tt2 = max(t0>0. ? t1 : t0, t1>0. ? t0 : t1);
                        float tt0 = tt1;
                        if (tt0<=0.)
                            return false;
                            
                        float3 pos = ro+tt0*rd;
                        bool ru = step(sz, length(pos))>0.5;
                        if (ru)
                        {
                            tt0 = tt2;
                            pos = ro+tt0*rd;
                        }
                        
                        if (tt0<=0.)
                            return false;
                            
                        bool ru2 = step(sz, length(pos))>0.5;
                        if (ru2)
                            return false;
                            
                        if (tt2>0.&&!ru&&!(step(sz, length(ro+tt2*rd))>0.5))
                        {
                            si = 1;
                            fadesi = s;
                            tsi = tt2;
                            float3 tpos = ro+tsi*rd;
                            float3 tgrad = ((float3)2.)*tpos.xzy*float3(a, b, c)+tpos.zxz*float3(d, d, e)+tpos.yyx*float3(f, e, f)+float3(g, h, i);
                            normsi = -normalize(tgrad);
                        }
                        
                        fade = s;
                        t = tt0;
                        float3 grad = ((float3)2.)*pos.xzy*float3(a, b, c)+pos.zxz*float3(d, d, e)+pos.yyx*float3(f, e, f)+float3(g, h, i);
                        norm = -normalize(grad);
                        return true;
                    }
                }
            }

            float dot2(in float3 v)
            {
                return dot(v, v);
            }

            float segShadow(in float3 ro, in float3 rd, in float3 pa, float sh)
            {
                float dm = dot(rd.yz, rd.yz);
                float k1 = (ro.x-pa.x)*dm;
                float k2 = (ro.x+pa.x)*dm;
                float2 k5 = (ro.yz+pa.yz)*dm;
                float k3 = dot(ro.yz+pa.yz, rd.yz);
                float2 k4 = (pa.yz+pa.yz)*rd.yz;
                float2 k6 = (pa.yz+pa.yz)*dm;
                for (int i = 0;i<4+ANGLE_loops; i++)
                {
                    float2 s = float2(i&1, i>>1);
                    float t = dot(s, k4)-k3;
                    if (t>0.)
                        sh = min(sh, dot2(float3(clamp(-rd.x*t, k1, k2), k5-k6*s)+rd*t)/(t*t));
                        
                }
                return sh;
            }

            float boxSoftShadow(in float3 ro, in float3 rd, in float3 rad, in float sk)
            {
                rd += 0.0001*(1.-abs(sign(rd)));
                float3 rdd = rd;
                float3 roo = ro;
                float3 m = 1./rdd;
                float3 n = m*roo;
                float3 k = abs(m)*rad;
                float3 t1 = -n-k;
                float3 t2 = -n+k;
                float tN = max(max(t1.x, t1.y), t1.z);
                float tF = min(min(t2.x, t2.y), t2.z);
                if (tN<tF&&tF>0.)
                    return 0.;
                    
                float sh = 1.;
                sh = segShadow(roo.xyz, rdd.xyz, rad.xyz, sh);
                sh = segShadow(roo.yzx, rdd.yzx, rad.yzx, sh);
                sh = segShadow(roo.zxy, rdd.zxy, rad.zxy, sh);
                sh = clamp(sk*sqrt(sh), 0., 1.);
                return sh*sh*(3.-2.*sh);
            }

            float box(in float3 ro, in float3 rd, in float3 r, out float3 nn, bool entering)
            {
                nn = 0;
                rd += 0.0001*(1.-abs(sign(rd)));
                float3 dr = 1./rd;
                float3 n = ro*dr;
                float3 k = r*abs(dr);
                float3 pin = -k-n;
                float3 pout = k-n;
                float tin = max(pin.x, max(pin.y, pin.z));
                float tout = min(pout.x, min(pout.y, pout.z));
                if (tin>tout)
                    return -1.;
                    
                if (entering)
                {
                    nn = -sign(rd)*step(pin.zxy, pin.xyz)*step(pin.yzx, pin.xyz);
                }
                else 
                {
                    nn = sign(rd)*step(pout.xyz, pout.zxy)*step(pout.xyz, pout.yzx);
                }
                return entering ? tin : tout;
            }

            float3 bgcol(in float3 rd)
            {
                return lerp(((float3)0.01), float3(0.336, 0.458, 0.668), 1.-pow(abs(rd.z+0.25), 1.3));
            }

            float3 background(in float3 ro, in float3 rd, float3 l_dir, out float alpha)
            {
                alpha = 0;
#ifdef ONLY_BOX
                alpha = 0.;
                return ((float3)0.01);
#endif
                float t = (-BOXDIMS.z-ro.z)/rd.z;
                alpha = 0.;
                float3 bgc = bgcol(rd);
                if (t<0.)
                    return bgc;
                    
                float2 uv = ro.xy+t*rd.xy;
#ifdef NO_SHADOW
                float shad = 1.;
#else
                float shad = boxSoftShadow(ro+t*rd, mul(normalize(l_dir+float3(0., 0., 1.)),rotz(PI*0.65)), BOXDIMS, 1.5);
#endif
                float aofac = smoothstep(-0.95, 0.75, length(abs(uv)-min(abs(uv), ((float2)0.45))));
                aofac = min(aofac, smoothstep(-0.65, 1., shad));
                float lght = max(dot(normalize(ro+t*rd+float3(0., -0., -5.)), mul(normalize(l_dir-float3(0., 0., 1.)),rotz(PI*0.65))), 0.);
                float3 col = lerp(((float3)0.4), float3(0.71, 0.772, 0.895), lght*lght*aofac+0.05)*aofac;
                alpha = 1.-smoothstep(7., 10., length(uv));
#ifdef SHADOW_ALPHA
                alpha = clamp(alpha*(1.-aofac)*1.25, 0., 1.);
#endif
                return lerp(col*length(col)*0.8, bgc, smoothstep(7., 10., length(uv)));
            }

#define swap(a, b) tv = a;

            float4 insides(float3 ro, float3 rd, float3 nor_c, float3 l_dir, out float tout)
            {
                tout = 0;
                tout = -1.;
                float3 trd = rd;
                float3 col = ((float3)0.);
                float pi = 3.1415925;
                if (abs(nor_c.x)>0.5)
                {
                    rd = rd.xzy*nor_c.x;
                    ro = ro.xzy*nor_c.x;
                }
                else if (abs(nor_c.z)>0.5)
                {
                    l_dir = mul(l_dir,roty(pi));
                    rd = rd.yxz*nor_c.z;
                    ro = ro.yxz*nor_c.z;
                }
                else if (abs(nor_c.y)>0.5)
                {
                    l_dir = mul(l_dir,rotz(-pi*0.5));
                    rd = rd*nor_c.y;
                    ro = ro*nor_c.y;
                }
                
#ifdef ANIM_SHAPE
                float curvature = 0.001+1.5-1.5*smoothstep(0., 8.5, glsl_mod((_Time.y+tshift)*0.44, 20.))*(1.-smoothstep(10., 18.5, glsl_mod((_Time.y+tshift)*0.44, 20.)));
#else
#ifdef STATIC_SHAPE
                const float curvature = STATIC_SHAPE;
#else
                const float curvature = 0.5;
#endif
#endif
                float bil_size = 1.;
                float4 ps = float4(-bil_size, -bil_size, bil_size, bil_size)*curvature;
                float4 ph = float4(-bil_size, bil_size, bil_size, -bil_size)*curvature;
                float4 colx[3] = {(float4)0, (float4)0., (float4)0.};
                float3 dx[3] = {(float3)-1, (float3)-1, (float3)-1};
                float4 colxsi[3] = {(float4)0, (float4)0., (float4)0.};
                int order[3] = {0, 1, 2};
                for (int i = 0;i<3+ANGLE_loops; i++)
                {
                    if (abs(nor_c.x)>0.5)
                    {
                        ro = mul(ro,rotz(-pi*(1./float(3))));
                        rd = mul(rd,rotz(-pi*(1./float(3))));
                    }
                    else if (abs(nor_c.z)>0.5)
                    {
                        ro = mul(ro,rotz(pi*(1./float(3))));
                        rd = mul(rd,rotz(pi*(1./float(3))));
                    }
                    else if (abs(nor_c.y)>0.5)
                    {
                        ro = mul(ro,rotx(pi*(1./float(3))));
                        rd = mul(rd,rotx(pi*(1./float(3))));
                    }
                    
                    float3 normnew;
                    float tnew;
                    float si;
                    float tsi;
                    float3 normsi;
                    float fade;
                    float fadesi;
                    if (iBilinearPatch(ro, rd, ps, ph, bil_size, tnew, normnew, si, tsi, normsi, fade, fadesi))
                    {
                        if (tnew>0.)
                        {
                            float4 tcol, tcolsi;
                            calcColor(ro, rd, normnew, tnew, bil_size, i, si, tsi, tcol, tcolsi);
                            if (tcol.a>0.)
                            {
                                {
                                    float3 tvalx = float3(tnew, float(si), tsi);
                                    dx[i] = tvalx;
                                }
#ifdef DEBUG
                                colx[i] = tcol;
                                if (si)
                                    colxsi[i] = tcolsi;
                                    
#else
                                float dif = clamp(dot(normnew, l_dir), 0., 1.);
                                float amb = clamp(0.5+0.5*dot(normnew, l_dir), 0., 1.);
                                {
#ifdef USE_COLOR
                                    float3 shad = 0.57*color_blue*amb+1.5*color_blue.bgr*dif;
                                    const float3 tcr = color_red;
#else
                                    float3 shad = float3(0.32, 0.43, 0.54)*amb+float3(1., 0.9, 0.7)*dif;
                                    const float3 tcr = float3(1., 0.21, 0.11);
#endif
                                    float ta = clamp(length(tcol.rgb), 0., 1.);
                                    tcol = clamp(tcol*tcol*2., 0., 1.);
                                    float4 tvalx = float4(tcol.rgb*shad*1.4+3.*(tcr*tcol.rgb)*clamp(1.-(amb+dif), 0., 1.), min(tcol.a, ta));
                                    tvalx.rgb = clamp(2.*tvalx.rgb*tvalx.rgb, 0., 1.);
                                    tvalx *= min(fade*5., 1.);
                                    colx[i] = tvalx;
                                }
                                if (si)
                                {
                                    dif = clamp(dot(normsi, l_dir), 0., 1.);
                                    amb = clamp(0.5+0.5*dot(normsi, l_dir), 0., 1.);
                                    {
#ifdef USE_COLOR
                                        float3 shad = 0.57*color_blue*amb+1.5*color_blue.bgr*dif;
                                        const float3 tcr = color_red;
#else
                                        float3 shad = float3(0.32, 0.43, 0.54)*amb+float3(1., 0.9, 0.7)*dif;
                                        const float3 tcr = float3(1., 0.21, 0.11);
#endif
                                        float ta = clamp(length(tcolsi.rgb), 0., 1.);
                                        tcolsi = clamp(tcolsi*tcolsi*2., 0., 1.);
                                        float4 tvalx = float4(tcolsi.rgb*shad+3.*(tcr*tcolsi.rgb)*clamp(1.-(amb+dif), 0., 1.), min(tcolsi.a, ta));
                                        tvalx.rgb = clamp(2.*tvalx.rgb*tvalx.rgb, 0., 1.);
                                        tvalx.rgb *= min(fadesi*5., 1.);
                                        colxsi[i] = tvalx;
                                    }
                                }
                                
#endif
                            }
                            
                        }
                        
                    }
                    
                }
                float a = 1.;
                if (dx[0].x<dx[1].x)
                {
                    {
                        float3 swap(dx[0], dx[1]);
                    }
                    {
                        int swap(order[0], order[1]);
                    }
                }
                
                if (dx[1].x<dx[2].x)
                {
                    {
                        float3 swap(dx[1], dx[2]);
                    }
                    {
                        int swap(order[1], order[2]);
                    }
                }
                
                if (dx[0].x<dx[1].x)
                {
                    {
                        float3 swap(dx[0], dx[1]);
                    }
                    {
                        int swap(order[0], order[1]);
                    }
                }
                
                tout = max(max(dx[0].x, dx[1].x), dx[2].x);
                if (dx[0].y<0.5)
                {
                    a = colx[order[0]].a;
                }
                
#if !(defined(DEBUG)&&defined(BUG))
                bool rul[3] = {dx[0].y>0.5&&dx[1].x<=0., dx[1].y>0.5&&dx[0].x>dx[1].z, dx[2].y>0.5&&dx[1].x>dx[2].z};
                for (int k = 0;k<3; k++)
                {
                    if (rul[k])
                    {
                        float4 tcolxsi = ((float4)0.);
                        tcolxsi = colxsi[order[k]];
                        float4 tcolx = ((float4)0.);
                        tcolx = colx[order[k]];
                        float4 tvalx = lerp(tcolxsi, tcolx, tcolx.a);
                        colx[order[k]] = tvalx;
                        float4 tvalx2 = lerp(((float4)0.), tvalx, max(tcolx.a, tcolxsi.a));
                        colx[order[k]] = tvalx2;
                    }
                    
                }
#endif
                float a1 = dx[1].y<0.5 ? colx[order[1]].a : dx[1].z>dx[0].x ? colx[order[1]].a : 1.;
                float a2 = dx[2].y<0.5 ? colx[order[2]].a : dx[2].z>dx[1].x ? colx[order[2]].a : 1.;
                col = lerp(lerp(colx[order[0]].rgb, colx[order[1]].rgb, a1), colx[order[2]].rgb, a2);
                a = max(max(a, a1), a2);
                return float4(col, a);
            }

            float4 frag (v2f i) : SV_Target
            {
                float4 fragColor = 0;
                float2 fragCoord = i.uv * _Resolution;
                float osc = 0.5;
                float3 l_dir = normalize(float3(0., 1., 0.));
                l_dir = mul(l_dir,rotz(0.5));
                float mouseY = 1.*0.5*PI;
#ifdef MOUSE_control
                mouseY = (1.-1.15*_Mouse.y/iResolution.y)*0.5*PI;
                if (_Mouse.y<1.)
#endif
                    
#ifdef CAMERA_POS
                mouseY = PI*CAMERA_POS;
#else
                mouseY = PI*0.49-smoothstep(0., 8.5, glsl_mod((_Time.y+tshift)*0.33, 25.))*(1.-smoothstep(14., 24., glsl_mod((_Time.y+tshift)*0.33, 25.)))*0.55*PI;
#endif
#ifdef ROTATION_SPEED
                float mouseX = -2.*PI-0.25*(_Time.y*ROTATION_SPEED+tshift);
#else
                float mouseX = -2.*PI-0.25*(_Time.y+tshift);
#endif
#ifdef MOUSE_control
                mouseX += -(_Mouse.x/iResolution.x)*2.*PI;
#endif
#ifdef CAMERA_FAR
                float3 eye = (2.+CAMERA_FAR)*float3(cos(mouseX)*cos(mouseY), sin(mouseX)*cos(mouseY), sin(mouseY));
#else
                float3 eye = 4.*float3(cos(mouseX)*cos(mouseY), sin(mouseX)*cos(mouseY), sin(mouseY));
#endif
                float3 w = normalize(-eye);
                float3 up = float3(0., 0., 1.);
                float3 u = normalize(cross(w, up));
                float3 v = cross(u, w);
                float4 tot = ((float4)0.);
#ifdef AA_CUBE
                const int AA = AA_CUBE;
                float3 incol_once = ((float3)0.);
                bool in_once = false;
                float4 incolbg_once = ((float4)0.);
                bool bg_in_once = false;
                float4 outcolbg_once = ((float4)0.);
                bool bg_out_once = false;
                for (int mx = 0;mx<AA; mx++)
                for (int nx = 0;nx<AA; nx++)
                {
                    float2 o = float2(glsl_mod(float(mx+AA/2), float(AA)), glsl_mod(float(nx+AA/2), float(AA)))/float(AA)-0.5;
                    float2 uv = (fragCoord+o-0.5*iResolution.xy)/iResolution.x;
#else
                    float2 uv = (fragCoord-0.5*iResolution.xy)/iResolution.x;
#endif
                    float3 rd = normalize(w*FDIST+uv.x*u+uv.y*v);
                    float3 ni;
                    float t = box(eye, rd, BOXDIMS, ni, true);
                    float3 ro = eye+t*rd;
                    float2 coords = ro.xy*ni.z/BOXDIMS.xy+ro.yz*ni.x/BOXDIMS.yz+ro.zx*ni.y/BOXDIMS.zx;
                    float fadeborders = (1.-smoothstep(0.915, 1.05, abs(coords.x)))*(1.-smoothstep(0.915, 1.05, abs(coords.y)));
                    if (t>0.)
                    {
                        float ang = -_Time.y*0.33;
                        float3 col = ((float3)0.);
#ifdef AA_CUBE
                        if (in_once)
                        col = incol_once;
                        else 
                        {
                            in_once = true;
#endif
                            float R0 = (IOR-1.)/(IOR+1.);
                            R0 *= R0;
                            float2 theta = ((float2)0.);
                            float3 n = float3(cos(theta.x)*sin(theta.y), sin(theta.x)*sin(theta.y), cos(theta.y));
                            float3 nr = n.zxy*ni.x+n.yzx*ni.y+n.xyz*ni.z;
                            float3 rdr = reflect(rd, nr);
                            float talpha;
                            float3 reflcol = background(ro, rdr, l_dir, talpha);
                            float3 rd2 = refract(rd, nr, 1./IOR);
                            float accum = 1.;
                            float3 no2 = ni;
                            float3 ro_refr = ro;
                            float4 colo[2] = {(float4)0., (float4)0.};
                            for (int j = 0;j<2+ANGLE_loops; j++)
                            {
                                float tb;
                                float2 coords2 = ro_refr.xy*no2.z+ro_refr.yz*no2.x+ro_refr.zx*no2.y;
                                float3 eye2 = float3(coords2, -1.);
                                float3 rd2trans = rd2.yzx*no2.x+rd2.zxy*no2.y+rd2.xyz*no2.z;
                                rd2trans.z = -rd2trans.z;
                                float4 internalcol = insides(eye2, rd2trans, no2, l_dir, tb);
                                if (tb>0.)
                                {
                                    internalcol.rgb *= accum;
                                    colo[j] = internalcol;
                                }
                                
                                if (tb<=0.||internalcol.a<1.)
                                {
                                    float tout = box(ro_refr, rd2, BOXDIMS, no2, false);
                                    no2 = n.zyx*no2.x+n.xzy*no2.y+n.yxz*no2.z;
                                    float3 rout = ro_refr+tout*rd2;
                                    float3 rdout = refract(rd2, -no2, IOR);
                                    float fresnel2 = R0+(1.-R0)*pow(1.-dot(rdout, no2), 1.3);
                                    rd2 = reflect(rd2, -no2);
#ifdef backside_refl
                                    if (dot(rdout, no2)>0.5)
                                    {
                                        fresnel2 = 1.;
                                    }
                                    
#endif
                                    ro_refr = rout;
                                    ro_refr.z = max(ro_refr.z, -0.999);
                                    accum *= fresnel2;
                                }
                                
                            }
                            float fresnel = R0+(1.-R0)*pow(1.-dot(-rd, nr), 5.);
                            col = lerp(lerp(colo[1].rgb*colo[1].a, colo[0].rgb, colo[0].a)*fadeborders, reflcol, pow(fresnel, 1.5));
                            col = clamp(col, 0., 1.);
#ifdef AA_CUBE
                        }
                        incol_once = col;
                        if (!bg_in_once)
                        {
                            bg_in_once = true;
                            float alpha;
                            incolbg_once = float4(background(eye, rd, l_dir, alpha), 0.15);
#if defined(BG_ALPHA)||defined(ONLY_BOX)||defined(SHADOW_ALPHA)
                            incolbg_once.w = alpha;
#endif
                        }
                        
#endif
                        float cineshader_alpha = 0.;
                        cineshader_alpha = clamp(0.15*dot(eye, ro), 0., 1.);
                        float4 tcolx = float4(col, cineshader_alpha);
#if defined(BG_ALPHA)||defined(ONLY_BOX)||defined(SHADOW_ALPHA)
                        tcolx.w = 1.;
#endif
                        tot += tcolx;
                    }
                    else 
                    {
                        float4 tcolx = ((float4)0.);
#ifdef AA_CUBE
                        if (!bg_out_once)
                        {
                            bg_out_once = true;
#endif
                            float alpha;
                            tcolx = float4(background(eye, rd, l_dir, alpha), 0.15);
#if defined(BG_ALPHA)||defined(ONLY_BOX)||defined(SHADOW_ALPHA)
                            tcolx.w = alpha;
#endif
#ifdef AA_CUBE
                            outcolbg_once = tcolx;
                        }
                        else tcolx = max(outcolbg_once, incolbg_once);
#endif
                        tot += tcolx;
                    }
#ifdef AA_CUBE
                }
                tot /= float(AA*AA);
#endif
                fragColor = tot;
#ifdef NO_ALPHA
                fragColor.w = 1.;
#endif
                fragColor.rgb = clamp(fragColor.rgb, 0., 1.);
#if defined(BG_ALPHA)||defined(ONLY_BOX)||defined(SHADOW_ALPHA)
                fragColor.rgb = fragColor.rgb*fragColor.w+tex2D(_MainTex, fragCoord/iResolution.xy).rgb*(1.-fragColor.w);
#endif
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}