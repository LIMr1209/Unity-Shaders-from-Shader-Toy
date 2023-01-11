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
  | vec3(1) | float3(1,1,1) |

- GLSL 中的 UV 坐标在顶部为 0 并向下增加，在 HLSL 中 0 在底部并向上增加，因此您可能需要在某些时候使用uv.y = 1 – uv.y。
- mainImage(out vec4 fragColor, in vec2 fragCoord)是片段着色器函数，相当于float4 mainImage(float2 fragCoord : SV_POSITION) : SV_Target
- 从 Texture2D 查找中删除第三个（偏差）参数
- 因为gl_FragCoord向量的z元素和特定的fragment的深度值相等。然而，我们也可以使用这个向量的x和y元素来实现一些有趣的效果。 gl_FragCoord的x和y元素是当前片段的窗口空间坐标（window-space coordinate）。它们的起始处是窗口的左下角。如果我们的窗口是800×600的，那么一个片段的窗口空间坐标x的范围就在0到800之间，y在0到600之间。
- 该iResolution变量是一个uniform vec3包含窗口尺寸的变量，并通过一些 openGL 代码发送到着色器。 该fragCoord变量是一个内置变量，其中包含应用着色器的像素的坐标。 更具体地说： fragCoord：是vec2在 X 轴上的 0 > 640 和 Y 轴上的 0 > 360 之间 iResolution：vec2X值为640，Y值为360
- Unity float2 fragCoord = float2(i.uv.x * _ScreenParams.x, i.uv.y * _ScreenParams.y);

