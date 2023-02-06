// https://www.shadertoy.com/view/ldKGDd
Shader "Unlit/2DParallaxStarfield  "
{
    Properties
    {
        [Header(General)]
        _MainTex ("iChannel0", 2D) = "white" {}
        [ToggleUI] _GammaCorrect ("Gamma Correction", Float) = 1
        _Resolution ("Resolution (Change if AA is bad)", Range(1, 1024)) = 1
        _Mouse ("Mouse", Vector) = (0.5, 0.5, 0.5, 0.5)

        [Header(Extracted)]
        SPEED ("SPEED", Float) = 0.1
        STAR_NUMBER ("STAR_NUMBER", Float) = 300
        ITER ("ITER", Float) = 4

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
            sampler2D _MainTex;
            float4 _MainTex_TexelSize;
            
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

            float SPEED;
            float STAR_NUMBER;
            float ITER;
            static float3 col1 = float3(155., 176., 255.) / 256.;
            static float3 col2 = float3(255., 204., 111.) / 256.;

            float rand(float i)
            {
                return frac(sin(dot(float2(i, i), float2(32.9898, 78.233))) * 43758.547);
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 fragCoord = i.uv * _Resolution;
                float2 uv = fragCoord / iResolution.y;
                float res = iResolution.x / iResolution.y;
                float4 fragColor = ((float4)0.);
                float4 sStar = ((float4)rand(uv.x * uv.y));
                sStar *= pow(rand(uv.x * uv.y), 200.);
                sStar.xyz *= lerp(col1, col2, rand(uv.x + uv.y));
                fragColor += sStar;
                float4 col = 0.5 - ((float4)length(float2(uv.x, 0.5) - uv));
                col.xyz *= lerp(col1, col2, 0.75);
                fragColor += col * 2.;
                float c = 0.;
                float c2 = 0.;
                float2 rv = uv;
                rv.x -= _Time.y * SPEED * 0.25;
                for (int i = 0; i < ITER; i++)
                    c += (tex2D(_MainTex, rv * 0.25 + rand(float(i + 10) + uv.x * uv.y) * (16. / iResolution.y)) /
                        float(ITER)).x;
                fragColor -= c * 0.5;
                fragColor = clamp(fragColor, 0., 1.);
                for (int i = 0; i < STAR_NUMBER; ++i)
                {
                    float n = float(i);
                    float3 pos = float3(rand(n) * res + (_Time.y + 100.) * SPEED, rand(n + 1.), rand(n + 2.));
                    pos.x = glsl_mod(pos.x*pos.z, res);
                    pos.y = (pos.y + rand(n + 10.)) * 0.5;
                    float4 col = ((float4)pow(length(pos.xy - uv), -1.25) * 0.001 * pos.z * rand(n + 3.));
                    col.xyz *= lerp(col1, col2, rand(n + 4.));
                    col.xyz *= lerp(rand(n + 5.), 1., abs(cos(_Time.y * rand(n + 6.) * 5.)));
                    fragColor += ((float4)col);
                }
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}