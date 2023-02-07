using UnityEngine;

public class UpdateShaderToy : MonoBehaviour
{
    public Shader shader;

    private Shader _previousShader;


    private void Update()
    {
        if (shader != _previousShader)
        {
            _previousShader = shader;
            SoulScreenEffect.Instance.Change(shader.name);
        }
    }
}