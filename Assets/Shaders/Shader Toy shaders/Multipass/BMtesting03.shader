// https://www.shadertoy.com/view/fldyRj
Shader "Unlit/BMtesting03"
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
    ENDCG
    SubShader
    {

        Tags
        {
            "RenderType"="Opaque"
        }
        LOD 100
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            float3 warp(float2 u, float ph1, float ph2)
            {
                float2 v = u - log(1. / max(length(u), 0.001)) * float2(-1, 1);
                float3 col = ((float3)0.);
                const int n = 5;
                for (int i = 0; i < n; i++)
                {
                    v = cos(v.y - float2(0, 1.57)) * exp(sin(v.x + ph1) + cos(v.y + ph2));
                    v -= u;
                    float3 d = (0.5 + 0.45 * cos(((float3)i) / float(n) * 3. + float3(0, 1, 2) * 1.5)) / max(
                        length(v), 0.001);
                    col += d * d / 32.;
                }
                return col;
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 fragCoord = i.uv * _Resolution;
                float2 u = (fragCoord - iResolution.xy * 0.5) / iResolution.y * 2.;
                float ph1 = _Time.y * 0.6;
                float ph2 = sin(_Time.y) * 0.25;
                float3 col = warp(u, ph1, ph2) + warp(u, ph1, ph2 + 1.57);
                col = lerp(col, col.zyx, 0.1);
                float4 preCol = texelFetch(_MainTex, ((int2)fragCoord), 0);
                float blend = iFrame < 2 ? 1. : 0.25;
                col = lerp(preCol.xyz, col, blend);
                float4 fragColor = float4(clamp(col, 0., 1.), 1);
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

            #define HIGHLIGHTS 

            float4 tx(in float2 p)
            {
                p *= float2(iResolution.y / iResolution.x, 1);
                return tex2D(_MainTex, p + 0.5 / iResolution.y);
            }

            float4 bTx(in float2 p)
            {
                float px = 2.;
                float4 c = ((float4)0);
                for (int i = 0; i < 9; i++)
                    c += tx(p + (float2(i / 3, i % 3) - 1.) * px / iResolution.y);
                return c / 9.;
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 fragCoord = i.uv * _Resolution;
                float2 uv = fragCoord / iResolution.y;
                float4 col = bTx(uv);
                #ifdef HIGHLIGHTS
                float2 px = 4. / iResolution.yy;
                float4 col2 = bTx(uv - px);
                float b = max(dot(col2 - col, float4(0.299, 0.587, 0.114, 0)), 0.) / length(px);
                col += col2.yzxw * col2.yzxw * b / 12.;
                #endif
                col = lerp(col, col.zyxw, max(0.3 - uv.y, 0.));
                float4 fragColor = sqrt(max(col, 0.));
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fixed4(1, 1, 1, 1);
                return fragColor;
            }
            ENDCG
        }
    }
}