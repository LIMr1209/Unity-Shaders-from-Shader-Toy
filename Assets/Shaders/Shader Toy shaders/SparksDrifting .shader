// https://www.shadertoy.com/view/MlKSWm
Shader "Unlit/SparksDrifting "
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

            float3 mod289(float3 x)
            {
                return x - floor(x * (1. / 289.)) * 289.;
            }

            float4 mod289(float4 x)
            {
                return x - floor(x * (1. / 289.)) * 289.;
            }

            float4 permute(float4 x)
            {
                return mod289((x * 34. + 1.) * x);
            }

            float4 taylorInvSqrt(float4 r)
            {
                return 1.7928429 - 0.85373473 * r;
            }

            float snoise(float3 v)
            {
                const float2 C = float2(1. / 6., 1. / 3.);
                const float4 D = float4(0., 0.5, 1., 2.);
                float3 i = floor(v + dot(v, C.yyy));
                float3 x0 = v - i + dot(i, C.xxx);
                float3 g = step(x0.yzx, x0.xyz);
                float3 l = 1. - g;
                float3 i1 = min(g.xyz, l.zxy);
                float3 i2 = max(g.xyz, l.zxy);
                float3 x1 = x0 - i1 + C.xxx;
                float3 x2 = x0 - i2 + C.yyy;
                float3 x3 = x0 - D.yyy;
                i = mod289(i);
                float4 p = permute(
                    permute(permute(i.z + float4(0., i1.z, i2.z, 1.)) + i.y + float4(0., i1.y, i2.y, 1.)) + i.x +
                    float4(0., i1.x, i2.x, 1.));
                float n_ = 0.14285715;
                float3 ns = n_ * D.wyz - D.xzx;
                float4 j = p - 49. * floor(p * ns.z * ns.z);
                float4 x_ = floor(j * ns.z);
                float4 y_ = floor(j - 7. * x_);
                float4 x = x_ * ns.x + ns.yyyy;
                float4 y = y_ * ns.x + ns.yyyy;
                float4 h = 1. - abs(x) - abs(y);
                float4 b0 = float4(x.xy, y.xy);
                float4 b1 = float4(x.zw, y.zw);
                float4 s0 = floor(b0) * 2. + 1.;
                float4 s1 = floor(b1) * 2. + 1.;
                float4 sh = -step(h, ((float4)0.));
                float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
                float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
                float3 p0 = float3(a0.xy, h.x);
                float3 p1 = float3(a0.zw, h.y);
                float3 p2 = float3(a1.xy, h.z);
                float3 p3 = float3(a1.zw, h.w);
                float4 norm = rsqrt(float4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
                p0 *= norm.x;
                p1 *= norm.y;
                p2 *= norm.z;
                p3 *= norm.w;
                float4 m = max(0.6 - float4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.);
                m = m * m;
                return 42. * dot(m * m, float4(dot(p0, x0), dot(p1, x1), dot(p2, x2), dot(p3, x3)));
            }

            float prng(in float2 seed)
            {
                seed = frac(seed * float2(5.3983, 5.4427));
                seed += dot(seed.yx, seed.xy + float2(21.5351, 14.3137));
                return frac(seed.x * seed.y * 95.4337);
            }

            static float PI = 3.1415927;

            float noiseStack(float3 pos, int octaves, float falloff)
            {
                float noise = snoise(((float3)pos));
                float off = 1.;
                if (octaves > 1)
                {
                    pos *= 2.;
                    off *= falloff;
                    noise = (1. - off) * noise + off * snoise(((float3)pos));
                }

                if (octaves > 2)
                {
                    pos *= 2.;
                    off *= falloff;
                    noise = (1. - off) * noise + off * snoise(((float3)pos));
                }

                if (octaves > 3)
                {
                    pos *= 2.;
                    off *= falloff;
                    noise = (1. - off) * noise + off * snoise(((float3)pos));
                }

                return (1. + noise) / 2.;
            }

            float2 noiseStackUV(float3 pos, int octaves, float falloff, float diff)
            {
                float displaceA = noiseStack(pos, octaves, falloff);
                float displaceB = noiseStack(pos + float3(3984.293, 423.21, 5235.19), octaves, falloff);
                return float2(displaceA, displaceB);
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 fragCoord = i.uv * _Resolution;
                float time = _Time.y;
                float2 resolution = iResolution.xy;
                float2 drag = _Mouse.xy;
                float2 offset = _Mouse.xy;
                float xpart = fragCoord.x / resolution.x;
                float ypart = fragCoord.y / resolution.y;
                float clip = 210.;
                float ypartClip = fragCoord.y / clip;
                float ypartClippedFalloff = clamp(2. - ypartClip, 0., 1.);
                float ypartClipped = min(ypartClip, 1.);
                float ypartClippedn = 1. - ypartClipped;
                float xfuel = 1. - abs(2. * xpart - 1.);
                float timeSpeed = 0.5;
                float realTime = timeSpeed * time;
                float2 coordScaled = 0.01 * fragCoord - 0.02 * float2(offset.x, 0.);
                float3 position = float3(coordScaled, 0.) + float3(1223., 6434., 8425.);
                float3 flow = float3(4.1 * (0.5 - xpart) * pow(ypartClippedn, 4.),
                                     -2. * xfuel * pow(ypartClippedn, 64.), 0.);
                float3 timing = realTime * float3(0., -1.7, 1.1) + flow;
                float3 displacePos = float3(1., 0.5, 1.) * 2.4 * position + realTime * float3(0.01, -0.7, 1.3);
                float3 displace3 = float3(noiseStackUV(displacePos, 2, 0.4, 0.1), 0.);
                float3 noiseCoord = (float3(2., 1., 1.) * position + timing + 0.4 * displace3) / 1.;
                float noise = noiseStack(noiseCoord, 3, 0.4);
                float flames = pow(ypartClipped, 0.3 * xfuel) * pow(noise, 0.3 * xfuel);
                float f = ypartClippedFalloff * pow(1. - flames * flames * flames, 8.);
                float fff = f * f * f;
                float3 fire = 1.5 * float3(f, fff, fff * fff);
                float smokeNoise = 0.5 + snoise(0.4 * position + timing * float3(1., 1., 0.2)) / 2.;
                float3 smoke = ((float3)0.3 * pow(xfuel, 3.) * pow(ypart, 2.) * (smokeNoise + 0.4 * (1. - noise)));
                float sparkGridSize = 30.;
                float2 sparkCoord = fragCoord - float2(2. * offset.x, 190. * realTime);
                sparkCoord -= 30. * noiseStackUV(0.01 * float3(sparkCoord, 30. * time), 1, 0.4, 0.1);
                sparkCoord += 100. * flow.xy;
                if (glsl_mod(sparkCoord.y/sparkGridSize, 2.) < 1.)
                    sparkCoord.x += 0.5 * sparkGridSize;

                float2 sparkGridIndex = ((float2)floor(sparkCoord / sparkGridSize));
                float sparkRandom = prng(sparkGridIndex);
                float sparkLife = min(
                    10. * (1. - min((sparkGridIndex.y + 190. * realTime / sparkGridSize) / (24. - 20. * sparkRandom),
                                    1.)), 1.);
                float3 sparks = ((float3)0.);
                if (sparkLife > 0.)
                {
                    float sparkSize = xfuel * xfuel * sparkRandom * 0.08;
                    float sparkRadians = 999. * sparkRandom * 2. * PI + 2. * time;
                    float2 sparkCircular = float2(sin(sparkRadians), cos(sparkRadians));
                    float2 sparkOffset = (0.5 - sparkSize) * sparkGridSize * sparkCircular;
                    float2 sparkModulus = glsl_mod(sparkCoord+sparkOffset, sparkGridSize) - 0.5 * ((float2)
                        sparkGridSize);
                    float sparkLength = length(sparkModulus);
                    float sparksGray = max(0., 1. - sparkLength / (sparkSize * sparkGridSize));
                    sparks = sparkLife * sparksGray * float3(1., 0.3, 0.);
                }

                float4 fragColor = float4(max(fire, sparks) + smoke, 1.);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}