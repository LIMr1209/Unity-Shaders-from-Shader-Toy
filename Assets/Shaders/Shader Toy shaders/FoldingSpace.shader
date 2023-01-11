// https://www.shadertoy.com/view/mtsGDs
Shader "Unlit/FoldingSpace"
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

            #define ModFix(x, y) (x - y * floor(x / y))

            #define PI 3.141592654


            float uSin(float t) { return 0.5 + 0.5 * sin(t); }

            float3 palette(in float t, in float3 a, in float3 b, in float3 c, in float3 d)
            {
                return a + b * cos(6.28318 * (c * t + d));
            }

            float3x3 rot(float3 ang)
            {
                float3x3 x = float3x3(1.0, 0.0, 0.0, 0.0, cos(ang.x), -sin(ang.x), 0.0, sin(ang.x), cos(ang.x));
                float3x3 y = float3x3(cos(ang.y), 0.0, sin(ang.y), 0.0, 1.0, 0.0, -sin(ang.y), 0.0, cos(ang.y));
                float3x3 z = float3x3(cos(ang.z), -sin(ang.z), 0.0, sin(ang.z), cos(ang.z), 0.0, 0.0, 0.0, 1.0);
                return x * y * z;
            }

            float2x2 rot(float angle)
            {
                return float2x2(cos(angle), -sin(angle), sin(angle), cos(angle));
            }


            // Fold point p given the fold center and axis normal
            float3 opFold(float3 p, float3 c, float3 n)
            {
                float dist = max(0.0, dot(p - c, n));
                return p - (dist * n * 2.0);
            }

            float3 opRep(in float3 p, in float3 c)
            {
                float3 q = ModFix(p, c) - 0.5 * c;
                return q;
            }

            float sdBox(float3 p, float3 b)
            {
                float3 d = abs(p) - b;
                return length(max(d, 0.0)) +
                    min(max(d.x, max(d.y, d.z)), 0.0); // remove this line for an only partially signed sdf
            }


            float opSmoothUnion(float d1, float d2, float k)
            {
                float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
                return lerp(d2, d1, h) - k * h * (1.0 - h);
            }

            float3 map(in float3 p)
            {
                //float3 fold_normal = float3(1.0, 1.0, 1.0);
                //float3 fold_normal = float3(1.0, 0.0, 1.0) * rot(float3(u_time));
                int num_folds = 6;
                float3 rep = float3(28.0, 10.0, 28.0);
                float rep_index = floor(p.y / rep.y) / rep.y;
                //rep_index = sin(rep_index*2.0*PI);
                for (int i = 0; i < num_folds; i++)
                {
                    float fi = float(i) / float(num_folds);
                    //float3 fold_normal = float3(cos(fi*2.0*PI), (cos(fi*6.0*PI) + sin(fi*6.0*PI))*(sin(u_time)), sin(fi*2.0*PI));
                    float3 fold_normal = float3(cos(fi * 2.0 * PI), 0.0, sin(fi * 2.0 * PI));
                    fold_normal = normalize(fold_normal);
                    p = opFold(p, float3(0, 0, 0), fold_normal);
                }
                p = opRep(p, rep);

                int num_box = 8;
                float d = 10e7;
                float smooth_amt = 0.05;
                float box_size = 1.0 + 0.75 * sin(rep_index * 2.0 * PI + _Time.y);
                for (int i = 0; i < num_box; i++)
                {
                    float index = float(i) / float(num_box);
                    float3 polar_p = p;
                    polar_p.xz += 7.0 * float2(cos(index * 2.0 * PI + 2.0 * PI * rep_index),
                                               sin(index * 2.0 * PI + 2.0 * PI * rep_index)) * tan(
                        uSin(_Time.y + rep_index * PI * 3.0) * PI * 0.25 + 0.1 * PI);

                    float3 a = mul(rot(float3(_Time.y + index * 2.0 * PI, _Time.y + index * 1.0 * PI,
                                          _Time.y + index * 0.666 * PI)) , polar_p);

                    float curr_d = sdBox(a, float3(box_size, box_size, box_size));
                    //d = curr_d;
                    d = opSmoothUnion(d, curr_d, smooth_amt);
                    //d = curr_d;

                    //p *= 1.15 + 0.25*uSin(u_time*1.13);
                    //p.xz *= rot(u_time + index*2.0*PI);
                    //box_size *= 0.9;
                    //smooth_amt += 0.01*sin(u_time*2.2);
                }

                float3 result = float3(abs(d) + 0.005, rep_index, 1.0);

                return result;
            }

            float pcurve(float x, float a, float b)
            {
                float k = pow(a + b, a + b) / (pow(a, a) * pow(b, b));
                return k * pow(x, a) * pow(1.0 - x, b);
            }

            // https://learnopengl.com/Lighting/Light-casters
            float attenuation(float dist, float constant, float l, float quadratic)
            {
                return 1.0 / (constant + l * dist + quadratic * dist * dist);
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

            fixed4 frag(v2f i) : SV_Target
            {
                float2 q = i.uv;
                float2 p = -1. + 2. * q;
                p.x *= _ScreenParams.x / _ScreenParams.y;

                // Camera setup.
                float3 viewDir = float3(0.0, 1.0, 0.0);
                float3 cam_up = float3(0.0, 0.0, 1.0);
                float3 cam_pos = float3(0.0, -4.0, 0.0);
                float3 u = normalize(cross(viewDir, cam_up));
                float3 v = cross(u, viewDir);
                float3 vcv = cam_pos + viewDir;
                float3 srcCoord = vcv + p.x * u + p.y * v;
                float3 rayDir = normalize(srcCoord - cam_pos);

                float3 cA = float3(0.05, 0.7, 0.97);
                float3 cB = float3(0.5, 0.1, 0.5);
                float3 cC = float3(1.0, 1.0, 1.0);
                float3 cD = float3(0.4, 0.0, 0.7);

                float depth = 1.0;
                float d = 0.0;
                float3 pos = float3(0, 0, 0);
                float3 colorAcc = float3(0, 0, 0);
                bool hit = false;
                for (int i = 0; i < 48; i++)
                {
                    //pos = cam_pos + rayDir * depth;
                    //pos = cam_pos + rayDir * depth + float3(0.0, 25.0*u_time*0.159 + 25.0*pcurve(mod(u_time*0.159, 1.0), 3.0, 8.0), 0.0);
                    pos = cam_pos + rayDir * depth + float3(
                        0.0, 35.0 * floor(_Time.y * 1.459) + 35.0 * pow(ModFix(_Time.y * 1.459, 1.0), 3.0), 0.0);
                    // pos = pos * rot(float3(0.0, _Time.y, 0.0));
                    pos = mul(rot(float3(0.0, _Time.y, 0.0)), pos);
                    //pos = cam_pos + rayDir * depth + float3(0.0, 25.0*floor(u_time*1.159) + 25.0*smoothstep(0.0, 1.0, mod(u_time*1.159, 1.0)), 0.0);
                    //pos = cam_pos + rayDir * depth + float3(0.0, u_time*2.159, 0.0);
                    //pos = cam_pos + rayDir * depth + float3(0.0, u_time, 0.0);
                    //pos = cam_pos + rayDir * depth + float3(0.0, 75.0*u_time*0.459+75.0*smoothstep(0.0, 1.0, mod(u_time*0.459, 1.0)), 0.0);
                    float3 mapRes = map(pos);
                    d = mapRes.x;
                    if (abs(d) < 0.001)
                    {
                        hit = true;
                    }
                    colorAcc += exp(-abs(d) * (8.0 + 7.5 * sin(_Time.y))) * palette(
                        mapRes.y * 2.33 + pos.y * 0.2, cA, cB, cC, cD);
                    colorAcc *= (1.0 + attenuation(abs(d), 12.8, 8.0, 20.1) * palette(
                        mapRes.y + pos.y * 0.2, cA, cB, cC, cD));
                    depth += max(d * 0.5, 0.065);
                }
                //if (!hit) {
                colorAcc = colorAcc * 0.02;
                colorAcc *= (1.0 + attenuation(depth, 0.5, 0.1, 0.1));
                colorAcc -= float3(0.05 / exp(-depth * 0.01), 0.05 / exp(-depth * 0.01), 0.05 / exp(-depth * 0.01));
                //colorAcc -= 0.1/exp(depth*1.00);
                //}
                return float4(colorAcc, 1.0);
            }
            ENDCG
        }
    }
}