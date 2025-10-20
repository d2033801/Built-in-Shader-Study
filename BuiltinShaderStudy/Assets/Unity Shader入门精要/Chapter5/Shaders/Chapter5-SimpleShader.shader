// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 5/Simple Shader"
{
    Properties
    {
    	_Color("颜色", Color) = (1,1,1,1)
    }
	
    SubShader
    {

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            uniform fixed4 _Color;

            // 定义顶点着色器输入结构体, application to vertex 应用 to 顶点
            struct a2v
            {
	            // POSITION语义告诉Unity这个变量是顶点位置
                float4 vertex : POSITION;
                // NORMAL语义告诉Unity这个变量是顶点法线
                float3 normal : NORMAL;
	                // TEXCOORD0语义告诉Unity这个变量是第0组纹理坐标 (Texture Coordinate)
            	float4 texcoord : TEXCOORD0;
            };

            // vertex to fragment, 顶点 to 片元
            struct v2f
            {
                // pos包含了裁剪空间中的位置信息
	            float4 pos : SV_POSITION;
                // COLOR0语义可以存储颜色信息
                fixed3 color : COLOR0;
            };

            v2f vert(a2v v)
            {
                v2f o;
                 // mul(UNITY_MATRIX_MVP, v.vertex), 左乘MVP。被Unity自动优化成内部函数
                o.pos = UnityObjectToClipPos(v.vertex);

                // 将分量范围从 (-1, 1), 映射到 (0, 1)
                o.color = v.normal * 0.5 + fixed3(0.5, 0.5, 0.5);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 c = i.color;
                c *= _Color.rgb;
                return fixed4(c, 1);
                // return fixed4(1, 1, 1, 1);
            }
            ENDCG
        }
    }
}
