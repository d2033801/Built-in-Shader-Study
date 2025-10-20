//装入一张序列帧图片并按时间切换
Shader "MyShader/ImageSlider"
{
    Properties
    {
        _MainTex ("Frame Image", 2D) = "white" {}
        _Color("Color", COLOR) = (1,1,1,1)
        _Speed("Speed", FLOAT) = 10
        _Horizontal("Horizontal count", INT) = 4
        _Vertical("Vertical count", INT) = 3
    }
    SubShader
    {
        //IgnoreProjector是忽视"Projector(投影仪)"组件对物体的影响
        Tags { "RenderType"="Transparent" "IgnoreProjector"="True" "Queue" = "Transparent"} 

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;         //是Texture中的Tilling和Offset字段的值, 在顶点shader中的TRANSFORM_TEX()中被用到
            float4 _Color;
            float _Speed;
            float _Horizontal;
            float _Vertical;

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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);   //TRANSFORM_TEX对UV进行对UV进行Tiling与Offset变换

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float deltaCount = floor(_Time.y*_Speed);
                float posCount = deltaCount % (_Horizontal * _Vertical);        //此时该播放第几张图片

                float row = floor(posCount / _Horizontal);                      //行
                float column = posCount - row * _Horizontal;                    //列
                float2 uv = half2(i.uv.x / _Horizontal + column / _Horizontal, (i.uv.y / _Vertical + (_Vertical - 1 - row) / _Vertical));          //注意uv范围是0~1, 列数除以水平长度得出的即为该列图片的开始位置
                
                // sample the texture
                fixed4 col = tex2D(_MainTex, uv);
                col.rgb *= _Color;
                return col;
            }
            ENDCG
        }
    }
}
