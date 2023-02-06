// https://www.shadertoy.com/view/MscBRs
Shader "Unlit/VoxelTunnel"
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

            float2x2 r2d(float a)
            {
                float c = cos(a), s = sin(a);
                return transpose(float2x2(c, s, -s, c));
            }

            float2 path(float t)
            {
                float a = sin(t * 0.2 + 1.5), b = sin(t * 0.2);
                return float2(2. * a, a * b);
            }

            static float g = 0.;

            float de(float3 p)
            {
                p.xy -= path(p.z);
                float d = -length(p.xy) + 4.;
                p.xy += float2(cos(p.z + _Time.y) * sin(_Time.y), cos(p.z + _Time.y));
                p.z -= 6. + _Time.y * 6.;
                d = min(d, dot(p, normalize(sign(p))) - 1.);
                g += 0.015 / (0.01 + d * d);
                return d;
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 fragCoord = i.uv * _Resolution;
                float2 uv = fragCoord / iResolution.xy - 0.5;
                uv.x *= iResolution.x / iResolution.y;
                float dt = _Time.y * 6.;
                float3 ro = float3(0, 0, -5. + dt);
                float3 ta = float3(0, 0, dt);
                ro.xy += path(ro.z);
                ta.xy += path(ta.z);
                float3 fwd = normalize(ta - ro);
                float3 right = cross(fwd, float3(0, 1, 0));
                float3 up = cross(right, fwd);
                float3 rd = normalize(fwd + uv.x * right + uv.y * up);
                rd.xy = mul(rd.xy, r2d(sin(-ro.x / 3.14) * 0.3));
                float3 p = floor(ro) + 0.5;
                float3 mask;
                float3 drd = 1. / abs(rd);
                rd = sign(rd);
                float3 side = drd * (rd * (p - ro) + 0.5);
                float t = 0., ri = 0.;
                for (float i = 0.; i < 1.; i += 0.01)
                {
                    ri = i;
                    if (de(p) < 0.)
                        break;

                    mask = step(side, side.yzx) * step(side, side.zxy);
                    side += drd * mask;
                    p += rd * mask;
                }
                t = length(p - ro);
                float3 c = ((float3)1) * length(mask * float3(1., 0.5, 0.75));
                c = lerp(float3(0.2, 0.2, 0.7), float3(0.2, 0.1, 0.2), c);
                c += g * 0.4;
                c.r += sin(_Time.y) * 0.2 + sin(p.z * 0.5 - _Time.y * 6.);
                c = lerp(c, float3(0.2, 0.1, 0.2), 1. - exp(-0.001 * t * t));
                float4 fragColor = float4(c, 1.);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}