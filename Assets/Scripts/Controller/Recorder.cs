using CustomRenderer;
using UnityEngine;
using UnityEngine.Rendering;

namespace Controller
{
    [ExecuteAlways]
    public class Recorder : MonoBehaviour
    {
        private void Update()
        {
            var volume = VolumeManager.instance.stack.GetComponent<PathRecord>();

            volume.focusPosition = transform.position;
        }
    }
}