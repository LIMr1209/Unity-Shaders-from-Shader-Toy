//https://www.shadertoy.com/view/WtG3RD
Shader "Custom/TheRingColorLerper"
{

	Properties
	{
		[Header(General)]
        [ToggleUI] _GammaCorrect ("Gamma Correction", Float) = 1
        _Resolution ("Resolution (Change if AA is bad)", Range(1, 1024)) = 1
        [ToggleUI] _ScreenEffect("ScreenEffect", Float) = 0

		
		[Header(Extracted)]
		_ColorRange("Color Range",Range(1,256)) = 255
		_BlackColor("RGB Color Intensity",Vector) = (16,21,25)
		_speed1("Speed 1",Range(0.0,5.0)) = 0.525
		_speed2("Speed 2",Range(0.0,5.0)) = 3.0
		_speed3("Speed 3",Range(0.0,5.0)) = 1.0
	}

	SubShader
	{
		Tags { "RenderType" = "Opaque" }

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

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

			// Built-in properties
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

			
			int _ColorRange;
			fixed4 _BlackColor;

			fixed _speed1;
			fixed _speed2;
			fixed _speed3;

			#define TAU 6.2831852
			#define MOD3 fixed3(.1031,.11369,.13787)
			#define BLACK_COL _BlackColor.xyz/_ColorRange
			

			fixed3 hash33(fixed3 p3)
			{
				p3 = frac(p3 * MOD3);
				p3 += dot(p3, p3.yxz+19.19);
				return -1.0 + 2.0 * frac(fixed3((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y, (p3.y+p3.z)*p3.x));
			}

			fixed simplex_noise(fixed3 p)
			{
				const fixed K1 = 0.333333333;
				const fixed K2 = 0.166666667;
				
				fixed3 i = floor(p + (p.x + p.y + p.z) * K1);
				fixed3 d0 = p - (i - (i.x + i.y + i.z) * K2);
					
				fixed3 e = step(fixed3(0.0,0.0,0.0), d0 - d0.yzx);
				fixed3 i1 = e * (1.0 - e.zxy);
				fixed3 i2 = 1.0 - e.zxy * (1.0 - e);
				
				fixed3 d1 = d0 - (i1 - 1.0 * K2);
				fixed3 d2 = d0 - (i2 - 2.0 * K2);
				fixed3 d3 = d0 - (1.0 - 3.0 * K2);
				
				fixed4 h = max(0.6 - fixed4(dot(d0, d0), dot(d1, d1), dot(d2, d2), dot(d3, d3)), 0.0);
				fixed4 n = h * h * h * h * fixed4(dot(d0, hash33(i)), dot(d1, hash33(i + i1)), dot(d2, hash33(i + i2)), dot(d3, hash33(i + 1.0)));
				
				return dot(fixed4(31.316,31.316,31.316,31.316), n);
			}

			
			fixed4 frag(v2f i) : SV_Target
			{			
				fixed2 uv = (i.uv-1*0.5);
				if(_ScreenEffect)
                {
                    uv.x *= _ScreenParams.x / _ScreenParams.y;
                }
                else
                {
                    uv.x *= iResolution.x / iResolution.y;
                }
					
				fixed a = sin(atan2( uv.x,uv.y));
				fixed am = abs(a-.5)/4.;
				fixed l = length(uv);                         
				
				fixed m1 = clamp(.1/smoothstep(.0, 1.75, l), 0., 1.);
				fixed m2 = clamp(.1/smoothstep(.42, 0., l), 0., 1.);
				fixed s1 = (simplex_noise(fixed3(uv*2., 1. + _Time.y*_speed1))*(max(1.0 - l*1.75, 0.)) + .9);
				fixed s2 = (simplex_noise(fixed3(uv*1., 15. + _Time.y*_speed1))*(max(.0 + l*1., .025)) + 1.25);
				fixed s3 = (simplex_noise(fixed3(fixed2(am, am*100. + _Time.y*_speed2)*.15, 30. + _Time.y*_speed1))*(max(.0 + l*1., .25)) + 1.5);
				s3 *= smoothstep(0.0, .3345, l);    
				
				fixed sh = smoothstep(0.15, .35, l);
								
				fixed m = m1*m1*m2 * ((s1*s2*s3) * (1.-l)) * sh;
				//m = clamp(m, 0., 1.);
				
				fixed3 col = lerp(BLACK_COL, (0.5 + 0.5*cos(_Time.y*_speed3 +uv.xyx*3.+fixed3(0,2,4))), m);

				float4 fragColor = float4(col, 1);
				if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
				return fragColor;
			}
			ENDCG
		}
  }
}

