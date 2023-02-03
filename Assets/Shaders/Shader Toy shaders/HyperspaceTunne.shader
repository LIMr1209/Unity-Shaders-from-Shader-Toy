// https://www.shadertoy.com/view/wtd3zM
Shader "Unlit/HyperspaceTunne"
{
    Properties
    {
        [Header(General)]
        [ToggleUI] _GammaCorrect ("Gamma Correction", Float) = 1
        _Resolution ("Resolution (Change if AA is bad)", Range(1, 1024)) = 1
        _Mouse ("Mouse", Vector) = (0.5, 0.5, 0.5, 0.5)


        [Header(Extracted)]
        MOD3 ("MOD3", Vector) = (0.1031,0.11369,0.13787)
        period ("period", Float) = 1
        speed ("speed", Float) = 2
        rotation_speed ("rotation_speed", Float) = 0.3
        t2 ("t2", Float) = 4
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

            
            #define TAU 6.28318
            #define PI 3.141592
            float period;
            float speed;
            float rotation_speed;
            float t2;
            float3 MOD3;
            float3 hash33(float3 p3)
            {
                p3 = frac(p3*MOD3);
                p3 += dot(p3, p3.yxz+19.19);
                return -1.+2.*frac(float3((p3.x+p3.y)*p3.z, (p3.x+p3.z)*p3.y, (p3.y+p3.z)*p3.x));
            }

            float simplexNoise(float3 p)
            {
                const float K1 = 0.33333334;
                const float K2 = 0.16666667;
                float3 i = floor(p+(p.x+p.y+p.z)*K1);
                float3 d0 = p-(i-(i.x+i.y+i.z)*K2);
                float3 e = step(((float3)0.), d0-d0.yzx);
                float3 i1 = e*(1.-e.zxy);
                float3 i2 = 1.-e.zxy*(1.-e);
                float3 d1 = d0-(i1-1.*K2);
                float3 d2 = d0-(i2-2.*K2);
                float3 d3 = d0-(1.-3.*K2);
                float4 h = max(0.6-float4(dot(d0, d0), dot(d1, d1), dot(d2, d2), dot(d3, d3)), 0.);
                float4 n = h*h*h*h*float4(dot(d0, hash33(i)), dot(d1, hash33(i+i1)), dot(d2, hash33(i+i2)), dot(d3, hash33(i+1.)));
                return dot(((float4)31.316), n);
            }

            float fBm3(in float3 p)
            {
                float f = 0.;
                float scale = 5.;
                p = glsl_mod(p, scale);
                float amp = 0.75;
                for (int i = 0;i<5; i++)
                {
                    f += simplexNoise(p*scale)*amp;
                    amp *= 0.5;
                    scale *= 2.;
                }
                return min(f, 1.);
            }

            float3 mod289(float3 x)
            {
                return x-floor(x*(1./289.))*289.;
            }

            float4 mod289(float4 x)
            {
                return x-floor(x*(1./289.))*289.;
            }

            float4 permute(float4 x)
            {
                return mod289((x*34.+1.)*x);
            }

            float4 taylorInvSqrt(float4 r)
            {
                return 1.7928429-0.85373473*r;
            }

            float snoise(float3 v)
            {
                const float2 C = float2(0.16666667, 0.33333334);
                const float4 D = float4(0., 0.5, 1., 2.);
                float3 i = floor(v+dot(v, C.yyy));
                float3 x0 = v-i+dot(i, C.xxx);
                float3 g = step(x0.yzx, x0.xyz);
                float3 l = 1.-g;
                float3 i1 = min(g.xyz, l.zxy);
                float3 i2 = max(g.xyz, l.zxy);
                float3 x1 = x0-i1+C.xxx;
                float3 x2 = x0-i2+C.yyy;
                float3 x3 = x0-D.yyy;
                i = mod289(i);
                float4 p = permute(permute(permute(i.z+float4(0., i1.z, i2.z, 1.))+i.y+float4(0., i1.y, i2.y, 1.))+i.x+float4(0., i1.x, i2.x, 1.));
                float n_ = 0.14285715;
                float3 ns = n_*D.wyz-D.xzx;
                float4 j = p-49.*floor(p*ns.z*ns.z);
                float4 x_ = floor(j*ns.z);
                float4 y_ = floor(j-7.*x_);
                float4 x = x_*ns.x+ns.yyyy;
                float4 y = y_*ns.x+ns.yyyy;
                float4 h = 1.-abs(x)-abs(y);
                float4 b0 = float4(x.xy, y.xy);
                float4 b1 = float4(x.zw, y.zw);
                float4 s0 = floor(b0)*2.+1.;
                float4 s1 = floor(b1)*2.+1.;
                float4 sh = -step(h, ((float4)0.));
                float4 a0 = b0.xzyw+s0.xzyw*sh.xxyy;
                float4 a1 = b1.xzyw+s1.xzyw*sh.zzww;
                float3 p0 = float3(a0.xy, h.x);
                float3 p1 = float3(a0.zw, h.y);
                float3 p2 = float3(a1.xy, h.z);
                float3 p3 = float3(a1.zw, h.w);
                float4 norm = taylorInvSqrt(float4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
                p0 *= norm.x;
                p1 *= norm.y;
                p2 *= norm.z;
                p3 *= norm.w;
                float4 m = max(0.6-float4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.);
                m = m*m;
                return 42.*dot(m*m, float4(dot(p0, x0), dot(p1, x1), dot(p2, x2), dot(p3, x3)));
            }

            float getnoise(int octaves, float persistence, float freq, float3 coords)
            {
                float amp = 1.;
                float maxamp = 0.;
                float sum = 0.;
                for (int i = 0;i<octaves; ++i)
                {
                    sum += amp*snoise(coords*freq);
                    freq *= 2.;
                    maxamp += amp;
                    amp *= persistence;
                }
                return sum/maxamp*0.5+0.5;
            }

            float4 frag (v2f i) : SV_Target
            {
                float2 fragCoord = i.uv * _Resolution;
                float t = glsl_mod(_Time.y, t2);
                t = t/t2;
                float4 col = ((float4)0.);
                float2 q = fragCoord.xy/iResolution.xy;
                float2 p = (2.*fragCoord.xy-iResolution.xy)/min(iResolution.y, iResolution.x);
                float2 mo = (2.*_Mouse.xy-iResolution.xy)/min(iResolution.x, iResolution.y);
                p += float2(0., -0.1);
                float ay = 0., ax = 0., az = 0.;
                if (_Mouse.z>0.)
                {
                    ay = 3.*mo.x;
                    ax = 3.*mo.y;
                }
                
                float3x3 mY = transpose(float3x3(cos(ay), 0., sin(ay), 0., 1., 0., -sin(ay), 0., cos(ay)));
                float3x3 mX = transpose(float3x3(1., 0., 0., 0., cos(ax), sin(ax), 0., -sin(ax), cos(ax)));
                float3x3 m = mul(mX,mY);
                float3 v = float3(p, 1.);
                v = mul(m,v);
                float v_xy = length(v.xy);
                float z = v.z/v_xy;
                float focal_depth = 0.15;
#ifdef WHITEOUT
                focal_depth = lerp(0.15, 0.015, smoothstep(0.65, 0.9, t));
#endif
                float2 polar;
                float p_len = length(v.xy);
                polar.y = z*focal_depth+_Time.y*speed;
                float a = atan2(v.y, v.x);
                a = 0.5+0.5*a/(1.*PI);
                a -= _Time.y*rotation_speed;
                float x = frac(a);
                if (x>=0.5)
                    x = 1.-x;
                    
                polar.x = x;
                float val = 0.45+0.55*fBm3(float3(float2(2., 0.5)*polar, 0.15*_Time.y));
                val = clamp(val, 0., 1.);
                col.rgb = float3(0.15, 0.4, 0.9)*((float3)val);
                float3 white = 0.35*((float3)smoothstep(0.55, 1., val));
                col.rgb += white;
                col.rgb = clamp(col.rgb, 0., 1.);
                float w_total = 0., w_out = 0.;
#ifdef WHITEOUT
                float w_in = 0.;
                w_in = abs(1.-1.*smoothstep(0., 0.25, t));
                w_out = abs(1.*smoothstep(0.8, 1., t));
                w_total = max(w_in, w_out);
#endif
                float disk_size = max(0.025, 1.5*w_out);
                float disk_col = exp(-(p_len-disk_size)*4.);
                col.rgb += clamp(((float3)disk_col), 0., 1.);
#ifdef WHITEOUT
                col.rgb = lerp(col.rgb, ((float3)1.), w_total);
#endif
                float4 fragColor = float4(col.rgb, 1);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}