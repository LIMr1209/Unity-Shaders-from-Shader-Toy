// https://www.shadertoy.com/view/dl23WR
Shader "Unlit/BirthdayBalloons"
{
    Properties
    {
        [Header(General)]
        _MainTex ("iChannel0", 2D) = "white" {}
        [ToggleUI] _GammaCorrect ("Gamma Correction", Float) = 1
        _Resolution ("Resolution (Change if AA is bad)", Range(1, 1024)) = 1
        [ToggleUI] _ScreenEffect("ScreenEffect", Float) = 0

        [Header(Extracted)]
        _Speed("Speed", range(0.1,10)) = 1
    }

    CGINCLUDE
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
    sampler2D _MainTex;
    float4 _MainTex_TexelSize;
    float _GammaCorrect;
    float _Resolution;
    float _ScreenEffect;

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
    ENDCG


    SubShader
    {
        Pass
        {
            CGPROGRAM
            float _Speed;
            #define LAYERS 3
            #define DENSITY float2(1., 2.)
            #define THRESSHOLD 0.2
            #define PI 3.1415
            #define L(u) length(u)
            #define S(p, r) smoothstep(20./R.y, 0., L(uv-p)-r)

            float h(float2 d)
            {
                float2 r = frac(d * float2(123.23, 234.534));
                r += dot(r, r + 23.4);
                return frac(r.x * r.y);
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 U;
                float2 R;
                float2 NUV;
                float2 u;
                if (_ScreenEffect)
                {
                    u = i.uv * _ScreenParams;
                    R = _ScreenParams.xy,
                        NUV = u / _ScreenParams.xy;
                }
                else
                {
                    u = i.uv * iResolution;
                    R = iResolution.xy,
                        NUV = u / iResolution.xy;
                }

                U = (u - R.xy / 2.) / R.y;
                float3 col = ((float3)0);
                float gM = 0., t = _Time.y * _Speed + PI;
                for (float i = float(LAYERS); i > 0.; i -= 1.)
                {
                    float2 uv = U * 6. * i;
                    uv.y -= t * (h(floor(uv).xx) * 0.3 + 0.5);
                    float2 d = floor(uv * (1. / DENSITY));
                    if (h(d + 21.) >= THRESSHOLD)
                    {
                        uv = glsl_mod(uv, DENSITY) - DENSITY / float2(DENSITY.x * 2., 2.);
                        float r = h(d), ss = 4.125 * (r + 0.5);
                        uv += ((float2)clamp(r, 0.05, 0.25)) * float2(sin(r * t) * 0.5, cos(r * t) * 1.5);
                        uv *= ss;
                        float sig = sign(uv.y);
                        float2 uv2 = 2. * uv - float2(0., -3.4);
                        float f = step(lerp(1., L(float2(abs(uv2.x)+1.*uv2.y, uv2.y*0.9)), max(0., -sig)), 0.3);
                        uv.y = lerp(uv.y * 0.6, uv.y, max(0., sig));
                        float lM = S(((float2)0.), 1.) + f;
                        gM += lM;
                        float3 rb = (cos(6. * (r + 0.3333 * float3(0, 1, -1))) + 0.5) * 0.5;
                        float3 lC = lerp(rb * 0.3, rb, smoothstep(-0.92, 0.2, uv.y));
                        lC = lerp(lC, rb * 2. + ((float3)0.5),
                                  max(0., smoothstep(0.1 * (1. - uv.y * 1.5), 0.4, L(uv*1.3) - 1.)));
                        lC = lerp(lC, rb * 0.3, f);
                        lC += exp(1. - L((uv-normalize(0.5-NUV))*6.));
                        col = lerp(col, lerp(float3(0.4, 0.2, 0.4) / ss, lC, 1. - i / float(LAYERS)), lM);
                    }
                    else continue;
                }
                float l = L(U), y = log(l) * 10., x = (atan2(U.y, U.x) + PI) / (2. * PI) * 20. + 0.33 * lerp(
                          t, -t, glsl_mod(floor(y), 2.)), s = abs(frac(x) - 0.5);
                col = lerp(
                    lerp(float3(0.2, 0.1, 0.2) * 0.8 * (1. - 0.3 * l * ((float3)step(
                             length(frac(mul(U * 35., transpose(float2x2(1, 1, -1, 1)))) - 0.5), 0.3))),
                         float3(2., 0, 1),
                         step(s + frac(y) + 0.2, 1.) * max(l - 0.56, 0.) * (1. - step(s + frac(y) + 0.4, 1.))), col,
                    clamp(gM, 0., 1.3));
                col *= min(0. + NUV.x * NUV.y * (1. - NUV.y) * (1. - NUV.x) / 0.01, 1.);
                float4 fragColor = float4(col, max(0., (l <= 0.2 ? 1. : 0.) - gM));
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
        Pass
        {
            CGPROGRAM
            #define SAMPLES 50.

            float4 frag(v2f i) : SV_Target
            {
                float2 U;
                if(_ScreenEffect)
                {
                    float2 u = i.uv * _ScreenParams;
                    U = u.xy / _ScreenParams.xy;
                }else
                {
                    float2 u = i.uv * iResolution;
                    U = u.xy / iResolution.xy;
                }
                float2 U2 = (U * 2. - 1.) * float2(1.7, 1);
                float o = tex2D(_MainTex, U).w;
                float3 cc = tex2D(_MainTex, U).xyz;
                float2 dtc = (U - 0.5) * (1. / SAMPLES);
                for (int i = 0; i < int(SAMPLES); i++)
                {
                    U -= dtc;
                    float s = tex2D(_MainTex, U + dtc).w;
                    o += s;
                }
                o = 2. * o / SAMPLES;
                cc += exp(1. - length(U2 * 3.2)) / 2.;
                float4 fragColor = float4(pow(cc * o, ((float3)1. / 2.2)), 1.);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}