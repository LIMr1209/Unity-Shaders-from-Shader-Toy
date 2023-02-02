// https://www.shadertoy.com/view/clsGDn
Shader "Unlit/Starfield"
{
    Properties
    {
        _MainColor("MainColor", Color) = (7, 8, 9, 0)
        _Speed("Speed",Range(0.1,10.0)) = 1.0
        _PointNum("PointNum", int) = 5
        [ToggleUI] _GammaCorrect ("Gamma Correction", Float) = 1
        _Resolution ("Resolution (Change if AA is bad)", Range(1, 1024)) = 1
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Transparent" "Queue" = "Transparent"
        }
        LOD 100

        Pass
        {
            ZWrite Off
//            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float _GammaCorrect;
            float _Resolution;

            #define iResolution float3(_Resolution, _Resolution, _Resolution)

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

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }


            fixed _Speed;
            fixed4 _MainColor;
            int _PointNum;


            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 fragColor;

                //Relative star position
                float2 p;
                       //Resolution for scaling and centering
                float2 r = iResolution.xy;

                float2 fragCoord = i.uv * iResolution;

                for (float i = 0., f; i++ < 1e1;
                     //Fade toward back and attenuate lighting
                 fragColor += (1e1 - f) / max(length(p = fmod(mul(float2x2(cos(i + float4(0, 33, 11, 0))), (fragCoord + fragCoord - r) / r.y * f ), 2.) - 1.)
                                              //Make 5 pointed-stars
                                              + cos(atan2(p.x, p.y) * _PointNum + _Time.y * _Speed * cos(i)) / 3e1
                                              //Blue tint
                                              - _MainColor / 6e1, .01) / 8e2)

                //Compute distance to back
                f = fmod(i - _Time.y, 1e1);

                return fragColor;
            }
            ENDCG
        }
    }
}