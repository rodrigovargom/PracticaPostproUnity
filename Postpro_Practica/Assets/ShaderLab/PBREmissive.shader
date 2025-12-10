Shader "Custom/PBREmissive"
{
   Properties
    {
        _Albedo ("Albedo (RGB)", 2D) = "white" {}
        _AlbedoTint ("Albedo Tint", Color) = (1,1,1,1)

        _NormalMap ("Normal Map", 2D) = "bump" {}
        _NormalIntensity ("Normal Intensity", Range(0,2)) = 1.0

        _EmissionMap ("Emission Map", 2D) = "black" {}
        _EmissionTint ("Emission Tint", Color) = (1,1,1,1)
        _EmissionIntensity ("Emission Intensity", Range(0,5)) = 1.0

        _ARM ("ARM (AO-Rough-Metallic)", 2D) = "white" {}
        _AOIntensity ("AO Intensity", Range(0,2)) = 1.0
        _RoughnessIntensity ("Roughness Intensity", Range(0,2)) = 1.0
        _MetallicIntensity ("Metallic Intensity", Range(0,2)) = 1.0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }

        LOD 300

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows
        #pragma target 3.0

        sampler2D _Albedo;
        float4 _AlbedoTint;

        sampler2D _NormalMap;
        float _NormalIntensity;

        sampler2D _EmissionMap;
        float4 _EmissionTint;
        float _EmissionIntensity;

        sampler2D _ARM;
        float _AOIntensity;
        float _RoughnessIntensity;
        float _MetallicIntensity;

        struct Input
        {
            float2 uv_Albedo;
            float2 uv_NormalMap;
            float2 uv_EmissionMap;
            float2 uv_ARM;
        };

        // Convertidor de normal map con intensidad
        inline float3 ApplyNormalIntensity(float3 n, float intensity)
        {
            return normalize(lerp(float3(0,0,1), n, intensity));
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // ---- Albedo ----
            float4 albedoTex = tex2D(_Albedo, IN.uv_Albedo);
            o.Albedo = albedoTex.rgb * _AlbedoTint.rgb;

            // ---- Normal Map ----
            float4 normalSample = tex2D(_NormalMap, IN.uv_NormalMap);
            float3 normal = UnpackNormal(normalSample);
            normal = ApplyNormalIntensity(normal, _NormalIntensity);
            o.Normal = normal;

            // ---- ARM Map (AO-Rough-Metallic) ----
            float3 arm = tex2D(_ARM, IN.uv_ARM).rgb;

            float AO       = arm.r * _AOIntensity;
            float Rough    = arm.g * _RoughnessIntensity;
            float Metallic = arm.b * _MetallicIntensity;

            // Unity usa Smoothness, no Roughness
            float Smoothness = 1 - saturate(Rough);
            o.Smoothness = Smoothness;
            o.Metallic   = saturate(Metallic);
            o.Occlusion  = saturate(AO);

            // ---- Emission ----
            float3 emissiveTex = tex2D(_EmissionMap, IN.uv_EmissionMap).rgb;
            float3 emissive = emissiveTex * _EmissionTint.rgb * _EmissionIntensity;
            o.Emission = emissive;
        }

        ENDCG
    }

    FallBack "Standard"
}
