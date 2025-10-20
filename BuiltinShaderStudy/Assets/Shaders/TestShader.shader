//教程链接: https://learn.u3d.cn/tutorial/unity-shader-beginner?chapterId=65b99eb1017bde00225663a3#65bb3c3d132bc200227547ae
Shader "MyShader/TestShader"
{
    Properties                                                      //属性
    {
        [Header(Colors)]                                            //在Inspector面板中进行标注, 分类用
        _Color("Color", COLOR) = (1,1,1,1)
        [hdr]_HDRColor("HDRColor", COLOR) = (1,1,1,1)               //色彩取样时标记为HDR, 可以让RGBA值大于1

        [Header(Number)]
        _Float("Float", float) = 0.5
        [Toggle]_FloatToggle("Toggle", float) = 0.5                 //选择框, 未选择为0, 选择为1
        _FloatSlider("FloatSlider", Range(0,1)) = 0.5               //滑动条, 限制范围为0到1
        [IntRange]_IntSlider("IntSlider", Range(0, 4)) = 0.5        //滑动条, 限制只能取整型
        [PowerSlider(2)]_FloatPowerSlider("FloatPowerSlider", Range(0, 1)) = 0.5    //power滑动条, 使滑动条取值为非线性, 括号内的值大概是幂函数的上标
        [Enum(UnityEngine.Rendering.CullMode)]_FloatEnum("Lists", float) = 0.5      //枚举类型, 下拉选项框
        _Vector("Vector", vector) = (0,0,0,0)

        [Header(Textures)]
        _MainTex ("Texture", 2D) = "white" {}
        [NoScaleOffset]_MainTexNoScale("我是2D纹理", 2D) = "white" {}               //使得纹理设置列表中不包含Tiling和Offset\
        [NORMAL]_NormalTex("NormalTexture", 2D) = "bump"{}                          //指定纹理为法线贴图
        _Main3DTex("我是3D纹理", 3d) = "" {}                                        //3D纹理主要用在查找表或者体积数据上，默认值与2D的不同，不管如何设置都只会显示为灰色图。
        _CubeTex("我是Cube纹理", CUBE) = "" {}                       //立方体纹理
    }   

    SubShader                               //子着色器
    {   
        cull off                            //不进行遮挡剔除
        Pass                                //一次pass代表"渲染一次模型"
        {
            CGPROGRAM                       //C for Graphics语言

            //定义顶点着色器, 命名为vert
            #pragma vertex vert
            //定义片元着色器, 命名为frag
            #pragma fragment frag

            //结构体appdata, 保存多个顶点着色器输入信息
            struct appdata
            {
                float4 vertex : POSITION;                       //POSITION代表顶点的本地坐标
                float2 uv : TEXCOORD;                           //TEXCOORD代表顶点的uv信息
            };

            //结构体vertex to fragment, 保存多个顶点着色器输出信息
            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD;
            };

            //顶点着色器, POSITION代表模型本地顶点坐标, SV_POSITION代表模型经过顶点着色器变换后的顶点坐标
            //顶点着色器输入原始顶点信息, 输出变换后的顶点信息
            v2f vert(appdata v)
            {
                v2f o;
                /*if(v.vertex.x > 0 && v.vertex.y > 0 && v.vertex.z > 0)    //使某部分顶点整体偏移长度1
                {
                    v.vertex += 1;
                }*/
                
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;        //Unity自带函数, 将本地坐标转换为裁剪坐标
            }

            float4 _Color;              //在Cg/HLSL中使用Properties中的变量前还需要在Cg/HLSL中再重新声明一次，名称要求一致。
            //float changeColor = 0.1;
            float4 _White = (1,1,1,1);

            float checker(float2 uv)                //生成棋盘式材质
            {
                float2 repeatUV = uv*10;            //每行棋盘格子数量。这一步实际上放缩了棋盘, 从0~1变为了0~1, 1~2, ..., 9~10十个区间
                float2 c = floor(repeatUV) / 2;     //floor()为向下取整。若repeatUV的整数部分可以被2整除则c的小数部分为0, 若不可被整除则小数部分为0.5
                /*
                 * frac()取小数部分。若repeatUV的整数部分均可以被整除或均不可以被整除, 则c.x+c.y的小数部分为0
                 * 若repeatUV的两个分量分别可被2整除和不可被2整除, 则c.x+c.y的小数部分为0.5
                 * 当小数部分为0.5时乘以2则返回值为1, 此时颜色为白色; 小数部分为0时返回值为0, 此时颜色为白色
                 */
                float checker = frac(c.x + c.y) * 2;    
                return checker;
            }

            float gradientBW(float2 uv)                //生成u方向的白到黑渐变
            {
                return 1 - uv.x;
            }

            float4 gradientRGBA(float2 uv)             //生成彩虹色
            {
                float4 RGBA = {0,0,0,1};
                //float x = uv.x * 6;
                //float x = _SinTime.z + 0.5f;
                //x *= 6;

                /*
                 * shaderlab中通过_Time可以获取时间变量，然后可以让图像跟随时间动起来。
                 * _Time含有x/y/z/w四个值，分别对应时间t/20、t、2t和3t。
                 * 当然也可以通过 _SinTime和_CosTime来获取时间的正弦或者余弦值，只不过他们的w分量才是准确值，而xyz值则为w值的八分之一、四分之一和二分之一。
                 */

                float x = frac(uv.x + _SinTime.z + 0.5f);               //使彩虹色随时间移动
                x *= 6;
                if(x < 1)
                {
                    RGBA.r = 1;
                    RGBA.g = x;
                }
                else if(x < 2)
                {
                    RGBA.r = 1 - frac(x);
                    RGBA.g = 1;
                }
                else if(x < 3)
                {
                    RGBA.g = 1;
                    RGBA.b = frac(x);
                }
                else if(x < 4)
                {
                    RGBA.g = 1 - frac(x);
                    RGBA.b = 1;
                }
                else if (x < 5)
                {
                    RGBA.r = frac(x);
                    RGBA.b = 1;
                }
                else if(x <= 6)
                {
                    RGBA.r = 1;
                    RGBA.b = 1 - frac(x);
                }
                return RGBA;
            }

            //片元着色器对模型每个片元像素进行处理
            //SV_TARGET是系统值，表示该函数返回的是用于下一个阶段输出的颜色值，也就是我们最终输出到显示器上的值。
            float4 frag(v2f i) : SV_TARGET
            {
                
                /*
                 _Color.x = _Color.x - changeColor;
                changeColor += 0.1;
                if(changeColor >= 1)
                {
                    changeColor = 0;
                }
                */
                //float col = checker(i.uv);
                //float col = gradientBW(i.uv);
                float4 col = gradientRGBA(i.uv);
                //float4 col = _Color;
                return col;
            }
            ENDCG
            
        }
    }
    //CustomEditor "EditerName"
}
