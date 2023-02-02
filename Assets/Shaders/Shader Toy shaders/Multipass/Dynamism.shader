// https://www.shadertoy.com/view/MtKSWW
Shader "Unlit/Dynamism"
{
    Properties
    {
        _MainTex ("iChannel0", 2D) = "white" {}
        _SecondTex ("iChannel1", 2D) = "white" {}
        _ThirdTex ("iChannel2", 2D) = "white" {}
        _FourthTex ("iChannel3", 2D) = "white" {}
        _Mouse ("Mouse", Vector) = (0.5, 0.5, 0.5, 0.5)
        [ToggleUI] _GammaCorrect ("Gamma Correction", Float) = 1
        _Resolution ("Resolution (Change if AA is bad)", Range(1, 1024)) = 1
    }
    SubShader
    {
        CGINCLUDE
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
        sampler2D _SecondTex;
        float4 _SecondTex_TexelSize;
        sampler2D _ThirdTex;
        float4 _ThirdTex_TexelSize;
        sampler2D _FourthTex;
        float4 _FourthTex_TexelSize;
        float4 _Mouse;
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

        #include "UnityCG.cginc"


        v2f vert(appdata v)
        {
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);
            o.uv = v.uv;
            return o;
        }

        #define time _Time.y
        #define time2 (time*2.1+(1.+sin(time+sin(time*0.4+cos(time*0.1))))*1.5)
        #define time3 (time*1.+(1.+sin(time*0.9+sin(time*0.34+cos(time*0.21))))*1.5)
        #define time4 (time*0.5+(1.+sin(time*0.8+sin(time*0.14+cos(time*0.15))))*1.2)

        float2 hash(float2 p)
        {
            float3 p3 = frac(((float3)p.xyx) * float3(0.1031, 0.103, 0.0973));
            p3 += dot(p3.zxy, p3.yxz + 19.19);
            return -1. + 2. * frac(float2(p3.x * p3.y, p3.z * p3.x));
        }

        float noise(in float2 p)
        {
            p *= 0.45;
            const float K1 = 0.36602542;
            const float K2 = 0.21132487;
            float2 i = floor(p + (p.x + p.y) * K1);
            float2 a = p - i + (i.x + i.y) * K2;
            float2 o = a.x > a.y ? float2(1., 0.) : float2(0., 1.);
            float2 b = a - o + K2;
            float2 c = a - 1. + 2. * K2;
            float3 h = max(0.5 - float3(dot(a, a), dot(b, b), dot(c, c)), 0.);
            float3 n = h * h * h * h * float3(dot(a, hash(i + 0.)), dot(b, hash(i + o)), dot(c, hash(i + 1.)));
            return dot(n, ((float3)38.));
        }

        float2x2 rot(in float a)
        {
            float c = cos(a), s = sin(a);
            return transpose(float2x2(c, s, -s, c));
        }

        float fbm(in float2 p, in float2 of)
        {
            p = mul(p, rot(time3 * 0.1));
            p += of;
            float z = 2.;
            float rz = 0.;
            float2 bp = p;
            for (float i = 1.; i < 9.; i++)
            {
                rz += noise(mul(p, rot(float(i) * 2.3)) + time * 0.5) / z;
                z *= 3.2;
                p *= 2.;
            }
            return rz;
        }

        float2 grdf(in float2 p, in float2 of)
        {
            float2 ep = float2(0., 0.0005);
            float2 d = float2(fbm(p - ep.yx, of) - fbm(p + ep.yx, of), fbm(p - ep.xy, of) - fbm(p + ep.xy, of));
            d /= length(d);
            return d;
        }
        ENDCG

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            float4 frag(v2f i) : SV_Target
            {
                float2 fragCoord = i.uv * _Resolution;
                float2 p = fragCoord.xy / iResolution.xy - 0.5;
                p.x *= iResolution.x / iResolution.y;
                p *= 1.75;
                float t1 = glsl_mod(time2*0.35, 4.);
                float t2 = glsl_mod(time2*0.35+1., 4.);
                float2 p1 = p * (4. - t1);
                float2 p2 = p * (4. - t2);
                float2 fld = grdf(p1, float2(time4 * 0.2, time * 0.));
                float2 fld2 = grdf(p2, float2(time4 * 0.2, time * 0.) + 2.2);
                float4 fragColor = float4(fld, fld2);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }


        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            float4 frag(v2f i) : SV_Target
            {
                float2 fragCoord = i.uv * _Resolution;
                float2 p = fragCoord.xy / iResolution.xy - 0.5;
                p.x *= iResolution.x / iResolution.y;
                p *= 1.75;
                float t3 = glsl_mod(time2*0.35 + 2, 4.);
                float t4 = glsl_mod(time2*0.35 + 3., 4.);

                float2 p3 = p * (4. - t3);
                float2 p4 = p * (4. - t4);
                float2 fld = grdf(p3, float2(time4 * 0.2, time * 0.) + 4.5);
                float2 fld2 = grdf(p4, float2(time4 * 0.2, time * 0.) + 7.3);
                float4 fragColor = float4(fld, fld2);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #define time _Time.y
            #define time2v ((1.+sin(time+sin(time*0.4+cos(time*0.1))))*1.5)
            #define time2 (time*2.1+time2v)

            float2 div(float2 p, sampler2D smp)
            {
                float2 tx = 1. / iResolution.xy;
                float4 uv = textureLod(smp, p, -100.);
                float4 uv_n = textureLod(smp, p + float2(0., tx.y), -100.);
                float4 uv_e = textureLod(smp, p + float2(tx.x, 0.), -100.);
                float4 uv_s = textureLod(smp, p + float2(0., -tx.y), -100.);
                float4 uv_w = textureLod(smp, p + float2(-tx.x, 0.), -100.);
                float div = uv_s.y - uv_n.y - uv_e.x + uv_w.x;
                float div2 = uv_s.w - uv_n.w - uv_e.z + uv_w.z;
                return float2(div, div2) * 1.8;
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 fragCoord = i.uv * _Resolution;
                float2 p = fragCoord.xy / iResolution.xy;
                float2 dv = div(p, _MainTex);
                float2 dv2 = div(p, _SecondTex);
                dv = pow(abs(dv), ((float2)0.5)) * sign(dv);
                dv = clamp(dv, 0., 4.);
                dv2 = pow(abs(dv2), ((float2)0.5)) * sign(dv2);
                dv2 = clamp(dv2, 0., 4.);
                float t1 = glsl_mod(time2*0.35, 4.);
                float t2 = glsl_mod(time2*0.35+1., 4.);
                float t3 = glsl_mod(time2*0.35+2., 4.);
                float t4 = glsl_mod(time2*0.35+3., 4.);
                const float ws = 1.1;
                const float wof = 1.8;
                float x = time;
                float drvT = 1.5 * cos(x + sin(0.4 * x + cos(0.1 * x))) * (cos(0.4 * x + cos(0.1 * x)) * (0.4 - 0.1 *
                    sin(0.1 * x)) + 1.) + 2.1;
                float ofsc = 0.8 + drvT * 0.07;
                float t1w = clamp(t1 * ws + wof, 0., 10.);
                float t2w = clamp(t2 * ws + wof, 0., 10.);
                float t3w = clamp(t3 * ws + wof, 0., 10.);
                float t4w = clamp(t4 * ws + wof, 0., 10.);
                float3 col = ((float3)0);
                col += sqrt(t1) * float3(0.28, 0.19, 0.15) * exp2(dv.x * t1w - t1w * ofsc);
                col += sqrt(t2) * float3(0.1, 0.13, 0.23) * exp2(dv.y * t2w - t2w * ofsc);
                col += sqrt(t3) * float3(0.27, 0.07, 0.07) * exp2(dv2.x * t3w - t3w * ofsc);
                col += sqrt(t4) * float3(0.1, 0.18, 0.25) * exp2(dv2.y * t4w - t4w * ofsc);
                col = pow(col, ((float3)0.6)) * 1.2;
                col *= smoothstep(0., 1., col);
                col *= pow(16. * p.x * p.y * (1. - p.x) * (1. - p.y), 0.4);
                float4 fragColor = float4(col, 1.);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            static const float2 center = float2(0, 0);
            static const int samples = 15;
            static const float wCurveA = 1.;
            static const float wCurveB = 1.;
            static const float dspCurveA = 2.;
            static const float dspCurveB = 1.;
            #define time _Time.y

            float wcurve(float x, float a, float b)
            {
                float r = pow(a + b, a + b) / (pow(a, a) * pow(b, b));
                return r * pow(x, a) * pow(1. - x, b);
            }

            float hash21(in float2 n)
            {
                return frac(sin(dot(n, float2(12.9898, 4.1414))) * 43758.547);
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 fragCoord = i.uv * _Resolution;
                float2 p = fragCoord / iResolution.xy;
                float2 mo = _Mouse.xy / iResolution.xy;
                float2 center = mo;
                center = float2(0.5, 0.5);
                float3 col = ((float3)0.);
                float2 tc = center - p;
                float w = 1.;
                float tw = 1.;
                float rnd = (hash21(p) - 0.5) * 0.75;
                float x = time;
                float drvT = 1.5 * cos(x + sin(0.4 * x + cos(0.1 * x))) * (cos(0.4 * x + cos(0.1 * x)) * (0.4 - 0.1 *
                    sin(0.1 * x)) + 1.) + 2.1;
                float strength = 0.01 + drvT * 0.01;
                for (int i = 0; i < samples; i++)
                {
                    float sr = float(i) / float(samples);
                    float sr2 = (float(i) + rnd) / float(samples);
                    float weight = wcurve(sr2, wCurveA, wCurveB);
                    float displ = wcurve(sr2, dspCurveA, dspCurveB);
                    col += tex2D(_ThirdTex, p + tc * sr2 * strength * displ).rgb * weight;
                    tw += 0.9 * weight;
                }
                col /= tw;
                float4 fragColor = float4(col, 1.);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }


    }
}