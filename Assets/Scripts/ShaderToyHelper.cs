using UnityEngine;


public class ShaderToyHelper : MonoBehaviour
{
    private static ShaderToyHelper _instance;
    [HideInInspector] public Material material = null;

    private bool _isDragging;
    
    public static ShaderToyHelper Instance
    {
        get
        {
            if (_instance == null)
            {
                _instance = FindObjectOfType(typeof(ShaderToyHelper)) as ShaderToyHelper;
            }

            return _instance;
        }
    }


    // Use this for initialization
    void Start()
    {
        _isDragging = false;
    }

    // Update is called once per frame
    void Update()
    {
        Vector3 mousePosition = Vector3.zero;
        if (Input.GetMouseButton(0) || Input.GetMouseButton(1))
        {
            _isDragging = true;
        }
        else
        {
            _isDragging = false;
        }

        if (_isDragging)
        {
            mousePosition = new Vector3(Input.mousePosition.x, Input.mousePosition.y, 1.0f);
        }
        else
        {
            mousePosition = new Vector3(Input.mousePosition.x, Input.mousePosition.y, 0.0f);
        }

        if (material != null)
        {
            material.SetVector("_Mouse", mousePosition);
        }
    }
}