// https://www.shadertoy.com/view/4tc3WB
Shader "Unlit/Shaderdough"
{
    Properties
    {
        [Header(General)]
        _Mouse ("Mouse", Vector) = (0.5, 0.5, 0.5, 0.5)
        [ToggleUI] _GammaCorrect ("Gamma Correction", Float) = 1
        _Resolution ("Resolution (Change if AA is bad)", Range(1, 1024)) = 1
        [ToggleUI] _ScreenEffect("ScreenEffect", Float) = 0

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
            float4 _Mouse;
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

            // --------------------------------------------------------
            // OPTIONS
            // --------------------------------------------------------

            // Disable to see more colour variety
            #define SEAMLESS_LOOP
            //#define COLOUR_CYCLE

            #define PI 3.14159265359
            #define PHI (1.618033988749895)

            float t;

            #define saturate(x) clamp(x, 0., 1.)

            // --------------------------------------------------------
            // http://www.neilmendoza.com/glsl-rotation-about-an-arbitrary-axis/
            // --------------------------------------------------------

            float3x3 rotationMatrix(float3 axis, float angle)
            {
                axis = normalize(axis);
                float s = sin(angle);
                float c = cos(angle);
                float oc = 1.0 - c;

                return float3x3(
                    oc * axis.x * axis.x + c, oc * axis.x * axis.y - axis.z * s, oc * axis.z * axis.x + axis.y * s,
                    oc * axis.x * axis.y + axis.z * s, oc * axis.y * axis.y + c, oc * axis.y * axis.z - axis.x * s,
                    oc * axis.z * axis.x - axis.y * s, oc * axis.y * axis.z + axis.x * s, oc * axis.z * axis.z + c
                );
            }


            // --------------------------------------------------------
            // http://math.stackexchange.com/a/897677
            // --------------------------------------------------------

            float3x3 orientMatrix(float3 A, float3 B)
            {
                float3x3 Fi = float3x3(
                    A,
                    (B - dot(A, B) * A) / length(B - dot(A, B) * A),
                    cross(B, A)
                );
                float3x3 G = float3x3(
                    dot(A, B), -length(cross(A, B)), 0,
                    length(cross(A, B)), dot(A, B), 0,
                    0, 0, 1
                );
                // return Fi * G * inverse(Fi);
                return mul(mul(Fi, G), transpose(Fi));
            }


            // --------------------------------------------------------
            // HG_SDF
            // https://www.shadertoy.com/view/Xs3GRB
            // --------------------------------------------------------

            #define GDFVector3 normalize(float3(1, 1, 1 ))
            #define GDFVector3b normalize(float3(-1, -1, -1 ))
            #define GDFVector4 normalize(float3(-1, 1, 1))
            #define GDFVector4b normalize(float3(-1, -1, 1))
            #define GDFVector5 normalize(float3(1, -1, 1))
            #define GDFVector5b normalize(float3(1, -1, -1))
            #define GDFVector6 normalize(float3(1, 1, -1))
            #define GDFVector6b normalize(float3(-1, 1, -1))

            #define GDFVector7 normalize(float3(0, 1, PHI+1.))
            #define GDFVector7b normalize(float3(0, 1, -PHI-1.))
            #define GDFVector8 normalize(float3(0, -1, PHI+1.))
            #define GDFVector8b normalize(float3(0, -1, -PHI-1.))
            #define GDFVector9 normalize(float3(PHI+1., 0, 1))
            #define GDFVector9b normalize(float3(PHI+1., 0, -1))
            #define GDFVector10 normalize(float3(-PHI-1., 0, 1))
            #define GDFVector10b normalize(float3(-PHI-1., 0, -1))
            #define GDFVector11 normalize(float3(1, PHI+1., 0))
            #define GDFVector11b normalize(float3(1, -PHI-1., 0))
            #define GDFVector12 normalize(float3(-1, PHI+1., 0))
            #define GDFVector12b normalize(float3(-1, -PHI-1., 0))

            #define GDFVector13 normalize(float3(0, PHI, 1))
            #define GDFVector13b normalize(float3(0, PHI, -1))
            #define GDFVector14 normalize(float3(0, -PHI, 1))
            #define GDFVector14b normalize(float3(0, -PHI, -1))
            #define GDFVector15 normalize(float3(1, 0, PHI))
            #define GDFVector15b normalize(float3(1, 0, -PHI))
            #define GDFVector16 normalize(float3(-1, 0, PHI))
            #define GDFVector16b normalize(float3(-1, 0, -PHI))
            #define GDFVector17 normalize(float3(PHI, 1, 0))
            #define GDFVector17b normalize(float3(PHI, -1, 0))
            #define GDFVector18 normalize(float3(-PHI, 1, 0))
            #define GDFVector18b normalize(float3(-PHI, -1, 0))

            #define fGDFBegin float d = 0.;

            // Version with variable exponent.
            // This is slow and does not produce correct distances, but allows for bulging of objects.
            #define fGDFExp(v) d += pow(abs(dot(p, v)), e);

            // Version with without exponent, creates objects with sharp edges and flat faces
            #define fGDF(v) d = max(d, abs(dot(p, v)));

            #define fGDFExpEnd return pow(d, 1./e) - r;
            #define fGDFEnd return d - r;

            // Primitives follow:

            float fDodecahedron(float3 p, float r)
            {
                fGDFBegin
                fGDF(GDFVector13)
                fGDF(GDFVector14)
                fGDF(GDFVector15)
                fGDF(GDFVector16)
                fGDF(GDFVector17)
                fGDF(GDFVector18)
                fGDFEnd
            }

            float fIcosahedron(float3 p, float r)
            {
                fGDFBegin
                fGDF(GDFVector3)
                fGDF(GDFVector4)
                fGDF(GDFVector5)
                fGDF(GDFVector6)
                fGDF(GDFVector7)
                fGDF(GDFVector8)
                fGDF(GDFVector9)
                fGDF(GDFVector10)
                fGDF(GDFVector11)
                fGDF(GDFVector12)
                fGDFEnd
            }

            float vmax(float3 v)
            {
                return max(max(v.x, v.y), v.z);
            }

            float sgn(float x)
            {
                return (x < 0.) ? -1. : 1.;
            }

            // Plane with normal n (n is normalized) at some distance from the origin
            float fPlane(float3 p, float3 n, float distanceFromOrigin)
            {
                return dot(p, n) + distanceFromOrigin;
            }

            // Box: correct distance to corners
            float fBox(float3 p, float3 b)
            {
                float3 d = abs(p) - b;
                return length(max(d, (float3)0)) + vmax(min(d, (float3)0));
            }

            // Distance to line segment between <a> and <b>, used for fCapsule() version 2below
            float fLineSegment(float3 p, float3 a, float3 b)
            {
                float3 ab = b - a;
                float t = saturate(dot(p - a, ab) / dot(ab, ab));
                return length((ab * t + a) - p);
            }

            // Capsule version 2: between two end points <a> and <b> with radius r 
            float fCapsule(float3 p, float3 a, float3 b, float r)
            {
                return fLineSegment(p, a, b) - r;
            }

            // Rotate around a coordinate axis (i.e. in a plane perpendicular to that axis) by angle <a>.
            // Read like this: R(p.xz, a) rotates "x towards z".
            // This is fast if <a> is a compile-time constant and slower (but still practical) if not.
            void pR(inout float2 p, float a)
            {
                p = cos(a) * p + sin(a) * float2(p.y, -p.x);
            }

            // Reflect space at a plane
            float pReflect(inout float3 p, float3 planeNormal, float offset)
            {
                float t = dot(p, planeNormal) + offset;
                if (t < 0.)
                {
                    p = p - (2. * t) * planeNormal;
                }
                return sign(t);
            }

            // Repeat around the origin by a fixed angle.
            // For easier use, num of repetitions is use to specify the angle.
            float pModPolar(inout float2 p, float repetitions)
            {
                float angle = 2. * PI / repetitions;
                float a = atan2(p.x, p.y) + angle / 2.;
                float r = length(p);
                float c = floor(a / angle);
                a = glsl_mod(a, angle) - angle / 2.;
                p = float2(cos(a), sin(a)) * r;
                // For an odd number of repetitions, fix cell index of the cell in -x direction
                // (cell index would be e.g. -5 and 5 in the two halves of the cell):
                if (abs(c) >= (repetitions / 2.)) c = abs(c);
                return c;
            }

            // Repeat around an axis
            void pModPolar(inout float3 p, float3 axis, float repetitions, float offset)
            {
                float3 z = float3(0, 0, 1);
                float3x3 m = orientMatrix(axis, z);
                // p *= inverse(m);
                p = mul(transpose(m), p);
                pR(p.xy, offset);
                pModPolar(p.xy, repetitions);
                pR(p.xy, -offset);
                // p *= m;
                p = mul(m, p);
            }


            // --------------------------------------------------------
            // knighty
            // https://www.shadertoy.com/view/MsKGzw
            // --------------------------------------------------------

            int Type = 5;
            float3 nc;
            float3 pbc;
            float3 pca;

            void initIcosahedron()
            {
                //setup folding planes and vertex
                float cospin = cos(PI / float(Type)), scospin = sqrt(0.75 - cospin * cospin);
                nc = float3(-0.5, -cospin, scospin); //3rd folding plane. The two others are xz and yz planes
                pbc = float3(scospin, 0., 0.5);
                //No normalization in order to have 'barycentric' coordinates work evenly
                pca = float3(0., scospin, cospin);
                pbc = normalize(pbc);
                pca = normalize(pca); //for slightly better DE. In reality it's not necesary to apply normalization :) 
            }

            void pModIcosahedron(inout float3 p)
            {
                p = abs(p);
                pReflect(p, nc, 0.);
                p.xy = abs(p.xy);
                pReflect(p, nc, 0.);
                p.xy = abs(p.xy);
                pReflect(p, nc, 0.);
            }

            float indexSgn(float s)
            {
                return s / 2. + 0.5;
            }

            bool boolSgn(float s)
            {
                return bool(s / 2. + 0.5);
            }

            float pModIcosahedronIndexed(inout float3 p, int subdivisions)
            {
                float x = indexSgn(sgn(p.x));
                float y = indexSgn(sgn(p.y));
                float z = indexSgn(sgn(p.z));
                p = abs(p);
                pReflect(p, nc, 0.);

                float xai = sgn(p.x);
                float yai = sgn(p.y);
                p.xy = abs(p.xy);
                float sideBB = pReflect(p, nc, 0.);

                float ybi = sgn(p.y);
                float xbi = sgn(p.x);
                p.xy = abs(p.xy);
                pReflect(p, nc, 0.);

                float idx = 0.;

                float faceGroupAi = indexSgn(ybi * yai * -1.);
                float faceGroupBi = indexSgn(yai);
                float faceGroupCi = clamp((xai - ybi - 1.), 0., 1.);
                float faceGroupDi = clamp(1. - faceGroupAi - faceGroupBi - faceGroupCi, 0., 1.);

                idx += faceGroupAi * (x + (2. * y) + (4. * z));
                idx += faceGroupBi * (8. + y + (2. * z));
                # ifndef SEAMLESS_LOOP
    	        idx += faceGroupCi * (12. + x + (2. * z));
                # endif
                idx += faceGroupDi * (12. + x + (2. * y));

                return idx;
            }


            // --------------------------------------------------------
            // IQ
            // https://www.shadertoy.com/view/ll2GD3
            // --------------------------------------------------------

            float3 pal(in float t, in float3 a, in float3 b, in float3 c, in float3 d)
            {
                return a + b * cos(6.28318 * (c * t + d));
            }

            float3 spectrum(float n)
            {
                return pal(n, float3(0.5, 0.5, 0.5), float3(0.5, 0.5, 0.5), float3(1.0, 1.0, 1.0),
                           float3(0.0, 0.33, 0.67));
            }


            // --------------------------------------------------------
            // tdhooper
            // https://www.shadertoy.com/view/Mtc3RX
            // --------------------------------------------------------

            float3 vMin(float3 p, float3 a, float3 b, float3 c)
            {
                float la = length(p - a);
                float lb = length(p - b);
                float lc = length(p - c);
                if (la < lb)
                {
                    if (la < lc)
                    {
                        return a;
                    }
                    else
                    {
                        return c;
                    }
                }
                else
                {
                    if (lb < lc)
                    {
                        return b;
                    }
                    else
                    {
                        return c;
                    }
                }
            }

            // Nearest icosahedron vertex
            float3 icosahedronVertex(float3 p)
            {
                if (p.z > 0.)
                {
                    if (p.x > 0.)
                    {
                        if (p.y > 0.)
                        {
                            return vMin(p, GDFVector13, GDFVector15, GDFVector17);
                        }
                        else
                        {
                            return vMin(p, GDFVector14, GDFVector15, GDFVector17b);
                        }
                    }
                    else
                    {
                        if (p.y > 0.)
                        {
                            return vMin(p, GDFVector13, GDFVector16, GDFVector18);
                        }
                        else
                        {
                            return vMin(p, GDFVector14, GDFVector16, GDFVector18b);
                        }
                    }
                }
                else
                {
                    if (p.x > 0.)
                    {
                        if (p.y > 0.)
                        {
                            return vMin(p, GDFVector13b, GDFVector15b, GDFVector17);
                        }
                        else
                        {
                            return vMin(p, GDFVector14b, GDFVector15b, GDFVector17b);
                        }
                    }
                    else
                    {
                        if (p.y > 0.)
                        {
                            return vMin(p, GDFVector13b, GDFVector16b, GDFVector18);
                        }
                        else
                        {
                            return vMin(p, GDFVector14b, GDFVector16b, GDFVector18b);
                        }
                    }
                }
            }

            // Nearest vertex and distance.
            // Distance is roughly to the boundry between the nearest and next
            // nearest icosahedron vertices, ensuring there is always a smooth
            // join at the edges, and normalised from 0 to 1
            float4 icosahedronAxisDistance(float3 p)
            {
                float3 iv = icosahedronVertex(p);
                float3 originalIv = iv;

                float3 pn = normalize(p);
                pModIcosahedron(pn);
                pModIcosahedron(iv);

                float boundryDist = dot(pn, float3(1, 0, 0));
                float boundryMax = dot(iv, float3(1, 0, 0));
                boundryDist /= boundryMax;

                float roundDist = length(iv - pn);
                float roundMax = length(iv - float3(0, 0, 1.));
                roundDist /= roundMax;
                roundDist = -roundDist + 1.;

                float blend = 1. - boundryDist;
                blend = pow(blend, 6.);

                float dist = lerp(roundDist, boundryDist, blend);

                return float4(originalIv, dist);
            }

            // Twists p around the nearest icosahedron vertex
            void pTwistIcosahedron(inout float3 p, float amount)
            {
                float4 a = icosahedronAxisDistance(p);
                float3 axis = a.xyz;
                float dist = a.a;
                float3x3 m = rotationMatrix(axis, dist * amount);
                p = mul(m, p);
            }


            // --------------------------------------------------------
            // MAIN
            // --------------------------------------------------------

            struct Model
            {
                float dist;
                float3 colour;
                float id;
            };

            Model fInflatedIcosahedron(float3 p, float3 axis)
            {
                float d = 1000.;

                # ifdef SEAMLESS_LOOP
                // Radially repeat along the rotation axis, so the
                // colours repeat more frequently and we can use
                // less frames for a seamless loop
                pModPolar(p, axis, 3., PI / 2.);
                # endif

                // Slightly inflated icosahedron
                float idx = pModIcosahedronIndexed(p, 0);
                d = min(d, dot(p, pca) - .9);
                d = lerp(d, length(p) - .9, .5);

                // Colour each icosahedron face differently
                # ifdef SEAMLESS_LOOP
                if (idx == 3.)
                {
                    idx = 2.;
                }
                idx /= 10.;
                # else
    	        idx /= 20.;
                # endif
                # ifdef COLOUR_CYCLE
    	        idx = mod(idx + t*1.75, 1.);
                # endif
                float3 colour = spectrum(idx);

                d *= .6;
                Model model;
                model.dist = d;
                model.colour = colour;
                model.id = 1;
                return model;
            }

            void pTwistIcosahedron(inout float3 p, float3 center, float amount)
            {
                p += center;
                pTwistIcosahedron(p, 5.5);
                p -= center;
            }

            Model model(float3 p)
            {
                float rate = PI / 6.;
                float3 axis = pca;

                float3 twistCenter = (float3)0;
                twistCenter.x = cos(t * rate * -3.) * .3;
                twistCenter.y = sin(t * rate * -3.) * .3;

                float3x3 m = rotationMatrix(
                    reflect(axis, float3(0, 1, 0)),
                    t * -rate
                );
                p = mul(m, p);
                twistCenter = mul(m, twistCenter);

                pTwistIcosahedron(p, twistCenter, 5.5);

                return fInflatedIcosahedron(p, axis);
            }


            // The MINIMIZED version of https://www.shadertoy.com/view/Xl2XWt


            const float MAX_TRACE_DISTANCE = 30.0; // max trace distance
            const float INTERSECTION_PRECISION = 0.001; // precision of the intersection
            const int NUM_OF_TRACE_STEPS = 100;


            // checks to see which intersection is closer
            // and makes the y of the float2 be the proper id
            float2 opU(float2 d1, float2 d2)
            {
                return (d1.x < d2.x) ? d1 : d2;
            }

            //--------------------------------
            // Modelling
            //--------------------------------
            Model map(float3 p)
            {
                return model(p);
            }

            // LIGHTING

            float softshadow(in float3 ro, in float3 rd, in float mint, in float tmax)
            {
                float res = 1.0;
                float t = mint;
                for (int i = 0; i < 16; i++)
                {
                    float h = map(ro + rd * t).dist;
                    res = min(res, 8.0 * h / t);
                    t += clamp(h, 0.02, 0.10);
                    if (h < 0.001 || t > tmax) break;
                }
                return clamp(res, 0.0, 1.0);
            }


            float calcAO(in float3 pos, in float3 nor)
            {
                float occ = 0.0;
                float sca = 1.0;
                for (int i = 0; i < 5; i++)
                {
                    float hr = 0.01 + 0.12 * float(i) / 4.0;
                    float3 aopos = nor * hr + pos;
                    float dd = map(aopos).dist;
                    occ += -(dd - hr) * sca;
                    sca *= 0.95;
                }
                return clamp(1.0 - 3.0 * occ, 0.0, 1.0);
            }

            const float GAMMA = 2.2;

            float3 gamma(float3 color, float g)
            {
                return pow(color, (float3)g);
            }

            float3 linearToScreen(float3 linearRGB)
            {
                return gamma(linearRGB, 1.0 / GAMMA);
            }

            float3 doLighting(float3 col, float3 pos, float3 nor, float3 ref, float3 rd)
            {
                // lighitng        
                float occ = calcAO(pos, nor);
                float3 lig = normalize(float3(-0.6, 0.7, 0.5));
                float amb = clamp(0.5 + 0.5 * nor.y, 0.0, 1.0);
                float dif = clamp(dot(nor, lig), 0.0, 1.0);
                float bac = clamp(dot(nor, normalize(float3(-lig.x, 0.0, -lig.z))), 0.0, 1.0) * clamp(
                    1.0 - pos.y, 0.0, 1.0);
                //float dom = smoothstep( -0.1, 0.1, ref.y );
                float fre = pow(clamp(1.0 + dot(nor, rd), 0.0, 1.0), 2.0);
                //float spe = pow(clamp( dot( ref, lig ), 0.0, 1.0 ),16.0);

                dif *= softshadow(pos, lig, 0.02, 2.5);
                //dom *= softshadow( pos, ref, 0.02, 2.5 );

                float3 lin = (float3)0.0;
                lin += 1.20 * dif * float3(.95, 0.80, 0.60);
                //lin += 1.20*spe*float3(1.00,0.85,0.55)*dif;
                lin += 0.80 * amb * float3(0.50, 0.70, .80) * occ;
                //lin += 0.30*dom*float3(0.50,0.70,1.00)*occ;
                lin += 0.30 * bac * float3(0.25, 0.25, 0.25) * occ;
                lin += 0.20 * fre * float3(1.00, 1.00, 1.00) * occ;
                col = col * lin;

                return col;
            }

            struct Hit
            {
                float len;
                float3 colour;
                float id;
            };

            Hit calcIntersection(in float3 ro, in float3 rd)
            {
                float h = INTERSECTION_PRECISION * 2.0;
                float t = 0.0;
                float res = -1.0;
                float id = -1.;
                float3 colour;

                for (int i = 0; i < NUM_OF_TRACE_STEPS; i++)
                {
                    if (abs(h) < INTERSECTION_PRECISION || t > MAX_TRACE_DISTANCE) break;
                    Model m = map(ro + rd * t);
                    h = m.dist;
                    t += h;
                    id = m.id;
                    colour = m.colour;
                }

                if (t < MAX_TRACE_DISTANCE) res = t;
                if (t > MAX_TRACE_DISTANCE) id = -1.0;

                Hit hit;
                hit.len = res;
                hit.colour = colour;
                hit.id = id;
                return hit;
            }


            //----
            // Camera Stuffs
            //----
            float3x3 calcLookAtMatrix(in float3 ro, in float3 ta, in float roll)
            {
                float3 ww = normalize(ta - ro);
                float3 uu = normalize(cross(ww, float3(sin(roll), cos(roll), 0.0)));
                float3 vv = normalize(cross(uu, ww));
                return float3x3(uu, vv, ww);
            }

            void doCamera(out float3 camPos, out float3 camTar, out float camRoll, in float time, in float2 mouse)
            {
                float x = mouse.x;
                float y = mouse.y;

                x = .65;
                y = .44;

                float dist = 3.3;
                float height = 0.;
                camPos = float3(0, 0, -dist);
                float3 axisY = float3(0, 1, 0);
                float3 axisX = float3(1, 0, 0);
                float3x3 m = rotationMatrix(axisY, -x * PI * 2.);
                axisX = mul(m, axisX);
                camPos = mul(m, camPos);
                m = rotationMatrix(axisX, -(y - .5) * PI * 2.);
                camPos = mul(m, camPos);
                camPos.y += height;
                camTar = -camPos + (float3).0001;
                camTar.y += height;
                camRoll = 0.;
            }

            // Calculates the normal by taking a very small distance,
            // remapping the function, and getting normal for that
            float3 calcNormal(in float3 pos)
            {
                float3 eps = float3(0.001, 0.0, 0.0);
                float3 nor = float3(
                    map(pos + eps.xyy).dist - map(pos - eps.xyy).dist,
                    map(pos + eps.yxy).dist - map(pos - eps.yxy).dist,
                    map(pos + eps.yyx).dist - map(pos - eps.yyx).dist);
                return normalize(nor);
            }

            float2 ffragCoord;

            float3 render(Hit hit, float3 ro, float3 rd)
            {
                float3 pos = ro + rd * hit.len;

                float3 color = float3(.04, .045, .05);
                color = float3(.35, .5, .65);
                float3 colorB = float3(.8, .8, .9);

                float2 pp;

                if (_ScreenEffect)
                {
                    pp = (-_ScreenParams.xy + 2.0 * ffragCoord.xy) / _ScreenParams.y;
                }
                else
                {
                    pp = (-iResolution.xy + 2.0 * ffragCoord.xy) / iResolution.y;
                }

                color = lerp(colorB, color, length(pp) / 1.5);


                if (hit.id == 1.)
                {
                    float3 norm = calcNormal(pos);
                    float3 ref = reflect(rd, norm);
                    color = doLighting(hit.colour, pos, norm, ref, rd);
                }

                return color;
            }

            float4 frag(v2f i) : SV_Target
            {
                initIcosahedron();
                t = _Time.y - .25;

                float2 fragCoord;
                float2 p;
                float2 m;
                if (_ScreenEffect)
                {
                    fragCoord = i.uv * _ScreenParams;
                    p = (_ScreenParams.xy + 2.0 * fragCoord.xy) / _ScreenParams.y;
                    m = _Mouse.xy / _ScreenParams.xy;
                }
                else
                {
                    fragCoord = i.uv * iResolution;
                    p = (iResolution.xy + 2.0 * fragCoord.xy) / iResolution.y;
                    m = _Mouse.xy / _ScreenParams.xy;
                }
                
                ffragCoord = fragCoord;
                 

                float3 camPos = float3(0., 0., 2.);
                float3 camTar = float3(0., 0., 0.);
                float camRoll = 0.;

                // camera movement
                doCamera(camPos, camTar, camRoll, _Time.y, m);

                // camera matrix
                float3x3 camMat = calcLookAtMatrix(camPos, camTar, camRoll); // 0.0 is the camera roll

                // create view ray
                float3 rd = normalize(mul(camMat, float3(p.xy, 2.0))); // 2.0 is the lens length

                Hit hit = calcIntersection(camPos, rd);


                float3 color = render(hit, camPos, rd);
                color = linearToScreen(color);

                float4 fragColor = float4(color, 1.0);
                return fragColor;
            }
            ENDCG
        }
    }
}