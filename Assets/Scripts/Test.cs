using UnityEngine;

public class Test : MonoBehaviour
{
    private void Start()
    {
        Material material = gameObject.GetComponent<MeshRenderer>().material;
        Shader shader = material.shader;
        for(int i=0; i<shader.GetPropertyCount(); i++)
        {
            Debug.Log(shader.GetPropertyName(i)); // 变量名
            Debug.Log(shader.GetPropertyType(i)); // 变量类型
            Debug.Log(shader.GetPropertyDescription(i)); // 变量描述
        }

    }
}