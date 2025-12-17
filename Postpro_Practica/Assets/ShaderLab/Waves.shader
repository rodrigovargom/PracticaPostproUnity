Shader "Custom/WavesDualAlbedoVF"
{
    Properties
    {
        _MainTex1 ("Albedo 1", 2D) = "white" {}
        _MainTex2 ("Albedo 2", 2D) = "white" {}

        _WaveAmplitude ("Wave Amplitude", Float) = 0.5
        _WaveFrequency ("Wave Frequency", Float) = 1.0
        _WaveSpeed ("Wave Speed", Float) = 1.0

        _PanDir1 ("Pan Direction 1 (XY)", Vector) = (1, 0, 0, 0)
        _PanSpeed1 ("Pan Speed 1", Float) = 0.2

        _PanDir2 ("Pan Direction 2 (XY)", Vector) = (0, 1, 0, 0)
        _PanSpeed2 ("Pan Speed 2", Float) = 0.15

        _HeightColor ("Height Color", Color) = (1,1,1,1)
        _HeightIntensity ("Height Intensity", Float) = 1.0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex1;
            sampler2D _MainTex2;

            float4 _MainTex1_ST;
            float4 _MainTex2_ST;

            float _WaveAmplitude;
            float _WaveFrequency;
            float _WaveSpeed;

            float2 _PanDir1;
            float _PanSpeed1;

            float2 _PanDir2;
            float _PanSpeed2;

            float4 _HeightColor;
            float _HeightIntensity;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv1 : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
                float height : TEXCOORD2;
            };

            v2f vert (appdata v)
            {
                v2f o;

                float time = _Time.y * _WaveSpeed;

                // Altura de la ola (en espacio objeto)
                float wave =
                    sin(v.vertex.x * _WaveFrequency + time) *
                    cos(v.vertex.z * _WaveFrequency + time);

                v.vertex.y += wave * _WaveAmplitude;

                o.height = wave;

                o.pos = UnityObjectToClipPos(v.vertex);

                // Paneo UV independiente
                o.uv1 = TRANSFORM_TEX(v.uv, _MainTex1)
                        + _PanDir1 * _PanSpeed1 * _Time.y;

                o.uv2 = TRANSFORM_TEX(v.uv, _MainTex2)
                        + _PanDir2 * _PanSpeed2 * _Time.y;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 col1 = tex2D(_MainTex1, i.uv1).rgb;
                fixed3 col2 = tex2D(_MainTex2, i.uv2).rgb;

                // Mezcla de las dos texturas
                fixed3 albedo = lerp(col1, col2, 0.5);

                // Intensidad basada en altitud
                float heightFactor = saturate(i.height * _HeightIntensity + 0.5);

                fixed3 finalColor = albedo * lerp(1.0, _HeightColor.rgb, heightFactor);

                return fixed4(finalColor, 1);
            }
            ENDCG
        }
    }
}
