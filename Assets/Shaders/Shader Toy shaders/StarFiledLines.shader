﻿// from art of code
Shader "Unlit/StarFiledLines"
{
    Properties
    {
        [Header(General)]
        [ToggleUI] _GammaCorrect ("Gamma Correction", Float) = 1
        _Resolution ("Resolution (Change if AA is bad)", Range(1, 1024)) = 1
        [ToggleUI] _ScreenEffect("ScreenEffect", Float) = 0


        [Header(Extracted)]
        _Scale("Scale XY max min",vector) = (10.0,0.5,0.0,0.0)
        _FadeVal("Fade length XY", Vector) = (1.2,0.8,0,0)
        _CFSpeed("Circle Fade Speed",Range(0.1,20.0)) = 5.0
        _ColorSpeed("Color Shift Speed",Range(0.1,20.0)) = 5.0
        _MoveSpeed("Move Speed",Range(0.1,10.0)) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

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
            float _ScreenEffect;

            // GLSL Compatability macros
            #define glsl_mod(x,y) (((x)-(y)*floor((x)/(y))))
            #define iResolution float3(_Resolution, _Resolution, _Resolution)


            fixed2 _Scale;
            fixed2 _FadeVal;
            fixed _CFSpeed;
            fixed _ColorSpeed;
            fixed _MoveSpeed;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;//TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            // a start oint , b end point
            fixed DistLine(fixed2 p , fixed2 a , fixed2 b)
            {
                fixed2 pa = p-a;
                fixed2 ba = b-a;
                fixed t = clamp(dot(pa, ba) / dot(ba, ba), 0.0 , 1.0);
                return length(pa - ba*t);
            }

            fixed N21(fixed2 p ) // random number function
            {
                p = frac(p* fixed2(233.32, 851.73));
                p += dot(p, p +23.45);
                return frac(p.x*p.y);
            }

            fixed2 N22(fixed2 p)
            {
                fixed n = N21(p);
                return fixed2(n, N21(n+p));
            }

            fixed2 GetPos(fixed2 id, fixed2 offset)
            {
                fixed2 n = N22(id+offset) * _Time.y*_MoveSpeed;
                return offset+sin(n)*0.4; // 0.4 to stay inside grid boundry
            }

            fixed Line(fixed2 p , fixed2 a, fixed2 b)
            {
                fixed m = smoothstep(0.03,0.01, DistLine(p, a, b)); // line width
                fixed d2 = length(a-b);
                m *= smoothstep(_FadeVal.x,_FadeVal.y,d2) + smoothstep(0.05,0.03,d2-0.75); // fade in out according to lenght
                return m;
            }

            fixed Layer(fixed2 uv)
            {
                fixed m = 0.0;

                fixed2 gv = frac(uv) - 0.5; // grid UV
                fixed2 id = floor(uv);

                fixed2 p[9]; // 3x3 grid

                int iter=0;
                for(fixed y = -1; y <= 1; y++)
                {
                    for(fixed x = -1; x <= 1; x++)
                    {
                        p[iter++] = GetPos(id, fixed2(x,y));
                    }
                }

                fixed time = _Time.y* _CFSpeed;
                for(int iter = 0; iter<9; iter++)
                {
                    m += Line(gv, p[4], p[iter]);

                    fixed2 j = (p[iter]- gv) * 15.0;
                    fixed sparkle = 1.0 / dot(j,j); // dot samething like square

                    m += sparkle * (sin(time + frac(p[iter].x)*10)*0.5 + 0.5);
                }
                // draw more 4 lines to avoid overlabing
                m += Line(gv, p[1], p[3]); 
                m += Line(gv, p[1], p[5]);
                m += Line(gv, p[7], p[3]);
                m += Line(gv, p[7], p[5]);

                return m;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                float2 uv = (i.uv - 0.5);   // -0.5 - 0.5
                if(_ScreenEffect)
                {
                    uv.x *= _ScreenParams.x / _ScreenParams.y;
                }
                else
                {
                    uv.x *= iResolution.x / iResolution.y;
                }
                fixed gradient = uv.y;
                fixed3 col = fixed3(0.0,0.0,0.0);

                fixed m = 0.0;
                fixed t = _Time.y *0.1;

                // rotaate uv
                fixed2x2 mat= fixed2x2(cos(t), -sin(t), sin(t), cos(t));
                uv = mul(uv,mat);

                for(fixed iter = 0.0; iter < 1.0; iter+= 1.0/4.0)
                {
                    fixed z = frac(iter+t);
                    fixed size = lerp(_Scale.x, _Scale.y,z);
                    fixed fade = smoothstep(0.0,0.5,z) * smoothstep(1.0,0.75,z);
                    m += Layer(uv*size+iter*20) * fade;
                }

                fixed3 baseColor = sin(t*_ColorSpeed*fixed3(0.345,0.456,0.657)) * 0.4 + 0.6;
                col = baseColor * m;
                col += gradient * baseColor;

                float4 fragColor = float4(col, 1.0);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}
