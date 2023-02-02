// https://www.shadertoy.com/view/4dSfDK
Shader "Unlit/GlowShaderTest2 "
{
    Properties
    {
        [ToggleUI] _GammaCorrect ("Gamma Correction", Float) = 1
        _Mouse ("Mouse", Vector) = (0.5, 0.5, 0.5, 0.5)
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
            float4 _Mouse;

            // GLSL Compatability macros
            #define glsl_mod(x,y) (((x)-(y)*floor((x)/(y))))
            #define texelFetch(ch, uv, lod) tex2Dlod(ch, float4((uv).xy * ch##_TexelSize.xy + ch##_TexelSize.xy * 0.5, 0, lod))
            #define textureLod(ch, uv, lod) tex2Dlod(ch, float4(uv, 0, lod))
            #define iResolution float3(_Resolution, _Resolution, _Resolution)
            #define iFrame (floor(_Time.y / 60))
            #define iChannelTime float4(_Time.y, _Time.y, _Time.y, _Time.y)
            #define iDate float4(2020, 6, 18, 30)
            #define iSampleRate (44100)

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            #define M_PI 3.1415927
#define M_TWO_PI (2.*M_PI)
            float rand(float2 n)
            {
                return frac(sin(dot(n, float2(12.9898, 12.1414)))*83758.55);
            }

            float noise(float2 n)
            {
                const float2 d = float2(0., 1.);
                float2 b = floor(n);
                float2 f = smoothstep(((float2)0.), ((float2)1.), frac(n));
                return lerp(lerp(rand(b), rand(b+d.yx), f.x), lerp(rand(b+d.xy), rand(b+d.yy), f.x), f.y);
            }

            float3 ramp(float t)
            {
                return t<=0.5 ? float3(1.-t*1.4, 0.2, 1.05)/t : float3(0.3*(1.-t)*2., 0.2, 1.05)/t;
            }

            float2 polarMap(float2 uv, float shift, float inner)
            {
                uv = ((float2)0.5)-uv;
                float px = 1.-frac(atan2(uv.y, uv.x)/6.28+0.25)+shift;
                float py = (sqrt(uv.x*uv.x+uv.y*uv.y)*(1.+inner*2.)-inner)*2.;
                return float2(px, py);
            }

            float fire(float2 n)
            {
                return noise(n)+noise(n*2.1)*0.6+noise(n*5.4)*0.42;
            }

            float shade(float2 uv, float t)
            {
                uv.x += uv.y<0.5 ? 23.+t*0.035 : -11.+t*0.03;
                uv.y = abs(uv.y-0.5);
                uv.x *= 35.;
                float q = fire(uv-t*0.013)/2.;
                float2 r = float2(fire(uv+q/2.+t-uv.x-uv.y), fire(uv+q-t));
                return pow((r.y+r.y)*max(0., uv.y)+0.1, 4.);
            }

            float3 color(float grad)
            {
                float m2 = _Mouse.z<0.0001 ? 1.15 : _Mouse.y*3./iResolution.y;
                grad = sqrt(grad);
                float3 color = ((float3)1./pow(float3(0.5, 0., 0.1)+2.61, ((float3)2.)));
                float3 color2 = color;
                color = ramp(grad);
                color /= m2+max(((float3)0), color);
                return color;
            }

            float4 frag (v2f i) : SV_Target
            {
                float2 fragCoord = i.uv * _Resolution;
                float m1 = _Mouse.z<0.0001 ? 3.6 : _Mouse.x*5./iResolution.x;
                float t = _Time.y;
                float2 uv = fragCoord/iResolution.yy;
                float ff = 1.-uv.y;
                uv.x -= (iResolution.x/iResolution.y-1.)/2.;
                float2 uv2 = uv;
                uv2.y = 1.-uv2.y;
                uv = polarMap(uv, 1.3, m1);
                uv2 = polarMap(uv2, 1.9, m1);
                float3 c1 = color(shade(uv, t))*ff;
                float3 c2 = color(shade(uv2, t))*(1.-ff);
                float4 fragColor = float4(c1+c2, 1.);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}