// https://www.shadertoy.com/view/fldXWS
Shader "Unlit/CubicDispersal"
{
    Properties
    {
        [Header(General)]
        [ToggleUI] _GammaCorrect ("Gamma Correction", Float) = 1
        _Resolution ("Resolution (Change if AA is bad)", Range(1, 1024)) = 1
        _Mouse ("Mouse", Vector) = (0.5, 0.5, 0.5, 0.5)
        
        [Header(Extracted)]
        MDIST ("MDIST", Float) = 150
        STEPS ("STEPS", Float) = 164

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

            float MDIST;
            float STEPS;
            #define pi 3.141592
            #define pmod(p, x) (glsl_mod(p, x)+0.5*x)
            #define rot(a) transpose(float2x2(cos(a), sin(a), -sin(a), cos(a)))
            #define vmm(v, minOrMax) minOrMax(v.x, minOrMax(v.y, v.z))
            #define AO(a, n, p) smoothstep(-a, a, map(p+n*a).x)
            float ebox(float3 p, float3 b)
            {
                float3 q = abs(p)-b;
                return length(max(q, 0.))+min(vmm(q, max), 0.);
            }

            float3 pal(in float t, in float3 a, in float3 b, in float3 c, in float3 d)
            {
                return a+b*cos(2.*pi*(c*t+d));
            }

            float h11(float a)
            {
                return frac(sin(a*12.9898)*43758.547);
            }

            float2 tanha(float2 x)
            {
                float2 x2 = x*x;
                return clamp(x*(27.+x2)/(27.+9.*x2), -1., 1.);
            }

            float tanha(float x)
            {
                float x2 = x*x;
                return clamp(x*(27.+x2)/(27.+9.*x2), -1., 1.);
            }

            struct sdResult 
            {
                float2 center;
                float2 dim;
                float id;
                float vol;
            };
            sdResult subdiv(float2 p, float seed)
            {
                float2 dMin = ((float2)-10.);
                float2 dMax = ((float2)10.);
                float t = _Time.y*0.6;
                float t2 = _Time.y;
                float2 dim = dMax-dMin;
                float id = 0.;
                float ITERS = 6.;
                float MIN_SIZE = 0.1;
                float MIN_ITERS = 1.;
                float2 diff2 = ((float2)1);
                for (float i = 0.;i<ITERS; i++)
                {
                    float2 divHash = tanha(float2(sin(t2*pi/3.+id+i*t2*0.05), cos(t2*pi/3.+h11(id)*100.+i*t2*0.05))*3.)*0.35+0.5;
                    divHash = lerp(((float2)0.5), divHash, tanha(sin(t*0.8)*5.)*0.2+0.4);
                    float2 divide = divHash*dim+dMin;
                    divide = clamp(divide, dMin+MIN_SIZE+0.01, dMax-MIN_SIZE-0.01);
                    float2 minAxis = min(abs(dMin-divide), abs(dMax-divide));
                    float minSize = min(minAxis.x, minAxis.y);
                    bool smallEnough = minSize<MIN_SIZE;
                    if (smallEnough&&i+1.>MIN_ITERS)
                    {
                        break;
                    }
                    
                    dMax = lerp(dMax, divide, step(p, divide));
                    dMin = lerp(divide, dMin, step(p, divide));
                    diff2 = step(p, divide)-float2(h11(diff2.x+seed)*10., h11(diff2.y+seed)*10.);
                    id = length(diff2)*100.;
                    dim = dMax-dMin;
                }
                float2 center = (dMin+dMax)/2.;
                sdResult result;
                result.center = center;
                result.id = id;
                result.dim = dim;
                result.vol = dim.x*dim.y;
                return result;
            }

            static float3 rdg = ((float3)0);
            float dibox(float3 p, float3 b, float3 rd)
            {
                float3 dir = sign(rd)*b;
                float3 rc = (dir-p)/rd;
                return min(rc.x, rc.z)+0.01;
            }

            static bool traverse = true;
            float3 map(float3 p)
            {
                float seed = sign(p.y)-0.3;
                seed = 1.;
                float2 a = float2(99999, 1);
                float2 b = ((float2)2);
                a.x = p.y-2.;
                float id = 0.;
                if (a.x<0.1||!traverse)
                {
                    float t = _Time.y;
                    sdResult sdr = subdiv(p.xz, seed);
                    float3 centerOff = float3(sdr.center.x, 0, sdr.center.y);
                    float2 dim = sdr.dim;
                    float rnd = 0.05;
                    float size = min(dim.y, dim.x)*1.;
                    size += (sin((centerOff.x+centerOff.z)*0.6+t*4.5)*0.5+0.5)*2.;
                    size = min(size, 4.);
                    a.x = ebox(p-centerOff-float3(0, 0, 0), float3(dim.x, size, dim.y)*0.5-rnd)-rnd;
                    if (traverse)
                    {
                        b.x = dibox(p-centerOff, float3(dim.x, 1, dim.y)*0.5, rdg);
                        a = a.x<b.x ? a : b;
                    }
                    
                    id = sdr.id;
                }
                
                return float3(a, id);
            }

            float3 norm(float3 p)
            {
                float2 e = float2(0.01, 0.);
                return normalize(map(p).x-float3(map(p-e.xyy).x, map(p-e.yxy).x, map(p-e.yyx).x));
            }

            float4 frag (v2f i) : SV_Target
            {
                float2 fragCoord = i.uv * _Resolution;
                float2 R = iResolution.xy;
                float2 uv = (fragCoord-0.5*R.xy)/R.y;
                float3 col = ((float3)0);
                float3 ro = float3(0, 6., -12)*1.2;
                ro.xz = mul(ro.xz,rot(0.35));
                float3 lk = float3(-1, -3, 0.5);
                if (_Mouse.z>0.)
                {
                    ro *= 2.;
                    lk = ((float3)0);
                    ro.yz = mul(ro.yz,rot(2.*(_Mouse.y/iResolution.y-0.5)));
                    ro.zx = mul(ro.zx,rot(-9.*(_Mouse.x/iResolution.x-0.5)));
                }
                
                float3 f = ((float3)normalize(lk-ro));
                float3 r = normalize(cross(float3(0, 1, 0), f));
                float3 rd = normalize(f*1.8+r*uv.x+uv.y*cross(f, r));
                rdg = rd;
                float3 p = ro;
                float dO = 0.;
                float3 d;
                bool hit = false;
                for (float i = 0.;i<STEPS; i++)
                {
                    p = ro+rd*dO;
                    d = map(p);
                    dO += d.x;
                    if (d.x<0.005)
                    {
                        hit = true;
                        break;
                    }
                    
                    if (dO>MDIST)
                        break;
                        
                }
                if (hit&&d.y!=2.)
                {
                    traverse = false;
                    float3 n = norm(p);
                    float3 r = reflect(rd, n);
                    float3 e = ((float3)0.5);
                    float3 al = pal(frac(d.z)*0.35-0.8, e*1.2, e, e*2., float3(0, 0.33, 0.66));
                    col = al;
                    float3 ld = normalize(float3(0, 45, 0)-p);
                    float sss = 0.1;
                    float sssteps = 10.;
                    for (float i = 1.;i<sssteps; ++i)
                    {
                        float dist = i*0.2;
                        sss += smoothstep(0., 1., map(p+ld*dist).x/dist)/(sssteps*1.5);
                    }
                    sss = clamp(sss, 0., 1.);
                    float diff = max(0., dot(n, ld))*0.7+0.3;
                    float amb = dot(n, ld)*0.45+0.55;
                    float spec = pow(max(0., dot(r, ld)), 13.);
                    float ao = AO(0.1, n, p)*AO(0.2, n, p)*AO(0.3, n, p);
                    spec = smoothstep(0., 1., spec);
                    col = float3(0.204, 0.267, 0.373)*lerp(float3(0.169, 0., 0.169), float3(0.984, 0.996, 0.804), lerp(amb, diff, 0.75))+spec*0.3;
                    col += sss*al;
                    col *= lerp(ao, 1., 0.65);
                    col = pow(col, ((float3)0.85));
                }
                else 
                {
                    col = lerp(float3(0.373, 0.835, 0.988), float3(0.424, 0.059, 0.925), length(uv));
                }
                col *= 1.-0.5*pow(length(uv*float2(0.8, 1.)), 2.7);
                float3 col2 = smoothstep(float3(0., 0., 0.), float3(1.1, 1.1, 1.3), col);
                col = lerp(col, col2, 0.5)*1.05;
                float4 fragColor = float4(col, 1.);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}