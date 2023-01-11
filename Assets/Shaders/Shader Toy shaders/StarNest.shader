// https://www.shadertoy.com/view/XlfGRj
Shader "Unlit/StarNest"
{
    Properties
    {
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

            #define iterations 17
            #define formuparam 0.53

            #define volsteps 20
            #define stepsize 0.1

            #define zoom   0.800
            #define tile   0.850
            #define speed  0.010

            #define brightness 0.0015
            #define darkmatter 0.300
            #define distfading 0.730
            #define saturation 0.850

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


            fixed4 frag(v2f i) : SV_Target
            {
                //get coords and direction
                float2 uv = i.uv - .5;
                uv.y *= _ScreenParams.y / _ScreenParams.x;
                float3 dir = float3(uv * zoom, 1.);
                float time = _Time.y * speed + .25;

                //mouse rotation
                float a1 = 0.5;
                float a2 = 0.8;
                float2x2 rot1 = float2x2(cos(a1), sin(a1), -sin(a1), cos(a1));
                float2x2 rot2 = float2x2(cos(a2), sin(a2), -sin(a2), cos(a2));
                dir.xz = mul(rot1, dir.xz);
                dir.xy = mul(rot2, dir.xy);
                float3 from = float3(1., .5, 0.5);
                from += float3(time * 2., time, -2.);
                from.xz = mul(rot1, from.xz);
                from.xy = mul(rot2, from.xy);

                //volumetric rendering
                float s = 0.1, fade = 1.;
                float3 v = float3(0,0,0);
                for (int r = 0; r < volsteps; r++)
                {
                    float3 p = from + s * dir * .5;
                    p = abs(float3(tile, tile, tile) - fmod(p, float3(tile * 2., tile * 2, tile * 2.))); // tiling fold
                    float pa, a = pa = 0.;
                    for (int i = 0; i < iterations; i++)
                    {
                        p = abs(p) / dot(p, p) - formuparam; // the magic formula
                        a += abs(length(p) - pa); // absolute sum of average change
                        pa = length(p);
                    }
                    float dm = max(0., darkmatter - a * a * .001); //dark matter
                    a *= a * a; // add contrast
                    if (r > 6) fade *= 1. - dm; // dark matter, don't render near
                    //v+=float3(dm,dm*.5,0.);
                    v += fade;
                    v += float3(s, s * s, s * s * s * s) * a * brightness * fade; // coloring based on distance
                    fade *= distfading; // distance fading
                    s += stepsize;
                }
                v = lerp(float3(length(v), length(v), length(v)), v, saturation); //color adjust
                float4 fragColor = float4(v * .01, 1.);
                return fragColor;
            }
            ENDCG
        }
    }
}