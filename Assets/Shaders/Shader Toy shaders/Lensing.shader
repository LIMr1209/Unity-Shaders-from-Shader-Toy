// https://www.shadertoy.com/view/MtByRh
Shader "Unlit/Lensing"
{
    Properties
    {
        [Header(General)]
        [ToggleUI] _GammaCorrect ("Gamma Correction", Float) = 1
        _Resolution ("Resolution (Change if AA is bad)", Range(1, 1024)) = 1
        _Mouse ("Mouse", Vector) = (0.5, 0.5, 0.5, 0.5)

        [Header(Extracted)]
        iterations ("iterations", Float) = 12
        formuparam ("formuparam", Float) = 0.57
        volsteps ("volsteps", Float) = 10
        stepsize ("stepsize", Float) = 0.2
        zoom ("zoom", Float) = 1.2
        tile ("tile", Float) = 1
        speed ("speed", Float) = 0.01
        brightness ("brightness", Float) = 0.0015
        darkmatter ("darkmatter", Float) = 1
        distfading ("distfading", Float) = 0.73
        saturation ("saturation", Float) = 1
        blackholeRadius ("blackholeRadius", Float) = 1.2
        blackholeIntensity ("blackholeIntensity", Float) = 1

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


            float iterations;
            float formuparam;
            float volsteps;
            float stepsize;
            float zoom;
            float tile;
            float speed;
            float brightness;
            float darkmatter;
            float distfading;
            float saturation;
            #define mo (2.*_Mouse.xy-iResolution.xy)/iResolution.y
            #define blackholeCenter float3(time*2., time, -2.)
            float blackholeRadius;
            float blackholeIntensity;

            float iSphere(float3 ray, float3 dir, float3 center, float radius)
            {
                float3 rc = ray - center;
                float c = dot(rc, rc) - radius * radius;
                float b = dot(dir, rc);
                float d = b * b - c;
                float t = -b - sqrt(abs(d));
                float st = step(0., min(t, d));
                return lerp(-1., t, st);
            }

            float3 iPlane(float3 ro, float3 rd, float3 po, float3 pd)
            {
                float d = dot(po - ro, pd) / dot(rd, pd);
                return d * rd + ro;
            }

            float3 r(float3 v, float2 r)
            {
                float4 t = sin(float4(r, r + 1.5707964));
                float g = dot(v.yz, t.yw);
                return float3(v.x * t.z - g * t.x, v.y * t.w - v.z * t.y, v.x * t.x + g * t.z);
            }

            float4 frag(v2f i) : SV_Target
            {
                float4 fragColor = 0;
                float2 fragCoord = i.uv * _Resolution;
                float2 uv = fragCoord.xy / iResolution.xy - 0.5;
                uv.y *= iResolution.y / iResolution.x;
                float3 dir = float3(uv * zoom, 1.);
                float time = _Time.y * speed + 0.25;
                float3 from = float3(0., 0., -15.);
                from = r(from, mo / 10.);
                dir = r(dir, mo / 10.);
                from += blackholeCenter;
                float3 nml = normalize(blackholeCenter - from);
                float3 pos = iPlane(from, dir, blackholeCenter, nml);
                pos = blackholeCenter - pos;
                float intensity = dot(pos, pos);
                if (intensity > blackholeRadius * blackholeRadius)
                {
                    intensity = 1. / intensity;
                    dir = lerp(dir, pos * sqrt(intensity), blackholeIntensity * intensity);
                    float s = 0.1, fade = 1.;
                    float3 v = ((float3)0.);
                    for (int r = 0; r < volsteps; r++)
                    {
                        float3 p = from + s * dir * 0.5;
                        p = abs(((float3)tile) - glsl_mod(p, ((float3)tile*2.)));
                        float pa, a = pa = 0.;
                        for (int i = 0; i < iterations; i++)
                        {
                            p = abs(p) / dot(p, p) - formuparam;
                            a += abs(length(p) - pa);
                            pa = length(p);
                        }
                        float dm = max(0., darkmatter - a * a * 0.001);
                        a *= a * a;
                        if (r > 6)
                            fade *= 1. - dm;

                        v += fade;
                        v += float3(s, s * s, s * s * s * s) * a * brightness * fade;
                        fade *= distfading;
                        s += stepsize;
                    }
                    v = lerp(((float3)length(v)), v, saturation);
                    fragColor = float4(v * 0.01, 1.);
                }
                else fragColor = ((float4)0.);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}