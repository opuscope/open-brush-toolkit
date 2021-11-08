
// ---------------------------------------------------------------------------
// Includes
// ---------------------------------------------------------------------------

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

// ---------------------------------------------------------------------------
// InputData
// ---------------------------------------------------------------------------

void InitializeInputData(Varyings input, half3 normalTS, out InputData inputData) {
	inputData = (InputData)0; // avoids "not completely initalized" errors

	inputData.positionWS = input.positionWS;

	#ifdef _NORMALMAP
		half3 viewDirWS = half3(input.normalWS.w, input.tangentWS.w, input.bitangentWS.w);
		inputData.normalWS = TransformTangentToWorld(normalTS,half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz));
	#else
		half3 viewDirWS = GetWorldSpaceNormalizeViewDir(inputData.positionWS);
		inputData.normalWS = input.normalWS;
	#endif

	inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
	viewDirWS = SafeNormalize(viewDirWS);

	inputData.viewDirectionWS = viewDirWS;

	#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
		inputData.shadowCoord = input.shadowCoord;
	#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
		inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
	#else
		inputData.shadowCoord = float4(0, 0, 0, 0);
	#endif

	// Fog
	#ifdef _ADDITIONAL_LIGHTS_VERTEX
		inputData.fogCoord = input.fogFactorAndVertexLight.x;
		inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
	#else
		inputData.fogCoord = input.fogFactor;
		inputData.vertexLighting = half3(0, 0, 0);
	#endif

	/* in v11/v12?, could use :
	#ifdef _ADDITIONAL_LIGHTS_VERTEX
		inputData.fogCoord = InitializeInputDataFog(float4(inputData.positionWS, 1.0), input.fogFactorAndVertexLight.x);
		inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
	#else
		inputData.fogCoord = InitializeInputDataFog(float4(inputData.positionWS, 1.0), input.fogFactor);
		inputData.vertexLighting = half3(0, 0, 0);
	#endif
	*/

	inputData.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, inputData.normalWS);
	inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
	inputData.shadowMask = SAMPLE_SHADOWMASK(input.lightmapUV);
}