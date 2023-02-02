// https://www.shadertoy.com/view/XtBXW3
Shader "Unlit/RainbowLaserBeam"
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

            float3 Strand(in float2 fragCoord, in float3 color, in float hoffset, in float hscale, in float vscale,
                          in float timescale)
            {
                float glow = 0.06 * iResolution.y;
                float twopi = 6.2831855;
                float curve = 1. - abs(
                    fragCoord.y - (sin(glsl_mod(fragCoord.x*hscale/100./iResolution.x*1000.+_Time.y*timescale+hoffset,
                                                twopi)) * iResolution.y * 0.25 * vscale + iResolution.y / 2.));
                float i = clamp(curve, 0., 1.);
                i += clamp((glow + curve) / glow, 0., 1.) * 0.4;
                return i * color;
            }

            float3 Muzzle(in float2 fragCoord, in float timescale)
            {
                float theta = atan2(iResolution.y / 2. - fragCoord.y,
                                    iResolution.x - fragCoord.x + 0.13 * iResolution.x);
                float len = iResolution.y * (10. + sin(theta * 20. + float(int(_Time.y * 20.)) * -35.)) / 11.;
                float d = max(-0.6, 1. - sqrt(pow(abs(iResolution.x - fragCoord.x), 2.) + pow(
                                  abs(iResolution.y / 2. - ((fragCoord.y - iResolution.y / 2.) * 4. + iResolution.y /
                                      2.)), 2.)) / len);
                return float3(d * (1. + sin(theta * 10. + floor(_Time.y * 20.) * 10.77) * 0.5),
                              d * (1. + -cos(theta * 8. - floor(_Time.y * 20.) * 8.77) * 0.5),
                              d * (1. + -sin(theta * 6. - floor(_Time.y * 20.) * 134.77) * 0.5));
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 fragCoord = i.uv * _Resolution;
                float timescale = 4.;
                float3 c = float3(0, 0, 0);
                c += Strand(fragCoord, float3(1., 0, 0), 0.7934 + 1. + sin(_Time.y) * 30., 1., 0.16, 10. * timescale);
                c += Strand(fragCoord, float3(0., 1., 0.), 0.645 + 1. + sin(_Time.y) * 30., 1.5, 0.2, 10.3 * timescale);
                c += Strand(fragCoord, float3(0., 0., 1.), 0.735 + 1. + sin(_Time.y) * 30., 1.3, 0.19, 8. * timescale);
                c += Strand(fragCoord, float3(1., 1., 0.), 0.9245 + 1. + sin(_Time.y) * 30., 1.6, 0.14,
                            12. * timescale);
                c += Strand(fragCoord, float3(0., 1., 1.), 0.7234 + 1. + sin(_Time.y) * 30., 1.9, 0.23,
                            14. * timescale);
                c += Strand(fragCoord, float3(1., 0., 1.), 0.84525 + 1. + sin(_Time.y) * 30., 1.2, 0.18,
                            9. * timescale);
                c += clamp(Muzzle(fragCoord, timescale), 0., 1.);
                float4 fragColor = float4(c.r, c.g, c.b, 1.);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}