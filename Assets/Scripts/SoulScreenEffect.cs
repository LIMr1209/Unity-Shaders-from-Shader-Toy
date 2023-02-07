using System.Linq;
using System.Reflection;
using UnityEngine;
using UnityEngine.Rendering.Universal;

public class SoulScreenEffect : MonoBehaviour
{
    private static SoulScreenEffect _instance;
    public static SoulScreenEffect Instance
    {
        get
        {
            if (_instance == null)
            {
                _instance = FindObjectOfType(typeof(SoulScreenEffect)) as SoulScreenEffect;
            }

            return _instance;
        }
    }
    
    private Shader _currentShader;
    

    public void Change(string shaderName)
    {
        Shader shader = Shader.Find(shaderName); // ShaderToy/"+
        if(!shader) return;
        if (_currentShader == shader)
        {
            // 更新 材质属性
            // ShaderToyHelperMouse.Instance.material
        }
        else
        {
            UniversalRenderPipelineAsset pipelineAsset = (UniversalRenderPipelineAsset) QualitySettings.renderPipeline;
            FieldInfo propertyInfo = pipelineAsset.GetType()
                .GetField("m_RendererDataList", BindingFlags.Instance | BindingFlags.NonPublic);
            var _scriptableRendererData = ((ScriptableRendererData[]) propertyInfo?.GetValue(pipelineAsset))?[0];
            var shaderToyScreenEffectRenderVolumeFeature = _scriptableRendererData.rendererFeatures
                .OfType<ShaderToyScreenEffectRenderVolumeFeature>().FirstOrDefault();
            if (shaderToyScreenEffectRenderVolumeFeature == null) return;
            Material material = new Material(shader);
            material.SetFloat("_ScreenEffect", 1);
            shaderToyScreenEffectRenderVolumeFeature.settings.material = material;
            ShaderToyHelperMouse.Instance.material = material;
            GetComponent<MeshRenderer>().material = material;
            _scriptableRendererData.SetDirty();
        }
    }


    public void OnDestroy()
    {
        UniversalRenderPipelineAsset pipelineAsset = (UniversalRenderPipelineAsset) QualitySettings.renderPipeline;
        FieldInfo propertyInfo = pipelineAsset.GetType()
            .GetField("m_RendererDataList", BindingFlags.Instance | BindingFlags.NonPublic);
        var _scriptableRendererData = ((ScriptableRendererData[]) propertyInfo?.GetValue(pipelineAsset))?[0];
        var shaderToyScreenEffectRenderVolumeFeature = _scriptableRendererData.rendererFeatures
            .OfType<ShaderToyScreenEffectRenderVolumeFeature>().FirstOrDefault();
        if (shaderToyScreenEffectRenderVolumeFeature == null) return;
        shaderToyScreenEffectRenderVolumeFeature.settings.material = null;
        ShaderToyHelperMouse.Instance.material =  null;
        GetComponent<MeshRenderer>().material = null;
        _scriptableRendererData.SetDirty();
    }
}