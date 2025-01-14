﻿// https://www.shadertoy.com/view/llVXRd
Shader "Unlit/GeodesicTiling"
{
    Properties
    {
        _Mouse ("Mouse", Vector) = (0.5, 0.5, 0.5, 0.5)
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
            float4 _Mouse;
            float _GammaCorrect;
            float _Resolution;

            // GLSL Compatability macros
            #define glsl_mod(x,y) (((x)-(y)*floor((x)/(y))))
            #define iResolution float3(_Resolution, _Resolution, _Resolution)
            #define iChannelTime float4(_Time.y, _Time.y, _Time.y, _Time.y)

            // Global access to uv data
            static v2f vertex_output;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            #define MODEL_ROTATION float2(0.3, 0.25)
            #define CAMERA_ROTATION float2(0.5, 0.5)
            #define MOUSE_CONTROL 1

            void pR(inout float2 p, float a)
            {
                p = cos(a) * p + sin(a) * float2(p.y, -p.x);
            }

            float pReflect(inout float3 p, float3 planeNormal, float offset)
            {
                float t = dot(p, planeNormal) + offset;
                if (t < 0.)
                {
                    p = p - 2. * t * planeNormal;
                }

                return sign(t);
            }

            float smax(float a, float b, float r)
            {
                float m = max(a, b);
                if (-a < r && -b < r)
                {
                    return max(m, -(r - sqrt((r + a) * (r + a) + (r + b) * (r + b))));
                }
                else
                {
                    return m;
                }
            }

            #define PI 3.1415927
            static float3 facePlane;
            static float3 uPlane;
            static float3 vPlane;
            static int Type = 5;
            static float3 nc;
            static float3 pab;
            static float3 pbc;
            static float3 pca;

            void initIcosahedron()
            {
                float cospin = cos(PI / float(Type)), scospin = sqrt(0.75 - cospin * cospin);
                nc = float3(-0.5, -cospin, scospin);
                pbc = float3(scospin, 0., 0.5);
                pca = float3(0., scospin, cospin);
                pbc = normalize(pbc);
                pca = normalize(pca);
                pab = float3(0, 0, 1);
                facePlane = pca;
                uPlane = cross(float3(1, 0, 0), facePlane);
                vPlane = float3(1, 0, 0);
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

            static const float sqrt3 = 1.7320508;
            static const float i3 = 0.57735026;
            static const float2x2 cart2hex = transpose(float2x2(1, 0, i3, 2. * i3));
            static const float2x2 hex2cart = transpose(float2x2(1, 0, -0.5, 0.5 * sqrt3));
            #define PHI (1.618034)
            #define TAU 6.2831855

            struct TriPoints
            {
                float2 a;
                float2 b;
                float2 c;
                float2 center;
                float2 ab;
                float2 bc;
                float2 ca;
            };

            TriPoints closestTriPoints(float2 p)
            {
                float2 pTri = mul(cart2hex, p);
                float2 pi = floor(pTri);
                float2 pf = frac(pTri);
                float split1 = step(pf.y, pf.x);
                float split2 = step(pf.x, pf.y);
                float2 a = float2(split1, 1);
                float2 b = float2(1, split2);
                float2 c = float2(0, 0);
                a += pi;
                b += pi;
                c += pi;
                a = mul(hex2cart, a);
                b = mul(hex2cart, b);
                c = mul(hex2cart, c);
                float2 center = (a + b + c) / 3.;
                float2 ab = (a + b) / 2.;
                float2 bc = (b + c) / 2.;
                float2 ca = (c + a) / 2.;
                TriPoints triPoints;
                triPoints.a = a;
                triPoints.b = b;
                triPoints.c = c;
                triPoints.center = center;
                triPoints.ab = ab;
                triPoints.bc = bc;
                triPoints.ca = ca;
                return triPoints;
            }

            struct TriPoints3D
            {
                float3 a;
                float3 b;
                float3 c;
                float3 center;
                float3 ab;
                float3 bc;
                float3 ca;
            };

            float3 intersection(float3 n, float3 planeNormal, float planeOffset)
            {
                float denominator = dot(planeNormal, n);
                float t = (dot(((float3)0), planeNormal) + planeOffset) / -denominator;
                return n * t;
            }

            static float faceRadius = 0.38196602;

            float2 icosahedronFaceCoordinates(float3 p)
            {
                float3 pn = normalize(p);
                float3 i = intersection(pn, facePlane, -1.);
                return float2(dot(i, uPlane), dot(i, vPlane));
            }

            float3 faceToSphere(float2 facePoint)
            {
                return normalize(facePlane + uPlane * facePoint.x + vPlane * facePoint.y);
            }
 
            TriPoints3D geodesicTriPoints(float3 p, float subdivisions)
            {
                float2 uv = icosahedronFaceCoordinates(p);
                float uvScale = subdivisions / faceRadius / 2.;
                TriPoints points = closestTriPoints(uv * uvScale);
                float3 a = faceToSphere(points.a / uvScale);
                float3 b = faceToSphere(points.b / uvScale);
                float3 c = faceToSphere(points.c / uvScale);
                float3 center = faceToSphere(points.center / uvScale);
                float3 ab = faceToSphere(points.ab / uvScale);
                float3 bc = faceToSphere(points.bc / uvScale);
                float3 ca = faceToSphere(points.ca / uvScale);
                TriPoints3D triPoints3D;
                triPoints3D.a = a;
                triPoints3D.b = b;
                triPoints3D.c = c;
                triPoints3D.center = center;
                triPoints3D.ab = ab;
                triPoints3D.bc = bc;
                triPoints3D.ca = ca;
                return triPoints3D;
            }

            float3 pal(in float t, in float3 a, in float3 b, in float3 c, in float3 d)
            {
                return a + b * cos(6.28318 * (c * t + d));
            }

            float3 spectrum(float n)
            {
                return pal(n, float3(0.5, 0.5, 0.5), float3(0.5, 0.5, 0.5), float3(1., 1., 1.), float3(0., 0.33, 0.67));
            }

            float3x3 sphericalMatrix(float theta, float phi)
            {
                float cx = cos(theta);
                float cy = cos(phi);
                float sx = sin(theta);
                float sy = sin(phi);
                return transpose(float3x3(cy, -sy * -sx, -sy * cx, 0, cx, sx, sy, cy * -sx, cy * cx));
            }

            float3x3 mouseRotation(bool enable, float2 xy)
            {
                if (enable)
                {
                    float2 mouse = _Mouse.xy / iResolution.xy;
                    if (mouse.x != 0. && mouse.y != 0.)
                    {
                        xy.x = mouse.x;
                        xy.y = mouse.y;
                    }
                }

                float rx, ry;
                rx = (xy.y + 0.5) * PI;
                ry = -xy.x * 2. * PI;
                return sphericalMatrix(rx, ry);
            }

            float3x3 modelRotation()
            {
                float3x3 m = mouseRotation(MOUSE_CONTROL == 1, MODEL_ROTATION);
                return m;
            }

            float3x3 cameraRotation()
            {
                float3x3 m = mouseRotation(MOUSE_CONTROL == 2, CAMERA_ROTATION);
                return m;
            }

            static const float SCENE_DURATION = 6.;
            static const float CROSSFADE_DURATION = 2.;
            static float time;

            struct HexSpec
            {
                float roundTop;
                float roundCorner;
                float height;
                float thickness;
                float gap;
            };

            HexSpec newHexSpec(float subdivisions)
            {
                HexSpec hexSpec;
                hexSpec.roundTop = 0.05 / subdivisions;
                hexSpec.roundCorner = 0.1 / subdivisions;
                hexSpec.height = 2;
                hexSpec.thickness = 2;
                hexSpec.gap = 0.005;
                return hexSpec;
            }

            float animSubdivisions1()
            {
                return lerp(2.4, 3.4, cos(time * PI) * 0.5 + 0.5);
            }

            HexSpec animHex1(float3 hexCenter, float subdivisions)
            {
                HexSpec spec = newHexSpec(subdivisions);
                float offset = time * 3. * PI;
                offset -= subdivisions;
                float blend = dot(hexCenter, pca);
                blend = cos(blend * 30. + offset) * 0.5 + 0.5;
                spec.height = lerp(1.75, 2., blend);
                spec.thickness = spec.height;
                return spec;
            }

            float animSubdivisions2()
            {
                return lerp(1., 2.3, sin(time * PI / 2.) * 0.5 + 0.5);
            }

            HexSpec animHex2(float3 hexCenter, float subdivisions)
            {
                HexSpec spec = newHexSpec(subdivisions);
                float blend = hexCenter.y;
                spec.height = lerp(1.6, 2., sin(blend * 10. + time * PI) * 0.5 + 0.5);
                spec.roundTop = 0.02 / subdivisions;
                spec.roundCorner = 0.09 / subdivisions;
                spec.thickness = spec.roundTop * 4.;
                spec.gap = 0.01;
                return spec;
            }

            float animSubdivisions3()
            {
                return 5.;
            }

            HexSpec animHex3(float3 hexCenter, float subdivisions)
            {
                HexSpec spec = newHexSpec(subdivisions);
                float blend = acos(dot(hexCenter, pab)) * 10.;
                blend = cos(blend + time * PI) * 0.5 + 0.5;
                spec.gap = lerp(0.01, 0.4, blend) / subdivisions;
                spec.thickness = spec.roundTop * 2.;
                return spec;
            }

            float sineInOut(float t)
            {
                return -0.5 * (cos(PI * t) - 1.);
            }

            float transitionValues(float a, float b, float c)
            {
                #ifdef LOOP
                #if LOOP == 1
                return a;
                #endif
                #if LOOP == 2
                return b;
                #endif
                #if LOOP == 3
                return c;
                #endif
                #endif
                float t = time / SCENE_DURATION;
                float scene = floor(glsl_mod(t, 3.));
                float blend = frac(t);
                float delay = (SCENE_DURATION - CROSSFADE_DURATION) / SCENE_DURATION;
                blend = max(blend - delay, 0.) / (1. - delay);
                blend = sineInOut(blend);
                float ab = lerp(a, b, blend);
                float bc = lerp(b, c, blend);
                float cd = lerp(c, a, blend);
                float result = lerp(ab, bc, min(scene, 1.));
                result = lerp(result, cd, max(scene - 1., 0.));
                return result;
            }

            HexSpec transitionHexSpecs(HexSpec a, HexSpec b, HexSpec c)
            {
                float roundTop = transitionValues(a.roundTop, b.roundTop, c.roundTop);
                float roundCorner = transitionValues(a.roundCorner, b.roundCorner, c.roundCorner);
                float height = transitionValues(a.height, b.height, c.height);
                float thickness = transitionValues(a.thickness, b.thickness, c.thickness);
                float gap = transitionValues(a.gap, b.gap, c.gap);
                HexSpec hexSpec;
                hexSpec.roundTop = roundTop;
                hexSpec.roundCorner = roundCorner;
                hexSpec.height = height;
                hexSpec.thickness = thickness;
                hexSpec.gap = gap;
                return hexSpec;
            }

            static const float3 FACE_COLOR = float3(0.9, 0.9, 1.);
            static const float3 BACK_COLOR = float3(0.1, 0.1, 0.15);
            static const float3 BACKGROUND_COLOR = float3(0., 0.005, 0.03);

            struct Model
            {
                float dist;
                float3 albedo;
                float glow;
            };

            Model hexModel(float3 p, float3 hexCenter, float3 edgeA, float3 edgeB, HexSpec spec)
            {
                float d;
                float edgeADist = dot(p, edgeA) + spec.gap;
                float edgeBDist = dot(p, edgeB) - spec.gap;
                float edgeDist = smax(edgeADist, -edgeBDist, spec.roundCorner);
                float outerDist = length(p) - spec.height;
                d = smax(edgeDist, outerDist, spec.roundTop);
                float innerDist = length(p) - spec.height + spec.thickness;
                d = smax(d, -innerDist, spec.roundTop);
                float3 color;
                float faceBlend = (spec.height - length(p)) / spec.thickness;
                faceBlend = clamp(faceBlend, 0., 1.);
                color = lerp(FACE_COLOR, BACK_COLOR, step(0.5, faceBlend));
                float3 edgeColor = spectrum(dot(hexCenter, pca) * 5. + length(p) + 0.8);
                float edgeBlend = smoothstep(-0.04, -0.005, edgeDist);
                color = lerp(color, edgeColor, edgeBlend);
                Model model;
                model.dist = d;
                model.albedo = color;
                model.glow = edgeBlend;
                return model;
            }

            Model opU(Model m1, Model m2)
            {
                if (m1.dist < m2.dist)
                {
                    return m1;
                }
                else
                {
                    return m2;
                }
            }

            Model geodesicModel(float3 p)
            {
                pModIcosahedron(p);
                float subdivisions = transitionValues(animSubdivisions1(), animSubdivisions2(), animSubdivisions3());
                TriPoints3D points = geodesicTriPoints(p, subdivisions);
                float3 edgeAB = normalize(cross(points.center, points.ab));
                float3 edgeBC = normalize(cross(points.center, points.bc));
                float3 edgeCA = normalize(cross(points.center, points.ca));
                Model model, part;
                HexSpec spec;
                spec = transitionHexSpecs(animHex1(points.b, subdivisions), animHex2(points.b, subdivisions),
                                          animHex3(points.b, subdivisions));
                part = hexModel(p, points.b, edgeAB, edgeBC, spec);
                model = part;
                spec = transitionHexSpecs(animHex1(points.c, subdivisions), animHex2(points.c, subdivisions),
                                          animHex3(points.c, subdivisions));
                part = hexModel(p, points.c, edgeBC, edgeCA, spec);
                model = opU(model, part);
                spec = transitionHexSpecs(animHex1(points.a, subdivisions), animHex2(points.a, subdivisions),
                                          animHex3(points.a, subdivisions));
                part = hexModel(p, points.a, edgeCA, edgeAB, spec);
                model = opU(model, part);
                return model;
            }

            Model map(float3 p)
            {
                float3x3 m = modelRotation();
                p = mul(p, m);
                #ifndef LOOP
                pR(p.xz, time * PI / 16.);
                #endif
                Model model = geodesicModel(p);
                return model;
            }

            float3 doLighting(Model model, float3 pos, float3 nor, float3 ref, float3 rd)
            {
                float3 lightPos = normalize(float3(0.5, 0.5, -1.));
                float3 backLightPos = normalize(float3(-0.5, -0.3, 1));
                float3 ambientPos = float3(0, 1, 0);
                float3 lig = lightPos;
                float amb = clamp((dot(nor, ambientPos) + 1.) / 2., 0., 1.);
                float dif = clamp(dot(nor, lig), 0., 1.);
                float bac = pow(clamp(dot(nor, backLightPos), 0., 1.), 1.5);
                float fre = pow(clamp(1. + dot(nor, rd), 0., 1.), 2.);
                float3 lin = ((float3)0.);
                lin += 1.2 * dif * ((float3)0.9);
                lin += 0.8 * amb * float3(0.5, 0.7, 0.8);
                lin += 0.3 * bac * ((float3)0.25);
                lin += 0.2 * fre * ((float3)1);
                float3 albedo = model.albedo;
                float3 col = lerp(albedo * lin, albedo, model.glow);
                return col;
            }

            static const float MAX_TRACE_DISTANCE = 8.;
            static const float INTERSECTION_PRECISION = 0.001;
            static const int NUM_OF_TRACE_STEPS = 100;
            static const float FUDGE_FACTOR = 0.9;

            struct CastRay
            {
                float3 origin;
                float3 direction;
            };

            struct Ray
            {
                float3 origin;
                float3 direction;
                float len;
            };

            struct Hit
            {
                Ray ray;
                Model model;
                float3 pos;
                bool isBackground;
                float3 normal;
                float3 color;
            };

            float3 calcNormal(in float3 pos)
            {
                float3 eps = float3(0.001, 0., 0.);
                float3 nor = float3(map(pos + eps.xyy).dist - map(pos - eps.xyy).dist,
                                    map(pos + eps.yxy).dist - map(pos - eps.yxy).dist,
                                    map(pos + eps.yyx).dist - map(pos - eps.yyx).dist);
                return normalize(nor);
            }

            Hit raymarch(CastRay castRay)
            {
                float currentDist = INTERSECTION_PRECISION * 2.;
                Model model;
                Ray ray;
                ray.origin = castRay.origin;
                ray.direction = castRay.direction;
                ray.len = 0;
                for (int i = 0; i < NUM_OF_TRACE_STEPS; i++)
                {
                    if (currentDist < INTERSECTION_PRECISION || ray.len > MAX_TRACE_DISTANCE)
                    {
                        break;
                    }

                    model = map(ray.origin + ray.direction * ray.len);
                    currentDist = model.dist;
                    ray.len += currentDist * FUDGE_FACTOR;
                }
                bool isBackground = false;
                float3 pos = ((float3)0);
                float3 normal = ((float3)0);
                float3 color = ((float3)0);
                if (ray.len > MAX_TRACE_DISTANCE)
                {
                    isBackground = true;
                }
                else
                {
                    pos = ray.origin + ray.direction * ray.len;
                    normal = calcNormal(pos);
                }
                Hit hit;
                hit.ray = ray;
                hit.model = model;
                hit.pos = pos;
                hit.isBackground = isBackground;
                hit.normal = normal;
                hit.color = color;
                return hit;
            }

            void shadeSurface(inout Hit hit)
            {
                float3 color = BACKGROUND_COLOR;
                if (hit.isBackground)
                {
                    hit.color = color;
                    return;
                }

                float3 ref = reflect(hit.ray.direction, hit.normal);
                #ifdef DEBUG
                color = hit.normal*0.5+0.5;
                #else
                color = doLighting(hit.model, hit.pos, hit.normal, ref, hit.ray.direction);
                #endif
                hit.color = color;
            }

            float3 render(Hit hit)
            {
                shadeSurface(hit);
                return hit.color;
            }

            float3x3 calcLookAtMatrix(in float3 ro, in float3 ta, in float roll)
            {
                float3 ww = normalize(ta - ro);
                float3 uu = normalize(cross(ww, float3(sin(roll), cos(roll), 0.)));
                float3 vv = normalize(cross(uu, ww));
                return transpose(float3x3(uu, vv, ww));
            }

            void doCamera(out float3 camPos, out float3 camTar, out float camRoll, in float time, in float2 mouse)
            {
                camRoll = 0;
                camTar = 0;
                camPos = 0;
                float dist = 5.5;
                camRoll = 0.;
                camTar = float3(0, 0, 0);
                camPos = float3(0, 0, -dist);
                camPos = mul(camPos, cameraRotation());
                camPos += camTar;
            }

            static const float GAMMA = 2.2;

            float3 gamma(float3 color, float g)
            {
                return pow(color, ((float3)g));
            }

            float3 linearToScreen(float3 linearRGB)
            {
                return gamma(linearRGB, 1. / GAMMA);
            }

            float4 frag(v2f __vertex_output) : SV_Target
            {
                vertex_output = __vertex_output;
                float4 fragColor = 0;
                float2 fragCoord = vertex_output.uv * _Resolution;
                time = _Time.y;
                #ifdef LOOP
                #if LOOP == 1
                time = glsl_mod(time, 2.);
                #endif
                #if LOOP == 2
                time = glsl_mod(time, 4.);
                #endif
                #if LOOP == 3
                time = glsl_mod(time, 2.);
                #endif
                #endif
                initIcosahedron();
                float2 p = (-iResolution.xy + 2. * fragCoord.xy) / iResolution.y;
                float2 m = _Mouse.xy / iResolution.xy;
                float3 camPos = float3(0., 0., 2.);
                float3 camTar = float3(0., 0., 0.);
                float camRoll = 0.;
                doCamera(camPos, camTar, camRoll, _Time.y, m);
                float3x3 camMat = calcLookAtMatrix(camPos, camTar, camRoll);
                float3 rd = normalize(mul(camMat, float3(p.xy, 2.)));
                CastRay castRay;
                castRay.origin = camPos;
                castRay.direction = rd;
                Hit hit = raymarch(castRay);
                float3 color = render(hit);
                #ifndef DEBUG
                color = linearToScreen(color);
                #endif
                fragColor = float4(color, 1.);
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}