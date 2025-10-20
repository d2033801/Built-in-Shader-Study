using UnityEngine;

public class Test : MonoBehaviour
{
    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        for (int i = 0; i < 100; i++)
        {
            // This is a comment
            Debug.Log("Hello World " + i);
            Debug.Log("This is a test message " + i);
        }
    }
}
