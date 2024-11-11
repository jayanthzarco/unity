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



Shader "Custom/ToonShadingOptimized"
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

        // Base pass for rendering the main texture and lighting
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

            // Texture samplers
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
                float3 normal : TEXCOORD2;
            };

            // Vertex shader
            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.viewDir = normalize(mul(UNITY_MATRIX_IT_MV, v.vertex).xyz); // View direction
                o.normal = normalize(mul((float3x3)UNITY_MATRIX_IT_MV, v.normal)); // Transform normal to view space
                return o;
            }

            // Fragment shader
            fixed4 frag(v2f i) : SV_Target
            {
                // Sample the base texture
                float4 mainTex = tex2D(_MainTex, i.uv);

                // Fixed light direction
                float3 lightDir = normalize(float3(0, 1, -1));
                // Reflective direction based on normal
                float3 reflectDir = reflect(-lightDir, i.normal);

                // Specular factor based on view direction
                float specularFactor = max(0, dot(i.viewDir, reflectDir));

                // Sample matcap textures for diffuse and specular lighting
                float4 diffuse = tex2D(_MatcapDiffuse, i.viewDir.xy * 0.5 + 0.5);
                float4 specular = tex2D(_MatcapSpecular, i.viewDir.xy * 0.5 + 0.5) *
                                  (pow(specularFactor, 16.0) * _ReflectionIntensity); // Adjust shininess

                // Combine diffuse and specular components
                return mainTex * diffuse + specular;
            }
            ENDCG
        }

        // Pass for rendering the outline
        Pass
        {
            Name "OUTLINE"
            Cull Front
            ZWrite On
            ColorMask RGBA

            Offset 1, 1
            CGPROGRAM
            #pragma vertex vertOutline
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

            // Vertex shader for outline
            v2f vertOutline(appdata v)
            {
                // Offset the vertex along the normal for the outline effect
                float3 outlineOffset = normalize(v.normal) * _OutlineWidth;
                v.vertex.xyz += outlineOffset;

                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                return o;
            }

            // Fragment shader for outline
            fixed4 fragOutline(v2f i) : SV_Target
            {
                return _OutlineColor; // Output the outline color
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
