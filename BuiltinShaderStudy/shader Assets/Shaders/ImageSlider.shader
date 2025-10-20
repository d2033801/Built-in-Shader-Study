// 该Shader用于显示一张包含多帧的序列帧图片，并根据时间自动切换显示不同的帧，实现动画效果
Shader "MyShader/ImageSlider"
{
    Properties
    {
        // 需要显示的序列帧图片
        _MainTex ("Frame Image", 2D) = "white" {}
        // 整体颜色调节，可用于改变图片色调或透明度
        _Color("Color", COLOR) = (1,1,1,1)
        // 动画播放速度，数值越大切换越快
        _Speed("Speed", FLOAT) = 10
        // 图片横向有多少帧（列数）
        _Horizontal("Horizontal count", INT) = 4
        // 图片纵向有多少帧（行数）
        _Vertical("Vertical count", INT) = 3
    }
    SubShader
    {
        // 设置渲染类型为透明，并忽略Projector组件的影响
        Tags { "RenderType"="Transparent" "IgnoreProjector"="True" "Queue" = "Transparent"} 

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            // 纹理采样器，用于获取图片像素颜色
            sampler2D _MainTex;
            // 纹理的Tiling和Offset参数
            float4 _MainTex_ST;
            // 颜色调节参数
            float4 _Color;
            // 动画速度
            float _Speed;
            // 横向帧数
            float _Horizontal;
            // 纵向帧数
            float _Vertical;

            // 顶点着色器输入结构体
            struct appdata
            {
                float4 vertex : POSITION; // 顶点位置
                float2 uv : TEXCOORD0;    // 顶点UV坐标
            };

            // 顶点着色器输出结构体，传递到片元着色器
            struct v2f
            {
                float2 uv : TEXCOORD0;        // 传递UV坐标
                float4 vertex : SV_POSITION;  // 裁剪空间下的顶点位置
            };

            // 顶点着色器：将模型空间的顶点转换到裁剪空间，并处理UV
            v2f vert (appdata v)
            {
                v2f o;
                // 将顶点位置从模型空间转换到裁剪空间
                o.vertex = UnityObjectToClipPos(v.vertex);
                // 对UV坐标应用Tiling和Offset变换
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            // 片元着色器：根据时间计算当前帧，并采样对应的图片区域
            fixed4 frag (v2f i) : SV_Target
            {
                // 计算从开始到现在应该切换了多少帧
                float deltaCount = floor(_Time.y * _Speed);
                // 当前应该显示第几帧（总帧数取模，循环播放）
                float posCount = deltaCount % (_Horizontal * _Vertical);

                // 计算当前帧在图片中的行号（从上到下）, 从0开始
                float row = floor(posCount / _Horizontal);
                // 计算当前帧在图片中的列号（从左到右）, 从0开始
                float column = posCount - row * _Horizontal;

                // 计算当前像素在当前帧格子中的UV坐标
                // 横向：先缩小到单帧宽度，再加上当前帧的起始横坐标
                // 纵向：同理，注意Unity的UV原点在左下角，所以要用(_Vertical - 1 - row)
                float2 uv = half2(
                    i.uv.x / _Horizontal + column / _Horizontal,
                    i.uv.y / _Vertical + (_Vertical - 1 - row) / _Vertical
                );

                // 从纹理中采样当前帧的颜色
                fixed4 col = tex2D(_MainTex, uv);
                // 乘以整体颜色，实现色调或透明度调整
                col.rgb *= _Color;
                // 返回最终颜色
                return col;
            }
            ENDCG
        }
    }
}