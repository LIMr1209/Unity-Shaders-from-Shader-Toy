using UnityEngine;

public class Dynamism : MonoBehaviour
{
    public int Resolution = 1024;
    public Material material;
    private RenderTexture RTA1, RTA2, RTB1, RTB2, RTC1, RTC2, RTD1, RTD2;

    void Blit(RenderTexture source, RenderTexture destination, Material mat, string name, int pass)
    {
        RenderTexture.active = destination;               
        mat.SetTexture(name, source);
        GL.PushMatrix();
        GL.LoadOrtho();
        GL.invertCulling = true;
        mat.SetPass(pass);
        GL.Begin(GL.QUADS);
        GL.MultiTexCoord2(0, 0.0f, 0.0f);
        GL.Vertex3(0.0f, 0.0f, 0.0f);
        GL.MultiTexCoord2(0, 1.0f, 0.0f);
        GL.Vertex3(1.0f, 0.0f, 0.0f);
        GL.MultiTexCoord2(0, 1.0f, 1.0f);
        GL.Vertex3(1.0f, 1.0f, 0.0f);
        GL.MultiTexCoord2(0, 0.0f, 1.0f);
        GL.Vertex3(0.0f, 1.0f, 0.0f);
        GL.End();
        GL.invertCulling = false;
        GL.PopMatrix();
    }

    void Start()
    {
        RTA1 = new RenderTexture(Resolution, Resolution, 0,
            RenderTextureFormat.ARGBFloat); //buffer must be floating point RT
        RTA2 = new RenderTexture(Resolution, Resolution, 0,
            RenderTextureFormat.ARGBFloat); //buffer must be floating point RT
        RTB1 = new RenderTexture(Resolution, Resolution, 0,
            RenderTextureFormat.ARGBFloat); //buffer must be floating point RT
        RTB2 = new RenderTexture(Resolution, Resolution, 0,
            RenderTextureFormat.ARGBFloat); //buffer must be floating point RT
        RTC1 = new RenderTexture(Resolution, Resolution, 0,
            RenderTextureFormat.ARGBFloat); //buffer must be floating point RT
        RTC2 = new RenderTexture(Resolution, Resolution, 0,
            RenderTextureFormat.ARGBFloat); //buffer must be floating point RT
        RTD1 = new RenderTexture(Resolution, Resolution, 0,
            RenderTextureFormat.ARGBFloat); //buffer must be floating point RT
        RTD2 = new RenderTexture(Resolution, Resolution, 0,
            RenderTextureFormat.ARGBFloat); //buffer must be floating point RT
        GetComponent<Renderer>().material = material;
    }

    void Update()
    {
        material.SetFloat("_Resolution", Resolution);

        Blit(RTA1, RTA2, material, "iChannel0", 0);
        Blit(RTB1, RTB2, material, "iChannel1", 1);

        material.SetTexture("iChannel0", RTA2);
        material.SetTexture("iChannel1", RTB2);
        Blit(RTC1, RTC2, material, "iChannel2", 2);
        material.SetTexture("iChannel2", RTC2);
        
        Blit(RTD1, RTD2, material, "iChannel2", 3);
    }

    void OnDestroy()
    {
        RTA1.Release();
        RTA2.Release();
        RTB1.Release();
        RTB2.Release();
        RTC1.Release();
        RTC2.Release();
        RTD1.Release();
        RTD2.Release();
    }
}