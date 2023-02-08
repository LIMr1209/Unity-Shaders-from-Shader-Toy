// https://www.shadertoy.com/view/3dsXWH
Shader "Unlit/ColorfulCellNoise"
{
    Properties
    {
         [Header(General)]
        [ToggleUI] _GammaCorrect ("Gamma Correction", Float) = 1
        _Resolution ("Resolution (Change if AA is bad)", Range(1, 1024)) = 1
         [ToggleUI] _ScreenEffect("ScreenEffect", Float) = 0
        
         [Header(Extracted)]
        _Speed("Speed", Range(0.1,10)) = 1
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
                float2 U;
                float t = _Time.y * _Speed / 3.;
                float2 R;
                if(_ScreenEffect)
                {
                    U = i.uv * _ScreenParams;
                    R = _ScreenParams.xy;
                }else
                {
                    U = i.uv * _Resolution;
                    R = iResolution.xy;
                }
                
                float2 uv = 1.25 * (U - 0.5 * R) / R.y;
                uv *= 5.;
                float2 id = floor(uv);
                float2 gv = frac(uv);
                float3 col = ((float3)0);
                float mD = 10.;
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