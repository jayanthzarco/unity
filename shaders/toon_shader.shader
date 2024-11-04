Shader "Custom/ToonShading"
{
    Properties
    {
        _MainTex ("Base Texture", 2D) = "white" {}
        _OutlineColor ("Outline Color", Color) = (0,0,0,1)
        _OutlineWidth ("Outline Width", Float) = 0.02
        _MatcapDiffuse ("MatCap Diffuse", 2D) = "white" {}
        _MatcapSpecular ("MatCap Specular", 2D) = "white" {}
        _ReflectionIntensity ("Reflection Intensity", Range(0, 1)) = 0.5
    }
    
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        
        Pass
        {
            Name "BASE"
            Cull Off
            ZWrite On
            ColorMask RGBA
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            
            sampler2D _MainTex;
            sampler2D _MatcapDiffuse;
            sampler2D _MatcapSpecular;
            float4 _OutlineColor;
            float _OutlineWidth;
            float _ReflectionIntensity;
            
            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 viewDir : TEXCOORD1;
            };
            
            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.viewDir = normalize(mul(UNITY_MATRIX_IT_MV, v.vertex).xyz);
                return o;
            }
            
            fixed4 frag(v2f i) : SV_Target
            {
                float4 mainTex = tex2D(_MainTex, i.uv);
                float4 diffuse = tex2D(_MatcapDiffuse, i.viewDir.xy * 0.5 + 0.5);
                float4 specular = tex2D(_MatcapSpecular, i.viewDir.xy * 0.5 + 0.5) * _ReflectionIntensity;
                
                return mainTex * diffuse + specular;
            }
            ENDCG
        }
        
        Pass
        {
            Name "OUTLINE"
            Cull Front
            ZWrite On
            ColorMask RGBA
            
            Offset 1,1
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment fragOutline
            #include "UnityCG.cginc"
            
            float _OutlineWidth;
            float4 _OutlineColor;
            
            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {   
                float4 pos : SV_POSITION;
            };
            
            v2f vert(appdata v)
            {
                v.vertex.xyz += v.normal * _OutlineWidth;
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                return o;
            }
            
            fixed4 fragOutline(v2f i) : SV_Target
            {
                return _OutlineColor;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
