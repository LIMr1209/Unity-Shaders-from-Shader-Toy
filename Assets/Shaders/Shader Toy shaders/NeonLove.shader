// https://www.shadertoy.com/view/WdK3Dz
Shader "Unlit/NeonLove"
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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv =  v.uv;
                return o;
            }

            #define POINT_COUNT 8
            static float2 points[POINT_COUNT];
            static const float speed = -0.5;
            static const float len = 0.25;
            static const float scale = 0.012;
            static float intensity = 1.3;
            static float radius = 0.015;
            float sdBezier(float2 pos, float2 A, float2 B, float2 C)
            {
                float2 a = B-A;
                float2 b = A-2.*B+C;
                float2 c = a*2.;
                float2 d = A-pos;
                float kk = 1./dot(b, b);
                float kx = kk*dot(a, b);
                float ky = kk*(2.*dot(a, a)+dot(d, b))/3.;
                float kz = kk*dot(d, a);
                float res = 0.;
                float p = ky-kx*kx;
                float p3 = p*p*p;
                float q = kx*(2.*kx*kx-3.*ky)+kz;
                float h = q*q+4.*p3;
                if (h>=0.)
                {
                    h = sqrt(h);
                    float2 x = (float2(h, -h)-q)/2.;
                    float2 uv = sign(x)*pow(abs(x), ((float2)1./3.));
                    float t = uv.x+uv.y-kx;
                    t = clamp(t, 0., 1.);
                    float2 qos = d+(c+b*t)*t;
                    res = length(qos);
                }
                else 
                {
                    float z = sqrt(-p);
                    float v = acos(q/(p*z*2.))/3.;
                    float m = cos(v);
                    float n = sin(v)*1.7320508;
                    float3 t = float3(m+m, -n-m, n-m)*z-kx;
                    t = clamp(t, 0., 1.);
                    float2 qos = d+(c+b*t.x)*t.x;
                    float dis = dot(qos, qos);
                    res = dis;
                    qos = d+(c+b*t.y)*t.y;
                    dis = dot(qos, qos);
                    res = min(res, dis);
                    qos = d+(c+b*t.z)*t.z;
                    dis = dot(qos, qos);
                    res = min(res, dis);
                    res = sqrt(res);
                }
                return res;
            }

            float2 getHeartPosition(float t)
            {
                return float2(16.*sin(t)*sin(t)*sin(t), -(13.*cos(t)-5.*cos(2.*t)-2.*cos(3.*t)-cos(4.*t)));
            }

            float getGlow(float dist, float radius, float intensity)
            {
                return pow(radius/dist, intensity);
            }

            float getSegment(float t, float2 pos, float offset)
            {
                for (int i = 0;i<POINT_COUNT; i++)
                {
                    points[i] = getHeartPosition(offset+float(i)*len+frac(speed*t)*6.28);
                }
                float2 c = (points[0]+points[1])/2.;
                float2 c_prev;
                float dist = 10000.;
                for (int i = 0;i<POINT_COUNT-1; i++)
                {
                    c_prev = c;
                    c = (points[i]+points[i+1])/2.;
                    dist = min(dist, sdBezier(pos, scale*c_prev, scale*points[i], scale*c));
                }
                return max(0., dist);
            }

            float4 frag (v2f i) : SV_Target
            {
                i.uv.y = 1 - i.uv.y;
                float2 fragCoord = i.uv * _Resolution;
                float2 uv = fragCoord/iResolution.xy;
                float widthHeightRatio = iResolution.x/iResolution.y;
                float2 centre = float2(0.5, 0.5);
                float2 pos = centre-uv;
                pos.y /= widthHeightRatio;
                pos.y += 0.03;
                float t = _Time.y;
                float dist = getSegment(t, pos, 0.);
                float glow = getGlow(dist, radius, intensity);
                float3 col = ((float3)0.);
                col += 10.*((float3)smoothstep(0.006, 0.003, dist));
                col += glow*float3(1., 0.05, 0.3);
                dist = getSegment(t, pos, 3.4);
                glow = getGlow(dist, radius, intensity);
                col += 10.*((float3)smoothstep(0.006, 0.003, dist));
                col += glow*float3(0.1, 0.4, 1.);
                col = 1.-exp(-col);
                col = pow(col, ((float3)0.4545));
                float4 fragColor = float4(col, 1.);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}
