using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace CustomRenderer
{
    public class PathRecordPass : ScriptableRenderPass
    {
        private ProfilingSampler _profilingSampler;

        private Material _blitMaterial;

        private RenderTargetHandle _source;
        private RenderTargetHandle _destination;

        private FilteringSettings _groundFiltering;
        private FilteringSettings _recordFiltering;
        private List<ShaderTagId> _depthShaderTagIds = new List<ShaderTagId>();
        private List<ShaderTagId> _recordShaderTagIds = new List<ShaderTagId>();
        
        private readonly int _textureSize;
        private readonly float _recordDistance;
        private Vector3 _curCameraPosition = Vector3.zero;
        private Vector3 _preCameraPosition = Vector3.zero;

        private readonly int PathRecordTextureId;

        private static readonly int OrthoProjectionParams = Shader.PropertyToID("_OrthoProjectionParams");
        private static readonly int GroundDepthTextureId = Shader.PropertyToID("_GroundDepthTexture");
        private static readonly int SourceRecordTextureId = Shader.PropertyToID("_SourceRecordTexture");
        private static readonly int CurrentRecordTextureId = Shader.PropertyToID("_CurrentRecordTexture");
        private static readonly int PreOriginalPositionId = Shader.PropertyToID("_PreOriginalPosition");
        private static readonly int OriginalPositionId = Shader.PropertyToID("_OriginalPosition");
        private static readonly int RecordDistanceId = Shader.PropertyToID("_RecordDistance");

        public PathRecordPass(string profilingTag, float recordDistance, 
            PathRecordRendererFeature.FilterSetting filterSetting,
            PathRecordRendererFeature.RenderTextureSetting renderTextureSetting)
        {
            this.profilingSampler = new ProfilingSampler(nameof(PathRecordPass));

            _profilingSampler = new ProfilingSampler(profilingTag);

            Shader blitShader = Shader.Find("Hidden/Custom/Path Record Blit");
            _blitMaterial = CoreUtils.CreateEngineMaterial(blitShader);

            _groundFiltering = new FilteringSettings(RenderQueueRange.all, (int)filterSetting.groundLayerMask);
            _recordFiltering = new FilteringSettings(RenderQueueRange.all, (int)filterSetting.recordLayerMask);

            foreach (var name in filterSetting.depthPassName)
            {
                _depthShaderTagIds.Add(new ShaderTagId(name));
            }

            foreach (var name in filterSetting.pathRecordPassName)
            {
                _recordShaderTagIds.Add(new ShaderTagId(name));
            }
            
            _recordDistance = recordDistance;
            _textureSize = (int)renderTextureSetting.textureSize;

            PathRecordTextureId = Shader.PropertyToID(renderTextureSetting.textureName);
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            var desc1 = new RenderTextureDescriptor(_textureSize, _textureSize, RenderTextureFormat.RFloat);
            cmd.GetTemporaryRT(GroundDepthTextureId, desc1);

            var desc2 = new RenderTextureDescriptor(_textureSize, _textureSize, RenderTextureFormat.Default);
            cmd.GetTemporaryRT(CurrentRecordTextureId, desc2);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            // TODO: Set drawing setting
            SortingCriteria sortingCriteria = renderingData.cameraData.defaultOpaqueSortFlags;

            DrawingSettings depthDrawingSettings = CreateDrawingSettings(
                _depthShaderTagIds, ref renderingData, sortingCriteria);
            DrawingSettings recordDrawingSettings = CreateDrawingSettings(
                _recordShaderTagIds, ref renderingData, sortingCriteria);

            CommandBuffer cmd = CommandBufferPool.Get();
            using (new ProfilingScope(cmd, _profilingSampler))
            {
                // TODO: Set ortho view projection override
                const float near = -5.0f;
                const float far = 5.0f;
                Matrix4x4 projection = Matrix4x4.Ortho(
                    -_recordDistance, _recordDistance, -_recordDistance, _recordDistance, near, far);
                projection = GL.GetGPUProjectionMatrix(
                    projection, renderingData.cameraData.IsCameraProjectionMatrixFlipped());

                var volume = VolumeManager.instance.stack.GetComponent<PathRecord>();
                _preCameraPosition = _curCameraPosition;
                _curCameraPosition = volume.focusPosition;

                Matrix4x4 view = Matrix4x4.zero;
                view[0, 0] = 1.0f;
                view[1, 2] = -1.0f;
                view[2, 1] = -1.0f;
                view[3, 3] = 1.0f;
                view[0, 3] = -_curCameraPosition.x;
                view[1, 3] = _curCameraPosition.z;
                view[2, 3] = _curCameraPosition.y;

                float reversed = (float)Convert.ToInt32(SystemInfo.usesReversedZBuffer);
                Vector4 orthoParams = new Vector4(near, far, reversed, 0.0f);

                RenderingUtils.SetViewAndProjectionMatrices(cmd, view, projection, true);

                // TODO: Render Depth map of Ground
                cmd.SetRenderTarget(new RenderTargetIdentifier(GroundDepthTextureId));
                cmd.ClearRenderTarget(false, true, Color.black, 0.0f);
                // Ensure we flush our command-buffer before we render...
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();
                
                context.DrawRenderers(renderingData.cullResults, ref depthDrawingSettings, ref _groundFiltering);

                // TODO: Render Avatar and compare depth to make sure whether intersect
                cmd.SetRenderTarget(new RenderTargetIdentifier(CurrentRecordTextureId));
                cmd.ClearRenderTarget(false, true, Color.black, 0.0f);
                cmd.SetGlobalVector(OrthoProjectionParams, orthoParams);
                // Ensure we flush our command-buffer before we render...
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();
                
                context.DrawRenderers(renderingData.cullResults, ref recordDrawingSettings, ref _recordFiltering);
                
                // TODO: Blit to destination and attenuation
                cmd.SetRenderTarget(_destination.Identifier());
                cmd.SetGlobalVector(PreOriginalPositionId, (Vector4)_preCameraPosition);
                cmd.SetGlobalVector(OriginalPositionId, (Vector4)_curCameraPosition);
                cmd.SetGlobalFloat(RecordDistanceId, _recordDistance);
                cmd.SetGlobalTexture(SourceRecordTextureId, _source.Identifier());
                cmd.SetGlobalTexture(CurrentRecordTextureId, new RenderTargetIdentifier(CurrentRecordTextureId));
                
                cmd.Blit(_source.Identifier(), _destination.Identifier(), _blitMaterial);
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                // TODO: Reset culling and camera data
                RenderingUtils.SetViewAndProjectionMatrices(
                    cmd, renderingData.cameraData.GetViewMatrix(), 
                    renderingData.cameraData.GetGPUProjectionMatrix(), true);
                cmd.SetRenderTarget(renderingData.cameraData.renderer.cameraColorTarget);
                cmd.SetGlobalTexture(PathRecordTextureId, _destination.Identifier());
            }
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            if (cmd == null)
                throw new ArgumentNullException("cmd");
            
            cmd.ReleaseTemporaryRT(GroundDepthTextureId);
            cmd.ReleaseTemporaryRT(CurrentRecordTextureId);
        }

        public void Setup(RenderTargetIdentifier source, RenderTargetIdentifier destination)
        {
            _source.Init(source);
            _destination.Init(destination);
            
            this.renderPassEvent = RenderPassEvent.BeforeRenderingGbuffer;
        }
    }
}