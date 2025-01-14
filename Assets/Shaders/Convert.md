# ShaderToy To Unity

- 转换备忘单

  |  标题   | 预制体文件 |
    |  ----  | ----  |
  | vec<"n">  | float<"n"> |
  | mat<"n">  | float<"n">x<"n"> |
  | fract  | frac |
  | mix  | lerp |
  | Texture2D   | Tex2D |
  | use *=  | use mul() |
  | mainImage  | frag or surf |
  | iTime  | _Time.y |
  | fragColor = color  | return color |
  | mod(x,y)  |  x-y*floor(x/y)  or fmod(x,y) |
  | atan(x,y)  | atan2(y,x) |
  | fragCoord/iResolution   | i.uv or IN.uv_MainTex |
  | iResolution.xy | _ScreenParams.xy | 
  | inversesqrt(x) | _rsqrt(x) | 
  | vec3(1) | float3(1,1,1)  or (float3)1|

- GLSL 中的 UV 坐标在顶部为 0 并向下增加，在 HLSL 中 0 在底部并向上增加，因此您可能需要在某些时候使用uv.y = 1 - uv.y。
- mainImage(out vec4 fragColor, in vec2 fragCoord)是片段着色器函数，相当于float4 mainImage(float2 fragCoord : SV_POSITION) :
  SV_Target
- 从 Texture2D 查找中删除第三个（偏差）参数
- 因为gl_FragCoord向量的z元素和特定的fragment的深度值相等。然而，我们也可以使用这个向量的x和y元素来实现一些有趣的效果。 gl_FragCoord的x和y元素是当前片段的窗口空间坐标（window-space
  coordinate）。它们的起始处是窗口的左下角。如果我们的窗口是800×600的，那么一个片段的窗口空间坐标x的范围就在0到800之间，y在0到600之间。
- 该iResolution变量是一个uniform vec3包含窗口尺寸的变量，并通过一些 openGL 代码发送到着色器。 该fragCoord变量是一个内置变量，其中包含应用着色器的像素的坐标。 更具体地说：
  fragCoord：是vec2在 X 轴上的 0 > 640 和 Y 轴上的 0 > 360 之间 iResolution：vec2X值为640，Y值为360
- Unity float2 fragCoord = float2(i.uv.x * _ScreenParams.x, i.uv.y * _ScreenParams.y); -fmod (HLSL) 将输出一个正数 mod (GLSL)
  将输出一个负数 你可以定义一个宏 define ModFix(x, y) (x - y * floor(x / y))
- mul(M, N)       M*N 矩阵M和矩阵N的积
- mul(M, v)    M*v 矩阵M和列向量v的积
- mul(v, M)    v* M 行向量v和矩阵M的积
- const 变量被定义成常量的话，在程序中，就不能再对该变量赋值，除非const和uniform，varying一起使用。const修饰的变量，需要在声明时给予一个初始值
- static 只在声明全局变量时使用，static将使变量对程序而言成为私有的，外部不可见，不能和uniform，varying一起使用
- uniform 用于全局变量和程序的入口函数的参数，用来定义constant buffers(常量缓存)
  。如果用于一个非入口函数的参数，它将被忽略。这样做的目的是为了使一个函数既能作为入口函数，又能作为非入口函数。uniform的变量可以像非uniform的变量那样读写。uniform修饰符通过向外部语言提供一个机制，来提供变量的初始值是如何指定和保存的信息。

```

// https://pema.dev/glsl2hlsl/
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
```


```
// 数组
float4 _ColorSet01[6] = {
float4(1,0,0,1),
float4(1,1,0,1),
float4(1,0,0,1),
float4(1,0,1,1),
float4(1,1,0,1),
float4(1,0,0,1)
};
```

```
-1. + 2. * uv   uv 范围 0-1 映射到 -1-1
```

