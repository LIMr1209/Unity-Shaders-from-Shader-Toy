using UnityEngine;


// [ExecuteInEditMode] // 编辑模式下 可以运行
public class BMtesting03: MonoBehaviour
{
    public int Resolution = 1024;
    public Material material;
    private RenderTexture RTA1, RTA2;

    void Start()
    {
        RTA1 = CreateRT();
        RTA2 = CreateRT();
        GetComponent<Renderer>().material = material;
        
        material.SetFloat("_Resolution", Resolution);
    }
    
    public RenderTexture CreateRT()
    {
        RenderTexture rt = new RenderTexture(Resolution, Resolution, 0, RenderTextureFormat.ARGBFloat);
        rt.Create();
        return rt;
    }
    

    void Update()
    {
        Graphics.Blit(RTA1,RTA2,material,0);
        material.SetTexture("iChannel0", RTA2);
        Graphics.Blit(RTA2,RTA1,material,1);
    }

    void OnDestroy()
    {
        RTA1.Release();
        RTA2.Release();
    }
}