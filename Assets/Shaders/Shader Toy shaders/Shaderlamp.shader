// https://www.shadertoy.com/view/MdjyRm
Shader "Unlit/Shaderlamp"
{
    Properties
    {
        [Header(General)]
        [ToggleUI] _GammaCorrect ("Gamma Correction", Float) = 1
        _Resolution ("Resolution (Change if AA is bad)", Range(1, 1024)) = 1
        [ToggleUI] _ScreenEffect("ScreenEffect", Float) = 0
        
        [Header(Extracted)]
        _Speed("Speed", Range(0.1, 10)) = 1
        [Toggle(_Rings)]_Rings("Rings (default = off)", Float) = 0
        [Toggle(_Polar)]_Polar("Polar (default = off)", Float) = 0
        [Toggle(_Warp)]_Warp("Warp (default = off)", Float) = 0
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #pragma shader_feature_local_fragment _Rings
            #pragma shader_feature_local_fragment _Polar
            #pragma shader_feature_local_fragment _Warp

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
            #define iResolution float3(_Resolution, _Resolution, _Resolution)

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float _Speed;
            #define eps 0.005
            #define far 40.
            #define time _Time.y*0.25*_Speed
            #define PI 3.1415925
            #define PSD pow(abs(textureLod(_MainTex, ((float2)0.5), 0.).r), 2.)

            float2 rotate(float2 p, float a)
            {
                float t = atan2(p.y, p.x) + a;
                float l = length(p);
                return float2(l * cos(t), l * sin(t));
            }

            float sdTorus(float3 p, float2 t)
            {
                float2 q = float2(length(p.xz) - t.x, p.y);
                return length(q) - t.y;
            }

            float3 tri(in float3 x)
            {
                return abs(x - floor(x) - 0.5);
            }

            float distort(float3 p)
            {
                return dot(tri(p + time) + sin(tri(p + time)), ((float3)0.666));
            }

            static float trap;

            float map(float3 p)
            {
                p.z += 0.2;
                p += distort(p * distort(p)) * 0.1;
                trap = dot(sin(p), 1. - abs(p)) * 1.2;
                float d = -sdTorus(p, float2(1., 0.7)) + distort(p) * 0.05;
                #if _Rings
                p.y -= 0.2;
                for (int i = 0;i<3; i++)
                {
                    p.y += float(i)*0.1;
                    d = min(d, sdTorus(p, float2(0.75, 0.01))-distort(p*float(i))*0.01);
                }
                #endif
                return d;
            }

            float3 calcNormal(float3 p)
            {
                float2 e = float2(eps, 0);
                return normalize(float3(map(p + e.xyy) - map(p - e.xyy), map(p + e.yxy) - map(p - e.yxy),
                                        map(p + e.yyx) - map(p - e.yyx)));
            }

            float trace(float3 r, float3 d, float start)
            {
                float m, t = start;
                for (int i = 0; i < 100; i++)
                {
                    m = map(r + d * t);
                    t += m;
                    if (m < eps || t > far)
                        break;
                }
                return t;
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 g;
                float2 R;
                if (_ScreenEffect)
                {
                    g = i.uv * _ScreenParams;
                    R = _ScreenParams.xy;
                }

                else
                {
                    g = i.uv * iResolution;
                    R = iResolution.xy;
                }

                float2 u = (g + g - R) / R.y;
                #ifdef _Polar
                u = rotate(u, 2.*atan2(u.y, u.x)+time);
                #endif
                #ifdef _Warp
                u = abs(u)/dot(u, u)-((float2)step(1., time));
                #endif
                float3 r = float3(0, 0, 1), d = normalize(float3(u, -1)), p, n, col;
                col = ((float3)0.);
                float t = trace(r, d, 0.);
                p = r + d * t;
                n = calcNormal(p);
                if (t < far)
                {
                    float3 objcol = float3(trap / abs(1. - trap), trap * trap, 1. - trap);
                    float3 lp = float3(1, 3, 3);
                    float3 ld = lp - p;
                    float len = length(ld);
                    float atten = max(0., 1. / (len * len));
                    ld /= len;
                    float amb = 0.25;
                    float diff = max(0., dot(ld, n));
                    float spec = pow(max(0., dot(reflect(-ld, n), r)), 8.);
                    float ref = trace(r, reflect(d, n), eps * 5.);
                    col = objcol * (diff * 0.8 + amb * 0.8 + 0.1 * spec + atten * 0.1) * ref;
                }

                float4 fragColor = float4(col, 1);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}