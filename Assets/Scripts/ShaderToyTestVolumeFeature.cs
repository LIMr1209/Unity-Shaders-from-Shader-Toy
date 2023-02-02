using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;


public class ShaderToyTestVolumeFeature : ScriptableRendererFeature
{
    // 创建可编写脚本的渲染通道
    class ShaderToyTestRenderVolumePass : ScriptableRenderPass
    {
        Settings settings;

        RenderTargetIdentifier source;

        public ShaderToyTestRenderVolumePass(Settings customSettings)
        {
            settings = customSettings;
            renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            RenderTextureDescriptor descriptor = renderingData.cameraData.cameraTargetDescriptor;
            descriptor.depthBufferBits = 0;

            var renderer = renderingData.cameraData.renderer;
            source = renderer.cameraColorTarget;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.isSceneViewCamera)
                return;

            var material = settings.material;
            CommandBuffer cmd = CommandBufferPool.Get("ShaderToyTest");
            cmd.Clear();

            Blit(cmd, source, source, material, 0);

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
        }
    }

    [System.Serializable]
    public class Settings
    {
        public Material originMaterial;
        [HideInInspector]public Material material;
    }

    public Settings settings = new Settings();
    private ShaderToyTestRenderVolumePass _scriptablePass;

    // Unity 在以下事件上调用此方法：
    //渲染器功能第一次加载时。
    //当您启用或禁用渲染器功能时。
    //当您在渲染器功能的检查器中更改属性时。
    public override void Create()
    {
        _scriptablePass = new ShaderToyTestRenderVolumePass(settings);
        if (settings.originMaterial)
        {
            settings.material = Instantiate(settings.originMaterial);
            settings.material.SetFloat("_ScreenEffect", 1);
            ShaderToyHelper.Instance.material = settings.material;
        }
        else
        {
            settings.material = null;
        }
    }


    // Unity每帧调用一次这个方法，每个Camera调用一次。此方法允许您将ScriptableRenderPass实例注入到可编写脚本的渲染器中。
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        var stack = VolumeManager.instance.stack;
        if(settings.material) renderer.EnqueuePass(_scriptablePass); // 在渲染队列中入队
    }
}