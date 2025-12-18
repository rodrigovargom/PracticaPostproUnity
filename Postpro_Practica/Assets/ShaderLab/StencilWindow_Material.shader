Shader "Custom/StencilWindow"
{
    Properties
    {
        _StencilID ("Stencil ID", Int) = 1
    }
    SubShader
    {
        Tags { "Queue"="Geometry-1" "RenderType"="Opaque" }
        ColorMask 0
        ZWrite Off

        Pass
        {
            Stencil
            {
                Ref [_StencilID]
                Comp Always
                Pass Replace
            }
        }
    }

    
}
