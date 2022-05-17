Shader "Unlit/FinalClips"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }
        LOD 100

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

            UNITY_DECLARE_TEX2DARRAY(FinalClips);

            sampler2D _MainTex;
            float4 _MainTex_ST;
            uniform int DepthRenderedIndex;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 col = 0;
                // col.a = 1.0; // for nvidia method uncomment this line
                fixed4 top = 0;
                for (int k = 0; k < DepthRenderedIndex + 1; k++)
                {
                    /*
                    // 原来的实现：说实话我觉得col的alpha通道算的不是很对
                    // 从前往后混的备用算法
                    //fixed4 back=	UNITY_SAMPLE_TEX2DARRAY(FinalClips, float3(i.uv, k));
                    //col.rgb=col.rgb*(col.a)+back.rgb*(1-col.a);
                    //col.a=1-(1-col.a)*(1-back.a);
                    // fixed4 front = UNITY_SAMPLE_TEX2DARRAY(FinalClips, float3(i.uv, DepthRenderedIndex-k));

                    // glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA,GL_ONE,GL_ZERO);
                    // 在半透明物体之前绘制的是SRC，绘制的背景是DST，因为是从后到前绘制
                    // col.rgb = col.rgb * (1 - front.a) + front.rgb * front.a;
                    // col.a = 1 - (1 - col.a) * (1 - front.a);
                    // col.a = front.a;
                    */

                    //My implementation
                    // from back to front
                    fixed4 front = UNITY_SAMPLE_TEX2DARRAY(FinalClips, float3(i.uv, DepthRenderedIndex-k));
                    col = col * (1 - front.a) + front * front.a;
                    top = col;

                    //from front to back
                    //this is from Nvidia: https://my.eng.utah.edu/~cs5610/handouts/DualDepthPeeling.pdf page 6
                    // fixed4 src = UNITY_SAMPLE_TEX2DARRAY(FinalClips, float3(i.uv, k));
                    // col.rgb = col.a * src.rgb * src.a + col.rgb;
                    // col.a = (1 - src.a) * col.a;
                    // top = col;
                }
                col.a = saturate(col.a);
                //被最后丢弃的图层 用最外层补上避免黑斑  可以不需要
                //没看懂这行的含义
                col.rgb = col.rgb + top.rgb * (1 - col.a);
                col.a = 1.0;
                return col;
            }
            ENDCG
        }
    }
}