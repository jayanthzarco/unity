Shader "Custom/ToonShading"
{
    Properties
    {
        _MainTex ("Base Texture", 2D) = "white" {}
        _OutlineColor ("Outline Color", Color) = (0,0,0,1)
        _OutlineWidth ("Outline Width", Float) = 0.02
        _MatcapDiffuse ("MatCap Diffuse", 2D) = "white" {}
        _MatcapSpecular ("MatCap Specular", 2D) = "white" {}
        _ReflectionColor ("Reflection Color", Color) = (1,1,1,1)
        _ReflectionIntensity ("Reflection Intensity", Range(0, 1)) = 0.2
        _SpecularIntensity ("Specular Intensity", Range(0, 1)) = 0.5
        _SpecularThreshold ("Specular Threshold", Range(0, 1)) = 0.1
        _ReflectionSteps ("Reflection Steps", Range(1, 5)) = 3
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
            float4 _ReflectionColor;
            float _ReflectionIntensity;
            float _SpecularIntensity;
            float _SpecularThreshold;
            float _ReflectionSteps;

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
                float3 worldNormal : TEXCOORD2;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.viewDir = normalize(WorldSpaceViewDir(v.vertex).xyz);
                o.worldNormal = normalize(mul((float3x3)unity_WorldToObject, v.normal)); // Optimize normal transformation to world space
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                half4 mainTex = tex2D(_MainTex, i.uv);

                // Light and reflection calculations
                half3 lightDir = normalize(float3(0, 1, -1));
                half3 reflectDir = reflect(-lightDir, i.worldNormal);

                // Specular component, only computed if threshold is passed
                half specularFactor = max(0, dot(i.viewDir, reflectDir) - _SpecularThreshold);
                specularFactor = pow(saturate(specularFactor / (1.0 - _SpecularThreshold)), 16.0) * _SpecularIntensity;
                half4 specular = tex2D(_MatcapSpecular, i.viewDir.xy * 0.5 + 0.5) * specularFactor;

                // Diffuse and reflection calculations
                half4 diffuse = tex2D(_MatcapDiffuse, i.viewDir.xy * 0.5 + 0.5);
                half reflectionFactor = dot(i.viewDir, i.worldNormal) * _ReflectionSteps;
                reflectionFactor = floor(reflectionFactor) / _ReflectionSteps;
                half4 reflection = _ReflectionColor * reflectionFactor * _ReflectionIntensity;

                return mainTex * diffuse + specular + reflection;
            }
            ENDCG
        }

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

            v2f vertOutline(appdata v)
            {
                float3 outlineOffset = normalize(v.normal) * _OutlineWidth;
                v.vertex.xyz += outlineOffset;

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
