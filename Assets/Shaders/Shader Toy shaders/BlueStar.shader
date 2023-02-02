// https://www.shadertoy.com/view/MlXGWM
Shader "Unlit/BlueStar"
{
    Properties
    {
        _MainTex ("iChannel0", 2D) = "white" {}
        [Header(General)]
        [ToggleUI] _GammaCorrect ("Gamma Correction", Float) = 1
        _Resolution ("Resolution (Change if AA is bad)", Range(1, 1024)) = 1

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
            sampler2D _MainTex;   float4 _MainTex_TexelSize;
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


            float snoise(float3 uv, float res)
            {
                const float3 s = float3(1., 100., 10000.);
                uv *= res;
                float3 uv0 = floor(glsl_mod(uv, res)) * s;
                float3 uv1 = floor(glsl_mod(uv+((float3)1.), res)) * s;
                float3 f = frac(uv);
                f = f * f * (3. - 2. * f);
                float4 v = float4(uv0.x + uv0.y + uv0.z, uv1.x + uv0.y + uv0.z, uv0.x + uv1.y + uv0.z,
                                  uv1.x + uv1.y + uv0.z);
                float4 r = frac(sin(v * 0.001) * 100000.);
                float r0 = lerp(lerp(r.x, r.y, f.x), lerp(r.z, r.w, f.x), f.y);
                r = frac(sin((v + uv1.z - uv0.z) * 0.001) * 100000.);
                float r1 = lerp(lerp(r.x, r.y, f.x), lerp(r.z, r.w, f.x), f.y);
                return lerp(r0, r1, f.z) * 2. - 1.;
            }

            static float brightness = 0.1;

            float4 frag(v2f i) : SV_Target
            {
                float4 fragColor = 0;
                float2 fragCoord = i.uv * _Resolution;
                if (brightness < 0.15)
                {
                    brightness = max(cos(_Time.y) * 0.25 + sin(_Time.y) * 0.25, 0.1);
                }

                float radius = 0.24 + brightness * 0.2;
                float invRadius = 1. / radius;
                float3 orange = float3(0.2, 0.65, 0.5);
                float3 orangeRed = float3(0.1, 0.25, 0.81);
                float time = _Time.y * 0.1;
                float aspect = iResolution.x / iResolution.y;
                float2 uv = fragCoord.xy / iResolution.xy;
                float2 p = -0.5 + uv;
                p.x *= aspect;
                float fade = pow(length(2. * p), 0.5);
                float fVal1 = 1. - fade;
                float fVal2 = 1. - fade;
                float angle = atan2(p.x, p.y) / 6.2832;
                float dist = length(p);
                float3 coord = float3(angle, dist, time * 0.1);
                float newTime1 = abs(snoise(coord + float3(0., -time * (0.35 + brightness * 0.001), time * 0.015),
                                            15.));
                float newTime2 = abs(snoise(coord + float3(0., -time * (0.15 + brightness * 0.001), time * 0.015),
                                            45.));
                for (int i = 1; i <= 7; i++)
                {
                    float power = pow(2., float(i + 1));
                    fVal1 += 0.5 / power * snoise(coord + float3(0., -time, time * 0.2), power * 10. * (newTime1 + 1.));
                    fVal2 += 0.5 / power * snoise(coord + float3(0., -time, time * 0.2), power * 25. * (newTime2 + 1.));
                }
                float corona = pow(fVal1 * max(1.1 - fade, 0.), 2.) * 50.;
                corona += pow(fVal2 * max(1.1 - fade, 0.), 2.) * 50.;
                corona *= 1.2 - newTime1;
                float3 sphereNormal = float3(0., 0., 1.);
                float3 dir = ((float3)0.);
                float3 center = float3(0.5, 0.5, 1.);
                float3 starSphere = ((float3)0.);
                float2 sp = -1. + 2. * uv;
                sp.x *= aspect;
                sp *= 2. - brightness;
                float r = dot(sp, sp);
                float f = (1. - sqrt(abs(1. - r))) / r + brightness * 0.5;
                if (dist < radius)
                {
                    corona *= pow(dist * invRadius, 24.);
                    float2 newUv;
                    newUv.x = sp.x * f;
                    newUv.y = sp.y * f;
                    newUv += float2(time, 0.);
                    float3 texSample = tex2D(_MainTex, newUv).rgb;
                    float uOff = texSample.g * brightness * 3.14 + time;
                    float2 starUV = newUv + float2(uOff, 0.);
                    starSphere = tex2D(_MainTex, starUV).rgb;
                }

                float starGlow = min(max(1. - dist * (1. - brightness), 0.), 1.);
                fragColor.rgb = ((float3)f * (0.75 + brightness * 0.3) * orange) + starSphere + corona * orange +
                    starGlow * orangeRed;
                fragColor.a = 1.;
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}