// https://www.shadertoy.com/view/3tBGRm
Shader "Unlit/UINoiseHalo"
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

            float3 hash33(float3 p3)
            {
                p3 = frac(p3 * float3(0.1031, 0.11369, 0.13787));
                p3 += dot(p3, p3.yxz + 19.19);
                return -1. + 2. * frac(float3(p3.x + p3.y, p3.x + p3.z, p3.y + p3.z) * p3.zyx);
            }

            float snoise3(float3 p)
            {
                const float K1 = 0.33333334;
                const float K2 = 0.16666667;
                float3 i = floor(p + (p.x + p.y + p.z) * K1);
                float3 d0 = p - (i - (i.x + i.y + i.z) * K2);
                float3 e = step(((float3)0.), d0 - d0.yzx);
                float3 i1 = e * (1. - e.zxy);
                float3 i2 = 1. - e.zxy * (1. - e);
                float3 d1 = d0 - (i1 - K2);
                float3 d2 = d0 - (i2 - K1);
                float3 d3 = d0 - 0.5;
                float4 h = max(0.6 - float4(dot(d0, d0), dot(d1, d1), dot(d2, d2), dot(d3, d3)), 0.);
                float4 n = h * h * h * h * float4(dot(d0, hash33(i)), dot(d1, hash33(i + i1)), dot(d2, hash33(i + i2)),
                                                  dot(d3, hash33(i + 1.)));
                return dot(((float4)31.316), n);
            }

            float4 extractAlpha(float3 colorIn)
            {
                float4 colorOut;
                float maxValue = min(max(max(colorIn.r, colorIn.g), colorIn.b), 1.);
                if (maxValue > 0.00001)
                {
                    colorOut.rgb = colorIn.rgb * (1. / maxValue);
                    colorOut.a = maxValue;
                }
                else
                {
                    colorOut = ((float4)0.);
                }
                return colorOut;
            }

            #define BG_COLOR (((float3)sin(_Time.y)*0.5+0.5)*0.+((float3)0.))
            #define time _Time.y
            static const float3 color1 = float3(0.611765, 0.262745, 0.996078);
            static const float3 color2 = float3(0.298039, 0.760784, 0.913725);
            static const float3 color3 = float3(0.062745, 0.078431, 0.6);
            static const float innerRadius = 0.6;
            static const float noiseScale = 0.65;

            float light1(float intensity, float attenuation, float dist)
            {
                return intensity / (1. + dist * attenuation);
            }

            float light2(float intensity, float attenuation, float dist)
            {
                return intensity / (1. + dist * dist * attenuation);
            }

            void draw(out float4 _FragColor, in float2 vUv)
            {
                _FragColor = 0;
                float2 uv = vUv;
                float ang = atan2(uv.y, uv.x);
                float len = length(uv);
                float v0, v1, v2, v3, cl;
                float r0, d0, n0;
                float r, d;
                n0 = snoise3(float3(uv * noiseScale, time * 0.5)) * 0.5 + 0.5;
                r0 = lerp(lerp(innerRadius, 1., 0.4), lerp(innerRadius, 1., 0.6), n0);
                d0 = distance(uv, r0 / len * uv);
                v0 = light1(1., 10., d0);
                v0 *= smoothstep(r0 * 1.05, r0, len);
                cl = cos(ang + time * 2.) * 0.5 + 0.5;
                float a = time * -1.;
                float2 pos = float2(cos(a), sin(a)) * r0;
                d = distance(uv, pos);
                v1 = light2(1.5, 5., d);
                v1 *= light1(1., 50., d0);
                v2 = smoothstep(1., lerp(innerRadius, 1., n0 * 0.5), len);
                v3 = smoothstep(innerRadius, lerp(innerRadius, 1., 0.5), len);
                float3 c = lerp(color1, color2, cl);
                float3 col = lerp(color1, color2, cl);
                col = lerp(color3, col, v0);
                col = (col + v1) * v2 * v3;
                col.rgb = clamp(col.rgb, 0., 1.);
                _FragColor = extractAlpha(col);
            }

            float4 frag(v2f i) : SV_Target
            {
                float4 fragColor = 0;
                float2 fragCoord = i.uv * _Resolution;
                float2 uv = (fragCoord * 2. - iResolution.xy) / iResolution.y;
                float4 col;
                draw(col, uv);
                float3 bg = BG_COLOR;
                fragColor.rgb = lerp(bg, col.rgb, col.a);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}