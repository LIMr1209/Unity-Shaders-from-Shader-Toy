// https://www.shadertoy.com/view/3dsXWH
Shader "Unlit/ColorfulCellNoise"
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

            #define PI 3.141592

            float2 random2(float2 p)
            {
                return frac(sin(float2(dot(p, float2(127.1, 311.7)), dot(p, float2(269.5, 183.3)))) * 43758.547);
            }

            float cubicInOut(float t)
            {
                return t < 0.5 ? 4. * t * t * t : 0.5 * pow(2. * t - 2., 3.) + 1.;
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 U = i.uv * _Resolution;
                float t = _Time.y / 3.;
                float2 R = iResolution.xy;
                float2 uv = 1.25 * (U - 0.5 * R) / R.y;
                uv *= 5.;
                float2 id = floor(uv);
                float2 gv = frac(uv);
                float3 col = ((float3)0);
                float mD = 10.;
                float2 thisPoint = random2(id);
                float2 cellID = float2(0, 0);
                for (int k = 0; k < 25; k++)
                {
                    float2 offs = float2(k % 5 - 2, k / 5 - 2);
                    float2 neighborPos = random2(id + offs) + offs;
                    neighborPos += cos(2. * t + 6.2831 * neighborPos);
                    float2 diff = gv - neighborPos;
                    float d = length(diff);
                    if (mD > d)
                    {
                        mD = d;
                        cellID = frac(neighborPos);
                    }
                }
                float3 colorGrad = 1.5 * float3(smoothstep(-5., 5., uv.x), 0, smoothstep(5., -5., uv.x));
                float3 cellGrad = float3(0, sin(PI * cellID.y), 0);
                float3 mixStuff = colorGrad;
                float3 mixed = lerp(cellGrad, colorGrad, colorGrad);
                col += smoothstep(1.5, 0., mD) * mixed;
                float4 fragColor = float4(col, 1.);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}