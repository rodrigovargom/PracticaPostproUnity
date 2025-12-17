Shader "Custom/PBRRimHologram"
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
        _RimColor ("Rim Color", Color) = (0,1,1,1)
        _RimIntensity ("Rim Intensity", Range(0,5)) = 1.5
        _RimPower ("Rim Power", Range(0.1,8)) = 3.0
        _RimBias ("Rim Bias", Range(-1,1)) = 0.0

        _RimDirection ("Rim Direction (World)", Vector) = (0,1,0,0)
        _UseDirectionalRim ("Directional Rim?", Float) = 0

        /* ---- HOLOGRAM ---- */
        _FlickerSpeed ("Flicker Speed", Range(0,10)) = 3.0
        _FlickerAmount ("Flicker Amount", Range(0,1)) = 0.4
        _MinAlpha ("Minimum Alpha", Range(0,1)) = 0.0
    }

    SubShader
    {
        Tags { 
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }

        LOD 300
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off

        CGPROGRAM
        #pragma surface surf Standard alpha:fade fullforwardshadows
        #pragma target 3.0

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

        float _FlickerSpeed;
        float _FlickerAmount;
        float _MinAlpha;

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

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            /* --- ALBEDO --- */
            float4 albedoTex = tex2D(_Albedo, IN.uv_Albedo);
            o.Albedo = albedoTex.rgb * _AlbedoTint.rgb;

            /* --- NORMAL --- */
            float3 n = UnpackNormal(tex2D(_NormalMap, IN.uv_NormalMap));
            o.Normal = ApplyNormalIntensity(n, _NormalIntensity);

            /* --- ARM --- */
            float3 arm = tex2D(_ARM, IN.uv_ARM).rgb;
            o.Occlusion  = saturate(arm.r * _AOIntensity);
            o.Smoothness = 1 - saturate(arm.g * _RoughnessIntensity);
            o.Metallic   = saturate(arm.b * _MetallicIntensity);

            /* --- RIM --- */
            float3 N = normalize(IN.worldNormalVector);
            float3 V = normalize(IN.viewDir);

            float rimBase = 1.0 - saturate(dot(N, V));

            if (_UseDirectionalRim > 0.5)
            {
                float3 rimDir = normalize(_RimDirection.xyz);
                rimBase *= (1.0 - saturate(dot(N, rimDir)));
            }

            float rim = pow(saturate(rimBase + _RimBias), _RimPower);

            /* --- FLICKER HOLOGRAMA --- */
            float flicker = sin(_Time.y * _FlickerSpeed) * 0.5 + 0.5;
            flicker = lerp(1.0, flicker, _FlickerAmount);

            float rimAnimated = rim * _RimIntensity * flicker;

            /* --- EMISSION --- */
            o.Emission = rimAnimated * _RimColor.rgb;

            /* --- TRANSPARENCIA POR RIM --- */
            // Menos rim = más transparente
            float alpha = saturate(rimAnimated);
            o.Alpha = max(alpha, _MinAlpha);
        }

        ENDCG
    }

    FallBack "Standard"
}
