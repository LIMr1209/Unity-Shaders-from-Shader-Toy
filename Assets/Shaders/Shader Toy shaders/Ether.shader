// https://www.shadertoy.com/view/MsjSW3
Shader "Unlit/Ether"
{
    Properties
    {
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
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"


            #define POINT_COUNT 8

            float2x2 m(float a)
            {
                float c = cos(a), s = sin(a);
                return float2x2(c, -s, s, c);
            }

            float map(float3 p)
            {
                p.xz *= mul(m(_Time.y * 0.4), p.xz);
                p.xy *= mul(m(_Time.y * 0.3), p.xy);
                float3 q = p * 2. + _Time.y;
                float a = sin(_Time.y * 0.7);
                return length(p + float3(a,a,a)) * log(length(p) + 1.) + sin(q.x + sin(q.z + sin(q.y))) * 0.5 - 1.;
            }


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


            fixed4 frag(v2f i) : SV_Target
            {
                float2 fragCoord = float2(i.uv.x * _ScreenParams.x, i.uv.y * _ScreenParams.y);
                float2 p = fragCoord.xy / _ScreenParams.y - float2(.9, .5);
                float3 cl = float3(0,0,0);
                float d = 2.5;
                for (int i = 0; i <= 5; i++)
                {
                    float3 q = float3(0, 0, 5.) + normalize(float3(p, -1)) * d;
                    float rz = map(q);
                    float f = clamp((rz - map(q + .1)) * 0.5, -.1, 1.);
                    float3 l = float3(0.1, 0.3, .4) + float3(5., 2.5, 3.) * f;
                    cl = cl * l + smoothstep(2.5, .0, rz) * .7 * l;
                    d += min(rz, 1.);
                }
                return float4(cl, 1.);
            }
            ENDCG
        }
    }
}