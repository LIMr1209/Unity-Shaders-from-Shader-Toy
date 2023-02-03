// https://www.shadertoy.com/view/XllBDl
Shader "Unlit/FestivePentagram "
{
    Properties
    {
        [Header(General)]
        [ToggleUI] _GammaCorrect ("Gamma Correction", Float) = 1
        _Resolution ("Resolution (Change if AA is bad)", Range(1, 1024)) = 1
        _Mouse ("Mouse", Vector) = (0.5, 0.5, 0.5, 0.5)
        
        [Header(Extracted)]
        N ("N", Float) = 5
        scale ("scale", Float) = 1
        CAMERA ("CAMERA", Float) = 6
        A ("A", Float) = 0.6
        K ("K", Float) = 0.4
        R ("R", Float) = 1

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

            #define PI 3.141592             
            int N;
            float scale;
            float CAMERA;
            float A;
            float K;
            float R;
            static const float theta = 2.*PI/float(N);
            static const float3x3 m = transpose(float3x3(cos(theta), sin(theta), 0, -sin(theta), cos(theta), 0, 0, 0, 1));
            float det(float2 c0, float2 c1)
            {
                return determinant(transpose(float2x2(c0, c1)));
            }

            float2 closest0(float3 p, float3 q, float3 r, float3 s)
            {
                float2 c0 = float2(1., dot(q, s));
                float2 c1 = float2(-dot(q, s), -1.);
                float2 a = float2(dot(r-p, q), dot(r-p, s));
                return float2(det(a, c1), det(c0, a))/det(c0, c1);
            }

            float2 closest1(float3 p, float3 q, float3 r, float3 s)
            {
                float2x2 m = transpose(float2x2(1., dot(q, s), -dot(q, s), -1.));
                return mul(m, float2(dot(r-p, q), dot(r-p, s)));
            }

            float2 closest2(float3 p, float3 q, float3 r, float3 s)
            {
                float3 n = normalize(cross(q, s));
                float3 n1 = cross(q, n);
                float3 n2 = cross(s, n);
                return float2(dot(r-p, n2)/dot(q, n2), dot(p-r, n1)/dot(s, n1));
            }

            float2 mmul(float2x2 m, float2 p)
            {
                return mul(m,p);
                return float2(m[0][0]*p[0]+m[1][0]*p[1], m[0][1]*p[0]+m[1][1]*p[1]);
            }

            float2 closest3(float3 p, float3 q, float3 r, float3 s)
            {
                float k = dot(q, s);
                float2x2 m = transpose(float2x2(-1., -k, k, 1.));
                return mmul(m, float2(dot(r-p, q), dot(r-p, s)))/(k*k-1.);
            }

            float2 closest(float3 p, float3 q, float3 r, float3 s)
            {
                return closest3(p, q, r, s);
            }

            float3 hsv2rgb_smooth(in float3 c)
            {
                float3 rgb = clamp(abs(glsl_mod(c.x*6.+float3(0., 4., 2.), 6.)-3.)-1., 0., 1.);
                rgb = rgb*rgb*(3.-2.*rgb);
                return c.z*lerp(((float3)1.), rgb, c.y);
            }

            float3x3 qrot(float4 q)
            {
                float x = q.x, y = q.y, z = q.z, w = q.w;
                float x2 = x*x, y2 = y*y, z2 = z*z;
                float xy = x*y, xz = x*z, xw = x*w;
                float yz = y*z, yw = y*w, zw = z*w;
                return mul(2.,transpose(float3x3(0.5-y2-z2, xy+zw, xz-yw, xy-zw, 0.5-x2-z2, yz+xw, xz+yw, yz-xw, 0.5-x2-y2)));
            }

            float2 rotate(float2 p, float t)
            {
                return p*cos(t)+float2(p.y, -p.x)*sin(t);
            }

            float3 transform(in float3 p)
            {
                if (_Mouse.x>0.)
                {
                    float theta = (2.*_Mouse.y-iResolution.y)/iResolution.y*PI;
                    float phi = (2.*_Mouse.x-iResolution.x)/iResolution.x*PI;
                    p.yz = rotate(p.yz, theta);
                    p.zx = rotate(p.zx, -phi);
                }
                
                return p;
            }

            float4 frag (v2f i) : SV_Target
            {
                float2 fragCoord = i.uv * _Resolution;
                float2 xy = scale*(2.*fragCoord-iResolution.xy)/iResolution.y;
                float3 p = float3(0, 0, -CAMERA);
                float3 q = float3(xy, 2);
                p = transform(p);
                q = transform(q);
                q = normalize(q);
                float3 r = float3(0, 1, 0);
                float3 s = float3(1, 0, 0);
                float3 axis = normalize(float3(1, 1, cos(0.1*_Time.y)));
                float phi = _Time.y*0.15;
                float3x3 n = qrot(float4(sin(phi)*axis, cos(phi)));
                p = mul(n,p);
                q = mul(n,q);
                float mindist = 10000000000.;
                float3 color = ((float3)0);
                for (int i = 0;i<N; i++)
                {
                    float2 k = closest(p, q, r, s);
                    float3 p1 = p+k.x*q;
                    float3 r1 = r+k.y*s;
                    float d = distance(p1, r1);
                    float h = glsl_mod(0.3*(-_Time.y+log(1.+abs(k.y))), 1.);
                    float3 basecolor = hsv2rgb_smooth(float3(h, 1., 1.));
                    color += A*float(k.x>0.)*(1.-pow(smoothstep(0., R, d), K))*basecolor;
                    s = mul(m,s);
                    r = mul(m,r);
                }
                float4 outColor = float4(sqrt(color), 1.);
                if (_GammaCorrect) outColor.rgb = pow(outColor.rgb, 2.2);
                return outColor;
            }
            ENDCG
        }
    }
}