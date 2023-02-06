// https://www.shadertoy.com/view/3sKGWw
Shader "Unlit/MulticolouredStars"
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

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }


            float random(float2 p)
            {
                float3 p3 = frac(((float3)p.xyx)*0.1031);
                p3 += dot(p3, p3.yzx+33.33);
                return frac((p3.x+p3.y)*p3.z);
            }

            float2 random2(float2 p)
            {
                float3 p3 = frac(((float3)p.xyx)*float3(0.1031, 0.103, 0.0973));
                p3 += dot(p3, p3.yzx+33.33);
                return frac((p3.xx+p3.yz)*p3.zy);
            }

            float getGlow(float dist, float radius, float intensity)
            {
                return pow(radius/dist, intensity);
            }

            float4 frag (v2f i) : SV_Target
            {
                float2 fragCoord = i.uv * _Resolution;
                float t = 1.+_Time.y*0.06;
                float layers = 10.;
                float scale = 32.;
                float depth;
                float phase;
                float rotationAngle = _Time.y*-0.1;
                float size;
                float glow;
                float del = 1./layers;
                float2 uv;
                float2 fl;
                float2 local_uv;
                float2 index;
                float2 pos;
                float2 seed;
                float2 centre;
                float2 cell;
                float2 rot = float2(cos(t), sin(t));
                float2x2 rotation = transpose(float2x2(cos(rotationAngle), -sin(rotationAngle), sin(rotationAngle), cos(rotationAngle)));
                float3 col = ((float3)0);
                float3 tone;
                for (float i = 0.;i<=1.; i += del)
                {
                    depth = frac(i+t);
                    centre = rot*0.2*depth+0.5;
                    uv = centre-fragCoord/iResolution.x;
                    uv = mul(uv,rotation);
                    uv *= lerp(scale, 0., depth);
                    fl = floor(uv);
                    local_uv = uv-fl-0.5;
                    for (float j = -1.;j<=1.; j++)
                    {
                        for (float k = -1.;k<=1.; k++)
                        {
                            cell = float2(j, k);
                            index = fl+cell;
                            seed = 128.*i+index;
                            pos = cell+0.9*(random2(seed)-0.5);
                            phase = 128.*random(seed);
                            tone = float3(random(seed), random(seed+1.), random(seed+2.));
                            size = (0.1+0.5+0.5*sin(phase*t))*depth;
                            glow = size*getGlow(length(local_uv-pos), 0.07, 2.5);
                            col += 5.*((float3)0.02*glow)+tone*glow;
                        }
                    }
                }
                col = 1.-exp(-col);
                col = pow(col, ((float3)0.4545));
                float4 fragColor = float4(col, 1.);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}