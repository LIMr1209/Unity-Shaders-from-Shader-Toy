// https://www.shadertoy.com/view/Mdt3Df
Shader "Unlit/Snow"
{
    Properties
    {
        [Header(General)]
        [ToggleUI] _GammaCorrect ("Gamma Correction", Float) = 1
        _Resolution ("Resolution (Change if AA is bad)", Range(1, 1024)) = 1
        [ToggleUI] _ScreenEffect("ScreenEffect", Float) = 0

        [Header(Extracted)]
        _DownSpeed("DownSpeed",Range(0.1,10.0)) = 1.0
        _LayerNum("LayerNum", range(1,50)) = 6
        _SnowNum("SnowNum", range(1,50)) = 12
        _BackGroundColor("BackGroundColor", Color) = (0.4, 0.8, 1.0, 0.0)
        _MainColor("MainColor", Color) = (1,1,1,1)
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
                fixed4 vertex : POSITION;
                fixed2 uv : TEXCOORD0;
            };

            struct v2f
            {
                fixed2 uv : TEXCOORD0;
                fixed4 vertex : SV_POSITION;
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


            fixed _DownSpeed;
            fixed _LayerNum;
            fixed _SnowNum;
            fixed4 _BackGroundColor;
            fixed4 _MainColor;


            fixed4 frag(v2f i) : SV_Target
            {
                float2 fragCoord;
                float2 p;
                if(_ScreenEffect)
                {
                     fragCoord = i.uv * _ScreenParams;
                     p = fragCoord.xy / _ScreenParams.x;
                }
                else
                {
                    fragCoord = i.uv * iResolution;
                    p = fragCoord.xy / iResolution.x;
                }
               
                float snow = 0.0;
                float gradient = (1.0 - float(i.uv.x)) * 0.4;
                float random = frac(sin(dot(fragCoord.xy, float2(12.9898, 78.233))) * 43758.5453);
                for (int k = 0; k < _LayerNum; k++)
                {
                    for (int i = 0; i < _SnowNum; i++)
                    {
                        float cellSize = 2.0 + (float(i) * 3.0);
                        float downSpeed = 0.3 + (sin(_Time.y * _DownSpeed * 0.4 + float(k + i * 20)) + 1.0) * 0.00008;
                        float2 uv = (fragCoord.xy / _ScreenParams.x) + float2(
                            0.01 * sin((_Time.y + float(k * 6185)) * 0.6 + float(i)) * (5.0 / float(i)),
                            downSpeed * (_Time.y + float(k * 1352)) * (1.0 / float(i)));
                        float2 uvStep = (ceil((uv) * cellSize - float2(0.5, 0.5)) / cellSize);
                        float x = frac(
                            sin(dot(uvStep.xy, float2(12.9898 + float(k) * 12.0, 78.233 + float(k) * 315.156))) *
                            43758.5453 + float(k) * 12.0) - 0.5;
                        float y = frac(
                            sin(dot(uvStep.xy, float2(62.2364 + float(k) * 23.0, 94.674 + float(k) * 95.0))) *
                            62159.8432
                            + float(k) * 12.0) - 0.5;

                        float randomMagnitude1 = sin(_Time.y * 2.5) * 0.7 / cellSize;
                        float randomMagnitude2 = cos(_Time.y * 2.5) * 0.7 / cellSize;

                        float d = 5.0 * distance(
                            (uvStep.xy + float2(x * sin(y), y) * randomMagnitude1 + float2(y, x) * randomMagnitude2),
                            uv.xy);

                        float omiVal = frac(sin(dot(uvStep.xy, float2(32.4691, 94.615))) * 31572.1684);
                        if (omiVal < 0.08 ? true : false)
                        {
                            float newd = (x + 1.0) * 0.4 * clamp(1.9 - d * (15.0 + (x * 6.3)) * (cellSize / 1.4), 0.0,
                                                                 1.0);
                            snow += newd;
                        }
                    }
                }


                return float4(snow, snow, snow, snow) * _MainColor + gradient * _BackGroundColor.rgba + random * 0.01;
            }
            ENDCG
        }
    }
}