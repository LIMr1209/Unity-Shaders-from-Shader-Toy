using UnityEngine;

public class BirthdayBalloons : MonoBehaviour
{
    public int Resolution = 1024;
    RenderTexture input, output;
    bool swap = true;
    private Shader m_shader;

    private Material m_Material;

    public Material material
    {
        get
        {
            if (m_Material == null)
            {
                m_Material = new Material(shader);
                m_Material.hideFlags = HideFlags.HideAndDontSave;
            }

            return m_Material;
        }
    }

    public Shader shader
    {
        get
        {
            if (m_shader == null)
            {
                m_shader = Shader.Find("Unlit/BirthdayBalloons");
            }

            return m_shader;
        }
    }

    void Blit(RenderTexture source, RenderTexture destination, Material mat, string name)
    {
        RenderTexture.active = destination;
        mat.SetTexture(name, source);
        GL.PushMatrix();
        GL.LoadOrtho();
        GL.invertCulling = true;
        mat.SetPass(0);
        GL.Begin(GL.QUADS);
        GL.MultiTexCoord2(0, 0.0f, 0.0f);
        GL.Vertex3(0.0f, 0.0f, 0.0f);
        GL.MultiTexCoord2(0, 1.0f, 0.0f);
        GL.Vertex3(1.0f, 0.0f, 0.0f);
        GL.MultiTexCoord2(0, 1.0f, 1.0f);
        GL.Vertex3(1.0f, 1.0f, 1.0f);
        GL.MultiTexCoord2(0, 0.0f, 1.0f);
        GL.Vertex3(0.0f, 1.0f, 0.0f);
        GL.End();
        GL.invertCulling = false;
        GL.PopMatrix();
    }

    void Start()
    {
        input = new RenderTexture(Resolution, Resolution, 0,
            RenderTextureFormat.ARGBFloat); //buffer must be floating point RT
        output = new RenderTexture(Resolution, Resolution, 0,
            RenderTextureFormat.ARGBFloat); //buffer must be floating point RT
        GetComponent<Renderer>().material = material;
    }

    void Update()
    {
        RaycastHit hit;
        if (Input.GetMouseButton(0))
        {
            if (Physics.Raycast(Camera.main.ScreenPointToRay(Input.mousePosition), out hit))
                material.SetVector("iMouse", new Vector4(
                    hit.textureCoord.x * Resolution, hit.textureCoord.y * Resolution,
                    Mathf.Sign(System.Convert.ToSingle(Input.GetMouseButton(0))),
                    Mathf.Sign(System.Convert.ToSingle(Input.GetMouseButton(1)))));
        }
        else
        {
            material.SetVector("iMouse", new Vector4(0.0f, 0.0f, -1.0f, -1.0f));
        }

        material.SetFloat("_Resolution", Resolution);

        if (swap)
        {
            // material.SetTexture("_MainTex", input);
            Blit(input, output, material, "_MainTex");
            // material.SetTexture("_MainTex", output);
        }
        else
        {
            // material.SetTexture("_MainTex", output);
            Blit(output, input, material, "_MainTex");
            // material.SetTexture("_MainTex", input);
        }

        swap = !swap;
    }

    void OnDestroy()
    {
        input.Release();
        output.Release();
    }
}