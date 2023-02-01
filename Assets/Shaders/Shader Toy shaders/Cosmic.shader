// https://www.shadertoy.com/view/msjXRK
Shader "Unlit/Cosmic"
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
            
            // Global access to uv data
            static v2f vertex_output;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv =  v.uv;
                return o;
            }

            float4 frag (v2f __vertex_output) : SV_Target
            {
                vertex_output = __vertex_output;
                vertex_output.uv.y = 1 - vertex_output.uv.y;
                vertex_output.uv.x = 1 - vertex_output.uv.x;
                float4 O = 0;
                float2 I = vertex_output.uv * _Resolution;
                O *= 0.;
                float2 r = iResolution.xy, p = mul(I-r*0.6,transpose(float2x2(1, -1, 2, 2)));
                for (float i = 0., a;i++<30.; O += 0.2/(abs(length(I = p/(r+r-p).y)*80.-i)+40./r.y)*clamp(cos(a = atan2(I.y, I.x)*ceil(i*0.1)+_Time.y*sin(i*i)+i*i), 0., 0.6)*(cos(a-i+float4(0, 1, 2, 0))+1.))
                ;
                if (_GammaCorrect) O.rgb = pow(O.rgb, 2.2);
                return O;
            }
            ENDCG
        }
    }
}

