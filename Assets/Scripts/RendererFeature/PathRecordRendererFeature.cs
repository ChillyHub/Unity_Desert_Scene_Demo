using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.Serialization;

namespace CustomRenderer
{
    public class PathRecordRendererFeature : ScriptableRendererFeature
    {
        [Range(5.0f, 20.0f)] 
        public float recordDistance = 5.0f;

        [Serializable]
        public class RenderTextureSetting
        {
            public enum TextureSize : int
            {
                _256x256 = 256,
                _512x512 = 512,
                _1024x1024 = 1024,
                _2048x2048 = 2048,
                _4096x4096 = 4096
            }
            public TextureSize textureSize = TextureSize._1024x1024;

            public string textureName = "_PathRecordTexture";
        }
        public RenderTextureSetting renderTextureSetting = new RenderTextureSetting();
        
        [Serializable]
        public class FilterSetting
        {
            public LayerMask groundLayerMask;
            public LayerMask recordLayerMask;
            public string[] depthPassName;
            public string[] pathRecordPassName;

            public FilterSetting()
            {
                depthPassName = new string[1];
                pathRecordPassName = new string[1];
                depthPassName[0] = "CustomDepth";
                pathRecordPassName[0] = "PathRecord";
            }
        }
        public FilterSetting filterSetting = new FilterSetting();

        private RenderTexture _temp1;
        private RenderTexture _temp2;
        private RenderTargetIdentifier _source;
        private RenderTargetIdentifier _destination;
        
        private PathRecordPass _pass; 

        private const string ProfilingTag = "Path Record";
        
        public override void Create()
        {
            _pass = new PathRecordPass(ProfilingTag, recordDistance, filterSetting, renderTextureSetting);
            
            if (_temp1 == null || _temp2 == null)
            {
                CreateRenderTextures(renderTextureSetting);
            }
            if (_temp1.width != (int)renderTextureSetting.textureSize)
            {
                ReleaseRenderTextures();
                CreateRenderTextures(renderTextureSetting);
            }

            _source = new RenderTargetIdentifier(_temp1);
            _destination = new RenderTargetIdentifier(_temp2);
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            _pass.Setup(_source, _destination);
            renderer.EnqueuePass(_pass);
            SwapRenderTextures();
        }

        private void OnDisable()
        {
            ReleaseRenderTextures();
        }

        private void OnDestroy()
        {
            ReleaseRenderTextures();
        }

        void SwapRenderTextures()
        {
            CoreUtils.Swap(ref _source, ref _destination);
        }

        void CreateRenderTextures(RenderTextureSetting rts)
        {
            int size = (int)rts.textureSize;
            var desc = new RenderTextureDescriptor(size, size, RenderTextureFormat.Default);
            _temp1 = RenderTexture.GetTemporary(desc);
            _temp2 = RenderTexture.GetTemporary(desc);
        }

        void ReleaseRenderTextures()
        {
            RenderTexture.ReleaseTemporary(_temp1);
            RenderTexture.ReleaseTemporary(_temp2);
            _temp1 = null;
            _temp2 = null;
        }
    }
}