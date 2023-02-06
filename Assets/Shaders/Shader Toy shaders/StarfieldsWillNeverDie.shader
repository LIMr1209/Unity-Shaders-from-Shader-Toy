// https://www.shadertoy.com/view/MtKBWw
Shader "Unlit/StarfieldsWillNeverDie"
{
    Properties
    {
        [Header(General)]
        [ToggleUI] _GammaCorrect ("Gamma Correction", Float) = 1
        _Resolution ("Resolution (Change if AA is bad)", Range(1, 1024)) = 1
        _Mouse ("Mouse", Vector) = (0.5, 0.5, 0.5, 0.5)

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


            float3 hsv(float h, float s, float v)
            {
                float4 K = float4(1., 2. / 3., 1. / 3., 3.);
                float3 p = abs(frac(((float3)h) + K.xyz) * 6. - K.www);
                return v * lerp(K.xxx, clamp(p - K.xxx, 0., 1.), s);
            }

            float rand(float2 co)
            {
                return frac(sin(dot(co.xy, float2(12.9898, 78.233))) * 43758.547);
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 fragCoord = i.uv * _Resolution;
                float2 p = (2. * fragCoord.xy - iResolution.xy) / min(iResolution.x, iResolution.y);
                float3 v = float3(p, 1. - length(p) * 0.2);
                float ta = _Time.y * 0.1;
                float3x3 m = transpose(float3x3(0., 1., 0., -sin(ta), 0., cos(ta), cos(ta), 0., sin(ta)));
                m = mul(mul(m, m), m);
                m = mul(m, m);
                v = mul(m, v);
                float a = atan2(v.y, v.x) / 3.141592 / 2. + 0.5;
                float slice = floor(a * 1000.);
                float phase = rand(float2(slice, 0.));
                float dist = rand(float2(slice, 1.)) * 3.;
                float hue = rand(float2(slice, 2.));
                float z = dist / length(v.xy) * v.z;
                float Z = glsl_mod(z+phase+_Time.y*0.6, 1.);
                float d = sqrt(z * z + dist * dist);
                float c = exp(-Z * 8. + 0.3) / (d * d + 1.);
                float4 fragColor = float4(hsv(hue, 0.6 * (1. - clamp(2. * c - 1., 0., 1.)), clamp(2. * c, 0., 1.)), 1.);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}