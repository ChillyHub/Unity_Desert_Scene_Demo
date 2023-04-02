using System;
using CustomRenderer;
using UnityEngine;
using UnityEngine.Rendering;

namespace Component
{
    [ExecuteAlways]
    public class ReflectionPlane : MonoBehaviour
    {
        private void Update()
        {
            var volume = VolumeManager.instance.stack.GetComponent<ScreenSpacePlanarReflection>();

            volume.PlanePosition = transform.position;
            volume.PlaneNormal = transform.up;
        }
    }
}