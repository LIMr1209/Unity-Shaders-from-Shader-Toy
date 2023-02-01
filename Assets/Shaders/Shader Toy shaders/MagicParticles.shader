// https://www.shadertoy.com/view/ld3GWS
Shader "Unlit/MagicParticles"
{
    Properties
    {
        _MainTex ("iChannel0", 2D) = "white" {}
        _SecondTex ("iChannel1", 2D) = "white" {}
        _ThirdTex ("iChannel2", 2D) = "white" {}
        _FourthTex ("iChannel3", 2D) = "white" {}
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
            sampler2D _MainTex;   float4 _MainTex_TexelSize;
            sampler2D _SecondTex; float4 _SecondTex_TexelSize;
            sampler2D _ThirdTex;  float4 _ThirdTex_TexelSize;
            sampler2D _FourthTex; float4 _FourthTex_TexelSize;
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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv =  v.uv;
                return o;
            }

            #define twopi 6.28319
            // Please be careful, setting complexity > 1 may crash your browser!
            // 1: for mac computers
            // 2: for computers with normal graphic card
            // 3: for computers with good graphic cards
            // 4: for gaming computers
            #define complexity 1

            // General particles constants
            #if complexity == 1
            static const int nb_particles = 95;                                  // Number of particles on the screen at the same time. Be CAREFUL with big numbers of particles, 1000 is already a lot!
            #elif complexity == 2
            static const int nb_particles = 160;
            #elif complexity == 3
            static const int nb_particles = 280;
            #elif complexity == 4
            static const int nb_particles = 500;
            #endif
            static const float2 gen_scale = float2(0.60, 0.45);                      // To scale the particle positions, not the particles themselves
            static const float2 middlepoint = float2(0.35, 0.15);                    // Offset of the particles

            // Particle movement constants
            static const float2 gravitation = float2(-0., -4.5);                     // Gravitation vector
            static const float3 main_x_freq = float3(0.4, 0.66, 0.78);               // 3 frequences (in Hz) of the harmonics of horizontal position of the main particle
            static const float3 main_x_amp = float3(0.8, 0.24, 0.18);                // 3 amplitudes of the harmonics of horizontal position of the main particle
            static const float3 main_x_phase = float3(0., 45., 55.);                 // 3 phases (in degrees) of the harmonics of horizontal position of the main particle
            static const float3 main_y_freq = float3(0.415, 0.61, 0.82);             // 3 frequences (in Hz) of the harmonics of vertical position of the main particle
            static const float3 main_y_amp = float3(0.72, 0.28, 0.15);	              // 3 amplitudes of the harmonics of vertical position of the main particle
            static const float3 main_y_phase = float3(90., 120., 10.);	              // 3 phases (in degrees) of the harmonics of vertical position of the main particle
            static const float part_timefact_min = 6.;                           // Specifies the minimum how many times the particle moves slower than the main particle when it's "launched"
            static const float part_timefact_max = 20.;                          // Specifies the maximum how many times the particle moves slower than the main particle when it's "launched"
            static const float2 part_max_mov = float2(0.28, 0.28);                   // Maxumum movement out of the trajectory in display units / s

            // Particle time constants
            static const float time_factor = 0.75;                               // Time in s factor, <1. for slow motion, >1. for faster movement
            static const float start_time = 2.5;                                 // Time in s needed until all the nb_particles are "launched"
            static const float grow_time_factor = 0.15;                          // Time in s particles need to reach their max intensity after they are "launched"
            #if complexity == 1
            static const float part_life_time_min = 0.9;                         // Minimum life time in s of a particle
            static const float part_life_time_max = 1.9;                         // Maximum life time in s of a particle
            #elif complexity == 2
            static const float part_life_time_min = 1.0;
            static const float part_life_time_max = 2.5;
            #elif complexity == 3
            static const float part_life_time_min = 1.1;
            static const float part_life_time_max = 3.2;
            #elif complexity == 4
            static const float part_life_time_min = 1.2;
            static const float part_life_time_max = 4.0;
            #endif

            // Particle intensity constants
            static const float part_int_div = 40000.;                            // Divisor of the particle intensity. Tweak this value to make the particles more or less bright
            static const float part_int_factor_min = 0.1;                        // Minimum initial intensity of a particle
            static const float part_int_factor_max = 3.2;                        // Maximum initial intensity of a particle
            static const float part_spark_min_int = 0.25;                        // Minimum sparkling intensity (factor of initial intensity) of a particle
            static const float part_spark_max_int = 0.88;                        // Minimum sparkling intensity (factor of initial intensity) of a particle
            static const float part_spark_min_freq = 2.5;                        // Minimum sparkling frequence in Hz of a particle
            static const float part_spark_max_freq = 6.0;                        // Maximum sparkling frequence in Hz of a particle
            static const float part_spark_time_freq_fact = 0.35;                 // Sparkling frequency factor at the end of the life of the particle
            static const float mp_int = 12.;                                     // Initial intensity of the main particle
            static const float dist_factor = 3.;                                 // Distance factor applied before calculating the intensity
            static const float ppow = 2.3;                                      // Exponent of the intensity in function of the distance

            // Particle color constants
            static const float part_min_hue = -0.13;                             // Minimum particle hue shift (spectrum width = 1.)
            static const float part_max_hue = 0.13;                              // Maximum particle hue shift (spectrum width = 1.)
            static const float part_min_saturation = 0.5;                        // Minimum particle saturation (0. to 1.)
            static const float part_max_saturation = 0.9;                        // Maximum particle saturation (0. to 1.)
            static const float hue_time_factor = 0.035;                          // Time-based hue shift
            static const float mp_hue = 0.5;                                     // Hue (shift) of the main particle
            static const float mp_saturation = 0.18;                             // Saturation (delta) of the main particle

            // Particle star constants
            static const float2 part_starhv_dfac = float2(9., 0.32);                 // x-y transformation vector of the distance to get the horizontal and vertical star branches
            static const float part_starhv_ifac = 0.25;                          // Intensity factor of the horizontal and vertical star branches
            static const float2 part_stardiag_dfac = float2(13., 0.61);              // x-y transformation vector of the distance to get the diagonal star branches
            static const float part_stardiag_ifac = 0.19;                        // Intensity factor of the diagonal star branches

            static const float mb_factor = 0.73;                                 // Mix factor for the multipass motion blur factor

            static float pst;
            static float plt;
            static float runnr;
            static float time2;
            static float time3;
            static float time4;
            float3 hsv2rgb(float3 hsv)
            {
                hsv.yz = clamp(hsv.yz, 0., 1.);
                return hsv.z*(0.63*hsv.y*(cos(twopi*(hsv.x+float3(0., 2./3., 1./3.)))-1.)+1.);
            }

            float random(float co)
            {
                return frac(sin(co*12.989)*43758.547);
            }

            float getParticleStartTime(int partnr)
            {
                return start_time*random(float(partnr*2));
            }

            float harms(float3 freq, float3 amp, float3 phase, float time)
            {
                float val = 0.;
                for (int h = 0;h<3; h++)
                val += amp[h]*cos(time*freq[h]*twopi+phase[h]/360.*twopi);
                return (1.+val)/2.;
            }

            float2 getParticlePosition(int partnr)
            {
                float part_timefact = lerp(part_timefact_min, part_timefact_max, random(float(partnr*2+94)+runnr*1.5));
                float ptime = (runnr*plt+pst)*(-1./part_timefact+1.)+time2/part_timefact;
                float2 ppos = float2(harms(main_x_freq, main_x_amp, main_x_phase, ptime), harms(main_y_freq, main_y_amp, main_y_phase, ptime))+middlepoint;
                float2 delta_pos = part_max_mov*(float2(random(float(partnr*3-23)+runnr*4.), random(float(partnr*7+632)-runnr*2.5))-0.5)*(time3-pst);
                float2 grav_pos = gravitation*pow(time4, 2.)/250.;
                return (ppos+delta_pos+grav_pos)*gen_scale;
            }

            float2 getParticlePosition_mp()
            {
                float2 ppos = float2(harms(main_x_freq, main_x_amp, main_x_phase, time2), harms(main_y_freq, main_y_amp, main_y_phase, time2))+middlepoint;
                return gen_scale*ppos;
            }

            float3 getParticleColor(int partnr, float pint)
            {
                float hue;
                float saturation;
                saturation = lerp(part_min_saturation, part_max_saturation, random(float(partnr*6+44)+runnr*3.3))*0.45/pint;
                hue = lerp(part_min_hue, part_max_hue, random(float(partnr+124)+runnr*1.5))+hue_time_factor*time2;
                return hsv2rgb(float3(hue, saturation, pint));
            }

            float3 getParticleColor_mp(float pint)
            {
                float hue;
                float saturation;
                saturation = 0.75/pow(pint, 2.5)+mp_saturation;
                hue = hue_time_factor*time2+mp_hue;
                return hsv2rgb(float3(hue, saturation, pint));
            }

            float3 drawParticles(float2 uv, float timedelta)
            {
                time2 = time_factor*(_Time.y+timedelta);
                float3 pcol = ((float3)0.);
                for (int i = 1;i<nb_particles; i++)
                {
                    pst = getParticleStartTime(i);
                    plt = lerp(part_life_time_min, part_life_time_max, random(float(i*2-35)));
                    time4 = glsl_mod(time2-pst, plt);
                    time3 = time4+pst;
                    runnr = floor((time2-pst)/plt);
                    float2 ppos = getParticlePosition(i);
                    float dist = distance(uv, ppos);
                    float2 uvppos = uv-ppos;
                    float distv = distance(uvppos*part_starhv_dfac+ppos, ppos);
                    float disth = distance(uvppos*part_starhv_dfac.yx+ppos, ppos);
                    float2 uvpposd = 0.707*float2(dot(uvppos, float2(1., 1.)), dot(uvppos, float2(1., -1.)));
                    float distd1 = distance(uvpposd*part_stardiag_dfac+ppos, ppos);
                    float distd2 = distance(uvpposd*part_stardiag_dfac.yx+ppos, ppos);
                    float pint0 = lerp(part_int_factor_min, part_int_factor_max, random(runnr*4.+float(i-55)));
                    float pint1 = 1./(dist*dist_factor+0.015)+part_starhv_ifac/(disth*dist_factor+0.01)+part_starhv_ifac/(distv*dist_factor+0.01)+part_stardiag_ifac/(distd1*dist_factor+0.01)+part_stardiag_ifac/(distd2*dist_factor+0.01);
                    float pint = pint0*(pow(pint1, ppow)/part_int_div)*(-time4/plt+1.);
                    pint *= smoothstep(0., grow_time_factor*plt, time4);
                    float sparkfreq = clamp(part_spark_time_freq_fact*time4, 0., 1.)*part_spark_min_freq+random(float(i*5+72)-runnr*1.8)*(part_spark_max_freq-part_spark_min_freq);
                    pint *= lerp(part_spark_min_int, part_spark_max_int, random(float(i*7-621)-runnr*12.))*sin(sparkfreq*twopi*time2)/2.+1.;
                    pcol += getParticleColor(i, pint);
                }
                float2 ppos = getParticlePosition_mp();
                float dist = distance(uv, ppos);
                float2 uvppos = uv-ppos;
                float distv = distance(uvppos*part_starhv_dfac+ppos, ppos);
                float disth = distance(uvppos*part_starhv_dfac.yx+ppos, ppos);
                float2 uvpposd = 0.7071*float2(dot(uvppos, float2(1., 1.)), dot(uvppos, float2(1., -1.)));
                float distd1 = distance(uvpposd*part_stardiag_dfac+ppos, ppos);
                float distd2 = distance(uvpposd*part_stardiag_dfac.yx+ppos, ppos);
                float pint1 = 1./(dist*dist_factor+0.015)+part_starhv_ifac/(disth*dist_factor+0.01)+part_starhv_ifac/(distv*dist_factor+0.01)+part_stardiag_ifac/(distd1*dist_factor+0.01)+part_stardiag_ifac/(distd2*dist_factor+0.01);
                if (part_int_factor_max*pint1>6.)
                {
                    float pint = part_int_factor_max*(pow(pint1, ppow)/part_int_div)*mp_int;
                    pcol += getParticleColor_mp(pint);
                }
                
                return pcol;
            }

            float4 frag (v2f i) : SV_Target
            {
                float2 fragCoord = i.uv * _Resolution;
                float2 uv = fragCoord.xy/iResolution.xx;
                float2 uv2 = fragCoord.xy/iResolution.xy;
                float3 pcolor = tex2D(_MainTex, uv2).rgb*mb_factor;
                pcolor += drawParticles(uv, 0.)*0.9;
                float4 fragColor = float4(pcolor, 0.);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}
