// https://www.shadertoy.com/view/cll3WH
Shader "Unlit/DreamyStarField"
{
    Properties
    {
        _Speed("Speed",Range(0.1,10.0)) = 1.0
        _NoiseTex ("NoiseTex", 2D) = "white" {}
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
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            #define TWOPI 6.2831852
            #define LAYERS 8.0
            #define MAXOFFSET 0.8
            #define HALF_SQRT2 0.7071


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

            float3 pal(in float t, in float3 a, in float3 b, in float3 c, in float3 d)
            {
                return a + b * cos(TWOPI * (c * t + d));
            }

            float2x2 rot(float angle)
            {
                return float2x2(cos(angle), sin(angle), -sin(angle), cos(angle));
            }

            // feature need to have return value 0 for r>=1.0 and max value =1.0
            float feature(float2 r_theta)
            {
                float feature = max(1.0 - r_theta.x, 0.0);
                feature -= 0.25 * pow(cos(r_theta.y * 5.0) + 2.8, r_theta.x * 2.0);
                return pow(max(feature, 0.0), 1.0);
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


            fixed _Speed;
            sampler2D _NoiseTex;
            float4 _NoiseTex_ST;


            fixed4 frag(v2f i) : SV_Target
            {
                float2 fragCoord = i.uv * _Resolution;
                float2 uv = fragCoord/iResolution.xy;
                uv = uv*2.-1.;
                uv.y /= iResolution.x/iResolution.y;
                float3 sum = ((float3)0.);
                float scale = 1.;
                for (float i = 0.;i<LAYERS; ++i)
                {
                    float2 _uv = uv*0.5/HALF_SQRT2;
                    _uv = mul(_uv,rot(i*2.))+float2(0.03, 0.04)*i;
                    scale = glsl_mod(i-_Time.y*0.3 * _Speed, LAYERS);
                    _uv *= scale;
                    float2 idx = trunc(_uv+((float2)LAYERS));
                    _uv = glsl_mod(_uv, 1.);
                    _uv = _uv*2.-1.;
                    float3 noise = 2.*tex2D(_NoiseTex, (idx+i)*0.07).rgb-1.;
                    noise.xy *= MAXOFFSET;
                    float2 margin = ((float2)1.)-abs(noise.xy);
                    float zoomScale = min(margin.x, margin.y);
                    zoomScale = lerp(0.3, zoomScale*0.5, (noise.z+1.)*0.5);
                    float2 local_uv = (_uv+noise.xy)/zoomScale;
                    float2 r_theta = float2(length(local_uv), atan2(local_uv.y, local_uv.x));
                    r_theta.y += sin(_Time.y*_Speed * noise.z+noise.y*5.)*noise.x*20.;
                    float3 color = pal(idx.x*idx.y/10.+_Time.y * _Speed *noise.z*3., float3(0.5, 0.5, 0.5), float3(0.5, 0.5, 0.5), float3(1., 1., 1.), float3(0., 0.1, 0.2));
                    sum += feature(r_theta)*color*(LAYERS-scale)/LAYERS*(noise.x+3.);
                }
                float4 fragColor = float4(pow(sum*1.5, ((float3)1.8/2.2)), 1.);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}