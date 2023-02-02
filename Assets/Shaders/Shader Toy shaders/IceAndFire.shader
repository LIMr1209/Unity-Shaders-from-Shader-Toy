// https://www.shadertoy.com/view/MdfBzl
Shader "Unlit/IceAndFire"
{
    Properties
    {
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
            float _GammaCorrect;
            float _Resolution;

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

            static const float s3 = 1.7320508;
            static const float i3 = 0.57735026;
            static const float2x2 tri2cart = transpose(float2x2(1., 0., -0.5, 0.5 * s3));
            static const float2x2 cart2tri = transpose(float2x2(1., 0., i3, 2. * i3));

            float3 pal(in float t)
            {
                const float3 a = ((float3)0.5);
                const float3 b = ((float3)0.5);
                const float3 c = float3(0.8, 0.8, 0.5);
                const float3 d = float3(0, 0.2, 0.5);
                return clamp(a + b * cos(6.28318 * (c * t + d)), 0., 1.);
            }

            #define HASHSCALE1 0.1031
            #define HASHSCALE3 float3(443.897, 441.423, 437.195)

            float hash12(float2 p)
            {
                float3 p3 = frac(((float3)p.xyx) * HASHSCALE1);
                p3 += dot(p3, p3.yzx + 19.19);
                return frac((p3.x + p3.y) * p3.z);
            }

            float2 hash23(float3 p3)
            {
                p3 = frac(p3 * HASHSCALE3);
                p3 += dot(p3, p3.yzx + 19.19);
                return frac((p3.xx + p3.yz) * p3.zy);
            }

            float3 bary(float2 v0, float2 v1, float2 v2)
            {
                float inv_denom = 1. / (v0.x * v1.y - v1.x * v0.y);
                float v = (v2.x * v1.y - v1.x * v2.y) * inv_denom;
                float w = (v0.x * v2.y - v2.x * v0.y) * inv_denom;
                float u = 1. - v - w;
                return float3(u, v, w);
            }

            float dseg(float2 xa, float2 ba)
            {
                return length(xa - ba * clamp(dot(xa, ba) / dot(ba, ba), 0., 1.));
            }

            float2 randCircle(float3 p)
            {
                float2 rt = hash23(p);
                float r = sqrt(rt.x);
                float theta = 6.2831855 * rt.y;
                return r * float2(cos(theta), sin(theta));
            }

            float2 randCircleSpline(float2 p, float t)
            {
                float t1 = floor(t);
                t -= t1;
                float2 pa = randCircle(float3(p, t1 - 1.));
                float2 p0 = randCircle(float3(p, t1));
                float2 p1 = randCircle(float3(p, t1 + 1.));
                float2 pb = randCircle(float3(p, t1 + 2.));
                float2 m0 = 0.5 * (p1 - pa);
                float2 m1 = 0.5 * (pb - p0);
                float2 c3 = 2. * p0 - 2. * p1 + m0 + m1;
                float2 c2 = -3. * p0 + 3. * p1 - 2. * m0 - m1;
                float2 c1 = m0;
                float2 c0 = p0;
                return (((c3 * t + c2) * t + c1) * t + c0) * 0.8;
            }

            float2 triPoint(float2 p)
            {
                float t0 = hash12(p);
                return mul(tri2cart, p) + 0.45 * randCircleSpline(p, 0.15 * _Time.y + t0);
            }

            void tri_color(in float2 p, in float4 t0, in float4 t1, in float4 t2, in float scl, inout float4 cw)
            {
                float2 p0 = p - t0.xy;
                float2 p10 = t1.xy - t0.xy;
                float2 p20 = t2.xy - t0.xy;
                float3 b = bary(p10, p20, p0);
                float d10 = dseg(p0, p10);
                float d20 = dseg(p0, p20);
                float d21 = dseg(p - t1.xy, t2.xy - t1.xy);
                float d = min(min(d10, d20), d21);
                d *= -sign(min(b.x, min(b.y, b.z)));
                if (d < 0.5 * scl)
                {
                    float2 tsum = t0.zw + t1.zw + t2.zw;
                    float3 h_tri = float3(hash12(tsum + t0.zw), hash12(tsum + t1.zw), hash12(tsum + t2.zw));
                    float2 pctr = (t0.xy + t1.xy + t2.xy) / 3.;
                    float theta = 1. + 0.01 * _Time.y;
                    float2 dir = float2(cos(theta), sin(theta));
                    float grad_input = dot(pctr, dir) - sin(0.05 * _Time.y);
                    float h0 = sin(0.7 * grad_input) * 0.5 + 0.5;
                    h_tri = lerp(((float3)h0), h_tri, 0.4);
                    float h = dot(h_tri, b);
                    float3 c = pal(h);
                    float w = smoothstep(0.5 * scl, -0.5 * scl, d);
                    cw += float4(w * c, w);
                }
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 fragCoord = i.uv * _Resolution;
                float scl = 4.1 / iResolution.y;
                float2 p = (fragCoord - 0.5 - 0.5 * iResolution.xy) * scl;
                float2 tfloor = floor(mul(cart2tri, p) + 0.5);
                float2 pts[9];
                for (int i = 0; i < 3; ++i)
                {
                    for (int j = 0; j < 3; ++j)
                    {
                        pts[3 * i + j] = triPoint(tfloor + float2(i - 1, j - 1));
                    }
                }
                float4 cw = ((float4)0);
                for (int i = 0; i < 2; ++i)
                {
                    for (int j = 0; j < 2; ++j)
                    {
                        float4 t00 = float4(pts[3 * i + j], tfloor + float2(i - 1, j - 1));
                        float4 t10 = float4(pts[3 * i + j + 3], tfloor + float2(i, j - 1));
                        float4 t01 = float4(pts[3 * i + j + 1], tfloor + float2(i - 1, j));
                        float4 t11 = float4(pts[3 * i + j + 4], tfloor + float2(i, j));
                        tri_color(p, t00, t10, t11, scl, cw);
                        tri_color(p, t00, t11, t01, scl, cw);
                    }
                }
                float4 fragColor = cw / cw.w;
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}