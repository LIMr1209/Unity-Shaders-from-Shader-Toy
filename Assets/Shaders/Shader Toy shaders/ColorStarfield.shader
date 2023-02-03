// https://www.shadertoy.com/view/MtG3DR
Shader "Unlit/ColorStarfield "
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
            Cull Off

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

            #define PI 3.141592             
            #define TIMER(sec, min, max) (glsl_mod(_Time.y, sec)*(max-min)/sec+min)
            float2x2 mm2(in float a)
            {
                float c = cos(a), s = sin(a);
                return transpose(float2x2(c, s, -s, c));
            }

            float4 frag (v2f i) : SV_Target
            {
                float2 fragCoord = i.uv * _Resolution;
                float2 uv = fragCoord.xy/iResolution.xy-((float2)0.5);
                uv.x *= iResolution.x/iResolution.y;
                float2 mouse = _Mouse.xy;
                if (!all((mouse) == (((float2)0.))))
                {
                    mouse = float2(mouse.x/iResolution.x-0.5, mouse.y/iResolution.y-0.5);
                    mouse.x *= iResolution.x/iResolution.y;
                }
                
                float3 color = ((float3)0.);
                float3 ray = float3(uv-mouse, 0.75);
                ray.xy = mul(ray.xy,mm2(TIMER(15., 0., -PI*2.)));
                float3 s = ray/max(abs(ray.x), abs(ray.y))*0.4;
                float3 p = s;
                for (int i = 0;i<5; i++)
                {
                    float2 nos1 = ((float2)floor(p.xy*30.334));
                    const float2 nos2 = float2(12.9898, 78.233);
                    const float nos3 = 43758.547;
                    float3 nc = float3(frac(sin(dot(nos1, nos2))*nos3), frac(sin(dot(nos1, nos2*0.5))*nos3), frac(sin(dot(nos1, nos2*0.25))*nos3));
                    float n = frac(sin(dot(nos1, nos2*2.))*nos3);
                    float z = frac(cos(n)-sin(n)-_Time.y*0.2);
                    float d = 1.-abs(30.*z-p.z);
                    float sz = 1./s.z;
                    float3 c = float3(sin(max(0., d*(sz*nc.r))), sin(max(0., d*(sz*nc.g))), sin(max(0., d*(sz*nc.b))));
                    color += (1.-z)*c;
                    p += s;
                }
                float4 fragColor = float4(max(((float3)0.), min(((float3)1.), color)), 1.);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}