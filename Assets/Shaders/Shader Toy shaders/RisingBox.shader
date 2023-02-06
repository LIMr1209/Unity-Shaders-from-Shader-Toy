// https://www.shadertoy.com/view/MtSBRw
Shader "Unlit/RisingBox"
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

            #define time (_Time.y+100.)

            float3x3 lookat(float3 d, float3 up)
            {
                float3 w = normalize(d), u = normalize(cross(w, up));
                return transpose(float3x3(u, cross(u, w), w));
            }

            float2x2 rotate(float a)
            {
                return transpose(float2x2(cos(a), sin(a), -sin(a), cos(a)));
            }

            float3 rotate(float3 p, float3 axis, float theta)
            {
                axis = normalize(axis);
                float3 v = cross(p, axis), u = cross(axis, v);
                return u * cos(theta) + v * sin(theta) + axis * dot(p, axis);
            }

            float hash(float n)
            {
                return frac(sin(n) * 43758.547);
            }

            float udRoundBox(float3 p, float3 b, float r)
            {
                return length(max(abs(p) - b, 0.)) - r;
            }

            float map(in float3 p)
            {
                float3 g = float3(floor(p.xz / 4.), 0);
                p.xz = glsl_mod(p.xz, 4.) - 2.;
                float n = max(0.5, hash(dot(g.xy, float2(10, 180))));
                p.y -= n * n * time * 7.;
                float s = 10. * hash(dot(g.xy, float2(5, 10)));
                if (s < 3.)
                    return 1.;

                g.z = floor(p.y / s);
                p.y = glsl_mod(p.y, s) - s / 2.;
                if (hash(dot(g, float3(5, 70, 1))) < 0.6)
                    return 1.;

                p = rotate(p, float3(hash(dot(g, float3(5, 27, 123))) * 2. - 1.,
                                     hash(dot(g, float3(15, 370, 23))) * 2. - 1.,
                                     hash(dot(g, float3(25, 570, 3))) * 2. - 1.),
                           time + hash(dot(g, float3(25, 570, 553))) * 3.);
                return udRoundBox(p, ((float3)0.5), 0.2);
            }

            float3 calcNormal(in float3 pos)
            {
                float2 e = float2(1, -1) * 0.002;
                return normalize(
                    e.xyy * map(pos + e.xyy) + e.yyx * map(pos + e.yyx) + e.yxy * map(pos + e.yxy) + e.xxx * map(
                        pos + e.xxx));
            }

            float3 doColor(float3 p)
            {
                if (p.y > 10.)
                    return float3(0, 0.7, 0.8);

                if (p.y > 0.)
                    return float3(0.3, 0.7, 0.2);

                return ((float3)0);
            }

            float3 rayCastPlane(float3 ro, float3 rd, float3 pos, float3 nor, float3 up)
            {
                float z = dot(pos - ro, nor) / dot(rd, nor);
                float3 p = ro + rd * z, a = p - pos, u = normalize(cross(nor, up)), v = normalize(cross(u, nor));
                return float3(-dot(a, u), dot(a, v), z);
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 fragCoord = i.uv * _Resolution;
                float2 p = (fragCoord * 2. - iResolution.xy) / iResolution.y;
                float3 ro = float3(0., 25., 20.);
                ro.xz = mul(rotate(_Time.y * 0.1), ro.xz);
                float3 rd = mul(lookat(-ro, float3(0, 1, 0)), normalize(float3(p, 2)));
                float3 col = lerp(float3(0.05, 0.05, 0.3), ((float3)0.8),
                                  smoothstep(0.5, 2.5, length(p * float2(1, 2))));
                const float maxd = 80., precis = 0.01;
                float t = 0., d;
                for (int i = 0; i < 150; i++)
                {
                    float3 p = ro + rd * t;
                    t += d = min(map(p), 1.);
                    if (d < precis || t > maxd)
                        break;
                }
                if (d < precis)
                {
                    float3 p = ro + rd * t;
                    float3 nor = calcNormal(p);
                    float3 li = normalize(((float3)1));
                    float3 bg = col;
                    col = doColor(p);
                    float dif = clamp(dot(nor, li), 0.3, 1.);
                    float amb = max(0.5 + 0.5 * nor.y, 0.);
                    float spc = pow(clamp(dot(reflect(normalize(p - ro), nor), li), 0., 1.), 30.);
                    col *= dif * amb;
                    col += spc;
                    col = clamp(col, 0., 1.);
                    col = lerp(bg, col, exp(-t * t * 0.0001));
                    col = pow(col, ((float3)0.6));
                }

                float3 c = rayCastPlane(ro, rd, ((float3)0), float3(0, 1, 0), float3(0, 0, 1));
                if (c.z < t)
                {
                    col = lerp(col, float3(1, 0.95, 0.9), smoothstep(30., 0., length(c.xy)));
                    col = lerp(col, float3(0.9, 0.5, 0.2), smoothstep(1., 0., map(ro + rd * c.z)));
                }

                c = rayCastPlane(ro, rd, float3(0, 10, 0), float3(0, 1, 0), float3(0, 0, 1));
                if (c.z < t)
                {
                    col = lerp(col, float3(0.8, 0.7, 0.2), smoothstep(1., 0., map(ro + rd * c.z)));
                }

                float4 fragColor = float4(col, 1.);;
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}