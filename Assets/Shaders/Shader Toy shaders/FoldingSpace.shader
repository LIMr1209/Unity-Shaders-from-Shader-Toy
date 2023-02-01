// https://www.shadertoy.com/view/mtsGDs
Shader "Unlit/FoldingSpace"
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
            #define iChannelResolution float4x4(                      \
                _MainTex_TexelSize.z,   _MainTex_TexelSize.w,   0, 0, \
                _SecondTex_TexelSize.z, _SecondTex_TexelSize.w, 0, 0, \
                _ThirdTex_TexelSize.z,  _ThirdTex_TexelSize.w,  0, 0, \
                _FourthTex_TexelSize.z, _FourthTex_TexelSize.w, 0, 0)

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv =  v.uv;
                return o;
            }

            #define PI 3.1415925
            float uSin(float t)
            {
                return 0.5+0.5*sin(t);
            }

            float3 palette(in float t, in float3 a, in float3 b, in float3 c, in float3 d)
            {
                return a+b*cos(6.28318*(c*t+d));
            }

            float3x3 rot(float3 ang)
            {
                float3x3 x = transpose(float3x3(1., 0., 0., 0., cos(ang.x), -sin(ang.x), 0., sin(ang.x), cos(ang.x)));
                float3x3 y = transpose(float3x3(cos(ang.y), 0., sin(ang.y), 0., 1., 0., -sin(ang.y), 0., cos(ang.y)));
                float3x3 z = transpose(float3x3(cos(ang.z), -sin(ang.z), 0., sin(ang.z), cos(ang.z), 0., 0., 0., 1.));
                return mul(mul(x,y),z);
            }

            float2x2 rot(float angle)
            {
                return transpose(float2x2(cos(angle), -sin(angle), sin(angle), cos(angle)));
            }

            float3 opFold(float3 p, float3 c, float3 n)
            {
                float dist = max(0., dot(p-c, n));
                return p-dist*n*2.;
            }

            float3 opRep(in float3 p, in float3 c)
            {
                float3 q = glsl_mod(p, c)-0.5*c;
                return q;
            }

            float sdBox(float3 p, float3 b)
            {
                float3 d = abs(p)-b;
                return length(max(d, 0.))+min(max(d.x, max(d.y, d.z)), 0.);
            }

            float opSmoothUnion(float d1, float d2, float k)
            {
                float h = clamp(0.5+0.5*(d2-d1)/k, 0., 1.);
                return lerp(d2, d1, h)-k*h*(1.-h);
            }

            float3 map(in float3 p)
            {
                int num_folds = 6;
                float3 rep = float3(28., 10., 28.);
                float rep_index = floor(p.y/rep.y)/rep.y;
                for (int i = 0;i<num_folds; i++)
                {
                    float fi = float(i)/float(num_folds);
                    float3 fold_normal = float3(cos(fi*2.*PI), 0., sin(fi*2.*PI));
                    fold_normal = normalize(fold_normal);
                    p = opFold(p, ((float3)0.), fold_normal);
                }
                p = opRep(p, rep);
                int num_box = 8;
                float d = 100000000.;
                float smooth_amt = 0.05;
                float box_size = 1.+0.75*sin(rep_index*2.*PI+_Time.y);
                for (int i = 0;i<num_box; i++)
                {
                    float index = float(i)/float(num_box);
                    float3 polar_p = p;
                    polar_p.xz += 7.*float2(cos(index*2.*PI+2.*PI*rep_index), sin(index*2.*PI+2.*PI*rep_index))*tan(uSin(_Time.y+rep_index*PI*3.)*PI*0.25+0.1*PI);
                    float curr_d = sdBox(mul(rot(float3(_Time.y+index*2.*PI, _Time.y+index*1.*PI, _Time.y+index*0.666*PI)),polar_p), ((float3)box_size));
                    d = opSmoothUnion(d, curr_d, smooth_amt);
                }
                float3 result = float3(abs(d)+0.005, rep_index, 1.);
                return result;
            }

            float pcurve(float x, float a, float b)
            {
                float k = pow(a+b, a+b)/(pow(a, a)*pow(b, b));
                return k*pow(x, a)*pow(1.-x, b);
            }

            float attenuation(float dist, float constant, float linear_, float quadratic)
            {
                return 1./(constant+linear_*dist+quadratic*dist*dist);
            }

            float4 frag (v2f i) : SV_Target
            {
                float2 fragCoord = i.uv * _Resolution;
                float2 q = fragCoord.xy/iResolution.xy;
                float2 p = -1.+2.*q;
                p.x *= iResolution.x/iResolution.y;
                float3 viewDir = float3(0., 1., 0.);
                float3 cam_up = float3(0., 0., 1.);
                float3 cam_pos = float3(0., -4., 0.);
                float3 u = normalize(cross(viewDir, cam_up));
                float3 v = cross(u, viewDir);
                float3 vcv = cam_pos+viewDir;
                float3 srcCoord = vcv+p.x*u+p.y*v;
                float3 rayDir = normalize(srcCoord-cam_pos);
                float3 cA = float3(0.05, 0.7, 0.97);
                float3 cB = float3(0.5, 0.1, 0.5);
                float3 cC = float3(1., 1., 1.);
                float3 cD = float3(0.4, 0., 0.7);
                float4 c = float4(0., 0., 0., 1.);
                float depth = 1.;
                float d = 0.;
                float3 pos = ((float3)0);
                float3 colorAcc = ((float3)0);
                bool hit = false;
                for (int i = 0;i<48; i++)
                {
                    pos = cam_pos+rayDir*depth+float3(0., 35.*floor(_Time.y*1.459)+35.*pow(glsl_mod(_Time.y*1.459, 1.), 3.), 0.);
                    pos = mul(pos,rot(float3(0., _Time.y, 0.)));
                    float3 mapRes = map(pos);
                    d = mapRes.x;
                    if (abs(d)<0.001)
                    {
                        hit = true;
                    }
                    
                    colorAcc += exp(-abs(d)*(8.+7.5*sin(_Time.y)))*palette(mapRes.y*2.33+pos.y*0.2, cA, cB, cC, cD);
                    colorAcc *= 1.+attenuation(abs(d), 12.8, 8., 20.1)*palette(mapRes.y+pos.y*0.2, cA, cB, cC, cD);
                    depth += max(d*0.5, 0.065);
                }
                colorAcc = colorAcc*0.02;
                colorAcc *= 1.+attenuation(depth, 0.5, 0.1, 0.1);
                colorAcc -= ((float3)0.05/exp(-depth*0.01));
                float4 fragColor = float4(colorAcc, 1.);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}