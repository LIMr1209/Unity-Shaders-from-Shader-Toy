// https://www.shadertoy.com/view/7lyBRR
Shader "Unlit/Stars"
{
    Properties
    {
        [Header(General)]
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
            #define iResolution float3(_Resolution, _Resolution, _Resolution)

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv =  v.uv;
                return o;
            }

            
            float4 frag (v2f i) : SV_Target
            {
                float4 O = 0;
                float2 I = i.uv * _Resolution;
                O *= 0.;
                for (float i = 1.;i++<50.; )
                O += (i*cos(i+float4(0, 2, 4, 0))+i)/10000./length(frac(I/iResolution.y*20./i+_Time.y*0.2+cos(i*float2(9, 7)))-0.5);
                O *= O;
                if (_GammaCorrect) O.rgb = pow(O.rgb, 2.2);
                return O;
            }
            ENDCG
        }
    }
}
