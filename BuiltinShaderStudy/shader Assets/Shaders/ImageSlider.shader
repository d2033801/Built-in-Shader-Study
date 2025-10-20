// ��Shader������ʾһ�Ű�����֡������֡ͼƬ��������ʱ���Զ��л���ʾ��ͬ��֡��ʵ�ֶ���Ч��
Shader "MyShader/ImageSlider"
{
    Properties
    {
        // ��Ҫ��ʾ������֡ͼƬ
        _MainTex ("Frame Image", 2D) = "white" {}
        // ������ɫ���ڣ������ڸı�ͼƬɫ����͸����
        _Color("Color", COLOR) = (1,1,1,1)
        // ���������ٶȣ���ֵԽ���л�Խ��
        _Speed("Speed", FLOAT) = 10
        // ͼƬ�����ж���֡��������
        _Horizontal("Horizontal count", INT) = 4
        // ͼƬ�����ж���֡��������
        _Vertical("Vertical count", INT) = 3
    }
    SubShader
    {
        // ������Ⱦ����Ϊ͸����������Projector�����Ӱ��
        Tags { "RenderType"="Transparent" "IgnoreProjector"="True" "Queue" = "Transparent"} 

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            // ��������������ڻ�ȡͼƬ������ɫ
            sampler2D _MainTex;
            // �����Tiling��Offset����
            float4 _MainTex_ST;
            // ��ɫ���ڲ���
            float4 _Color;
            // �����ٶ�
            float _Speed;
            // ����֡��
            float _Horizontal;
            // ����֡��
            float _Vertical;

            // ������ɫ������ṹ��
            struct appdata
            {
                float4 vertex : POSITION; // ����λ��
                float2 uv : TEXCOORD0;    // ����UV����
            };

            // ������ɫ������ṹ�壬���ݵ�ƬԪ��ɫ��
            struct v2f
            {
                float2 uv : TEXCOORD0;        // ����UV����
                float4 vertex : SV_POSITION;  // �ü��ռ��µĶ���λ��
            };

            // ������ɫ������ģ�Ϳռ�Ķ���ת�����ü��ռ䣬������UV
            v2f vert (appdata v)
            {
                v2f o;
                // ������λ�ô�ģ�Ϳռ�ת�����ü��ռ�
                o.vertex = UnityObjectToClipPos(v.vertex);
                // ��UV����Ӧ��Tiling��Offset�任
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            // ƬԪ��ɫ��������ʱ����㵱ǰ֡����������Ӧ��ͼƬ����
            fixed4 frag (v2f i) : SV_Target
            {
                // ����ӿ�ʼ������Ӧ���л��˶���֡
                float deltaCount = floor(_Time.y * _Speed);
                // ��ǰӦ����ʾ�ڼ�֡����֡��ȡģ��ѭ�����ţ�
                float posCount = deltaCount % (_Horizontal * _Vertical);

                // ���㵱ǰ֡��ͼƬ�е��кţ����ϵ��£�, ��0��ʼ
                float row = floor(posCount / _Horizontal);
                // ���㵱ǰ֡��ͼƬ�е��кţ������ң�, ��0��ʼ
                float column = posCount - row * _Horizontal;

                // ���㵱ǰ�����ڵ�ǰ֡�����е�UV����
                // ��������С����֡��ȣ��ټ��ϵ�ǰ֡����ʼ������
                // ����ͬ��ע��Unity��UVԭ�������½ǣ�����Ҫ��(_Vertical - 1 - row)
                float2 uv = half2(
                    i.uv.x / _Horizontal + column / _Horizontal,
                    i.uv.y / _Vertical + (_Vertical - 1 - row) / _Vertical
                );

                // �������в�����ǰ֡����ɫ
                fixed4 col = tex2D(_MainTex, uv);
                // ����������ɫ��ʵ��ɫ����͸���ȵ���
                col.rgb *= _Color;
                // ����������ɫ
                return col;
            }
            ENDCG
        }
    }
}