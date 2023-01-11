// https://www.shadertoy.com/view/ctXGRn
Shader "Unlit/ShootingStars "
{
    Properties
    {
        _Speed("Speed",Range(0.1,10.0)) = 1.0
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
            Blend SrcAlpha OneMinusSrcAlpha

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

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }


            fixed _Speed;


            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 fragColor;

                float2 fragCoord = float2(i.uv.x * _ScreenParams.x, i.uv.y * _ScreenParams.y);

                //Line dimensions (box) and position relative to line
                float2 b = float2(0, .2), p;
                //Rotation matrix
                float2x2 R;
                //Iterate 20 times
                // for (float i = .9; i++ < 20.;
                //          //Add attenuation
                //      fragColor += 1e-3 / length(clamp(p = R
                //                                       //Using rotated boxes
                //                                       * (frac((fragCoord / _ScreenParams.y * i * .1 + iTime * b) * R) -
                //                                           .5), -b, b) - p)
                //      //My favorite color palette
                //      * (cos(p.y / .1 + float4(0, 1, 2, 3)) + 1.))
                //     //Rotate for each iteration
                //     R = float2x2(cos(i + float4(0, 33, 11, 0)));

                for (float i = .9; i++ < 20.;
                         //Add attenuation
                     fragColor += 1e-3 / length(clamp(p = mul(R, frac(mul(fragCoord / _ScreenParams.y * i * .1 + _Time.y * b, R)) -
                                                          .5)
                                                      //Using rotated boxes
                                                      , -b, b) - p)
                     //My favorite color palette
                     * (cos(p.y / .1 + float4(0, 1, 2, 3)) + 1.))
                    //Rotate for each iteration
                    R = float2x2(cos(i + float4(0, 33, 11, 0)));
                return fragColor;
            }
            ENDCG
        }
    }
}