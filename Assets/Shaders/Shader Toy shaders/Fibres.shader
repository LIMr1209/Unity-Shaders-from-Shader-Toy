// https://www.shadertoy.com/view/dlfGDn
Shader "Unlit/Fibres"
{
    Properties
    {
        _Speed("Speed",Range(0.1,10.0)) = 1.0
        _NoiseTex ("NoiseTex", 2D) = "white" {}
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

            float _Speed;
            sampler2D _NoiseTex;
            float4 _NoiseTex_ST;

            float4 pointColor(float3 p, float t)
            {
                // Translate
                p.xy += float2(cos(2.1 * p.z), sin(1.5 * p.z));
                // Scale
                p.xy *= 1. + .3 * sin(1.1 * p.z);
                // Random opacity
                float op = tex2D(_NoiseTex, .1 * p.xy).r;
                // Pulse
                float pulse = smoothstep(4., 5., fmod(p.z + 6. * _Time.y + op, 5.));
                op = lerp(op, 1., pulse);

                // Tube shape
                float l = length(p.xy);
                op *= smoothstep(.5, .3, l);

                // Random color
                float3 col = (.5 + .5 * pulse) * (.5 + .5 * cos(
                    float3(1, 2, 3) + .8 * cos(10. * float3(1, 2, 3) * p.xyy) + .5 * p.z));

                return float4(col, pow(op, 2.));
            }

            // Accumulates colors of points along the ray
            // depending on their opacities.
            float3 rayColor(float3 ro, float3 rd)
            {
                const float dt = .01;
                float3 color = float3(0,0,0);
                float tr = 1.;
                float t = dt * tex2D(_NoiseTex, rd.xy).r;

                // [unroll(500)]
                [loop]
                for (; t < 3.; t += dt)
                {
                    float4 pc = pointColor(ro + t * rd, t);

                    // More transparent close to camera
                    float fade = .5 + .5 * smoothstep(0., .7, t);
                    pc.a *= fade;

                    float da = pow(max(1. - pc.a, 0.), dt);
                    color += 2. * pc.rgb * tr * (1. - da);
                    tr *= da;
                    if (tr < .001)break;
                }
                // Background color
                float3 p = ro + 3. * rd;
                float x = smoothstep(.5, 1., sin(10. * length(p.xy - float2(-cos(2.1 * p.z), -sin(1.5 * p.z)))));
                color += lerp(float3(0, 0, .02), float3(0, 0, .06), x) * tr;
                return color;
            }

            float3x3 viewMatrix(float3 forward, float3 up)
            {
                float3 w = -normalize(forward);
                float3 u = cross(up, w);
                float3 v = cross(w, u);
                return float3x3(u, v, w);
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
                float t = 2. * _Time.y;

                float3 cam = float3(-.5 * sin(_Time.y), 0., -t);
                float3 forward = float3(.5 * sin(_Time.y), 0, -1.);
                // if (iMouse.z > 0.)
                // {
                //     float a = 2. * iMouse.x / _ScreenParams.x - 1.;
                //     float b = 2. * iMouse.y / _ScreenParams.y - 1.;
                //     forward = float3(sin(a) * cos(b), sin(b), -cos(a) * cos(b));
                // }

                float2 fragCoord = float2(i.uv.x * _ScreenParams.x, i.uv.y * _ScreenParams.y);

                float3 up = float3(0, 1, 0);
                float3x3 m = viewMatrix(forward, up);

                float2 uv = 1.5 * (fragCoord - .5 * _ScreenParams.xy) / _ScreenParams.y;
                float3 dir = mul(normalize(float3(uv, -1)), m);

                float3 col = rayColor(cam, dir);

                col = pow(col, float3(1. / 2.2, 1. / 2.2, 1. / 2.2));
                float4 fragColor = float4(col, 1.0);
                return fragColor;
            }
            ENDCG
        }
    }
}