Shader "Custom/PBRRim.shader"
{
Properties
    {
        /* ---- PBR BASE ---- */
        _Albedo ("Albedo (RGB)", 2D) = "white" {}
        _AlbedoTint ("Albedo Tint", Color) = (1,1,1,1)

        _NormalMap ("Normal Map", 2D) = "bump" {}
        _NormalIntensity ("Normal Intensity", Range(0,2)) = 1.0

        _ARM ("ARM (AO-Rough-Metal)", 2D) = "white" {}
        _AOIntensity ("AO Intensity", Range(0,2)) = 1.0
        _RoughnessIntensity ("Roughness Intensity", Range(0,2)) = 1.0
        _MetallicIntensity ("Metallic Intensity", Range(0,2)) = 1.0

        /* ---- RIM LIGHT ---- */
        _RimColor ("Rim Color", Color) = (1,1,1,1)
        _RimIntensity ("Rim Intensity", Range(0,5)) = 1.0
        _RimPower ("Rim Power / Curva", Range(0.1,8)) = 3.0
        _RimBias ("Rim Bias", Range(-1,1)) = 0.0

        // Esto permite dirigir el rim light opcionalmente
        _RimDirection ("Rim Direction (World)", Vector) = (0,1,0,0)
        _UseDirectionalRim ("Directional Rim?", Float) = 0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 300

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows
        #pragma target 3.0

        /* ---- PROPERTIES ---- */
        sampler2D _Albedo;
        float4 _AlbedoTint;

        sampler2D _NormalMap;
        float _NormalIntensity;

        sampler2D _ARM;
        float _AOIntensity;
        float _RoughnessIntensity;
        float _MetallicIntensity;

        float4 _RimColor;
        float _RimIntensity;
        float _RimPower;
        float _RimBias;

        float4 _RimDirection;
        float _UseDirectionalRim;

        struct Input
        {
            float2 uv_Albedo;
            float2 uv_NormalMap;
            float2 uv_ARM;

            float3 viewDir;    
            float3 worldNormalVector;
            float3 worldPos;
        };

        inline float3 ApplyNormalIntensity(float3 n, float intensity)
        {
            return normalize(lerp(float3(0,0,1), n, intensity));
        }

        /* ---- SURFACE FUNCTION ---- */
        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            /* --- ALBEDO + TINT --- */
            float4 albedoTex = tex2D(_Albedo, IN.uv_Albedo);
            o.Albedo = albedoTex.rgb * _AlbedoTint.rgb;

            /* --- NORMAL MAP --- */
            float4 normalSample = tex2D(_NormalMap, IN.uv_NormalMap);
            float3 n = UnpackNormal(normalSample);
            n = ApplyNormalIntensity(n, _NormalIntensity);
            o.Normal = n;

            /* --- ARM MAP --- */
            float3 arm = tex2D(_ARM, IN.uv_ARM).rgb;

            float AO       = arm.r * _AOIntensity;
            float Rough    = arm.g * _RoughnessIntensity;
            float Metallic = arm.b * _MetallicIntensity;

            o.Occlusion  = saturate(AO);
            o.Smoothness = 1 - saturate(Rough);
            o.Metallic   = saturate(Metallic);

            /* --- RIM LIGHT CALC --- */

            // Normal (world space)
            float3 N = normalize(IN.worldNormalVector);

            // View direction (world space)
            float3 V = normalize(IN.viewDir);

            // Rim básico: 1 - dot(N, V)
            float rimBase = 1.0 - saturate(dot(N, V));

            // Direccional opcional
            if (_UseDirectionalRim > 0.5)
            {
                float3 rimDir = normalize(_RimDirection.xyz);
                float d = saturate(dot(N, rimDir));
                rimBase *= (1.0 - d);
            }

            // Aplicar curva (exponente)
            float rim = pow(saturate(rimBase + _RimBias), _RimPower);

            // Intensidad y color
            float3 rimFinal = rim * _RimIntensity * _RimColor.rgb;

            // Mezclar rim light con emisión del material (PBR-friendly)
            o.Emission = rimFinal;
        }

        ENDCG
    }

    FallBack "Standard"
}
