// https://www.shadertoy.com/view/MtByRh
Shader "Unlit/Lensing"
{
    Properties
    {
        [Header(General)]
        [ToggleUI] _GammaCorrect ("Gamma Correction", Float) = 1
        _Resolution ("Resolution (Change if AA is bad)", Range(1, 1024)) = 1
        _Mouse ("Mouse", Vector) = (0.5, 0.5, 0.5, 0.5)
        [ToggleUI] _ScreenEffect("ScreenEffect", Float) = 0

        [Header(Extracted)]
        _Iterations ("Iterations", range(5,30)) = 12
        _Zoom ("Zoom", range(1.0, 10)) = 1.2
        _Speed ("Speed", range(0.1, 10)) = 0.1
        _BlackholeIntensity ("BlackholeIntensity", Float) = 1

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


            static const float formuparam = 0.57;
            static const float volsteps = 10.0;
            static const float stepsize = 0.2;
            static const float tile = 1.0;
            static const float brightness = 0.0015;
            static const float darkmatter = 1;
            static const float distfading = 0.73;
            static const float saturation = 1;
            #define blackholeCenter float3(time*2., time, -2.)
            static const float blackholeRadius = 0.01;
            float _Iterations;
            float _Zoom;
            float _Speed;
            float _BlackholeIntensity;

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
                float4 fragColor;
                float2 uv;
                float2 mo;
                if (_ScreenEffect)
                {
                    float2 fragCoord = i.uv * _ScreenParams;
                    uv = fragCoord.xy / _ScreenParams.xy - 0.5;
                    uv.y *= _ScreenParams.y / _ScreenParams.x;
                    if (_Mouse.z == 1.0)
                    {
                        mo = (2. * _Mouse.xy - _ScreenParams.xy) / _ScreenParams.y;
                    }
                    else
                    {
                        mo = (2. - _ScreenParams.xy) / _ScreenParams.y;
                    }
                }
                else
                {
                    float2 fragCoord = i.uv * iResolution;
                    uv = fragCoord.xy / iResolution.xy - 0.5;
                    uv.y *= iResolution.y / iResolution.x;
                    if (_Mouse.z == 1.0)
                    {
                        mo = (2. * _Mouse.xy - iResolution.xy) / iResolution.y;
                    }
                    else
                    {
                        mo = (2. - iResolution.xy) / iResolution.y;
                    }
                }

                float3 dir = float3(uv * _Zoom, 1.);
                float time = _Time.y * _Speed / 10 + 0.25;
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
                    dir = lerp(dir, pos * sqrt(intensity), _BlackholeIntensity * intensity);
                    float s = 0.1, fade = 1.;
                    float3 v = ((float3)0.);
                    for (int r = 0; r < volsteps; r++)
                    {
                        float3 p = from + s * dir * 0.5;
                        p = abs(((float3)tile) - glsl_mod(p, ((float3)tile*2.)));
                        float pa, a = pa = 0.;
                        for (int i = 0; i < _Iterations; i++)
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