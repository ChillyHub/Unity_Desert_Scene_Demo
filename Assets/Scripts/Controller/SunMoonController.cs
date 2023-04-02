using System;
using CustomRenderer;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.UIElements;

namespace Controller
{
    [ExecuteAlways]
    public class SunMoonController : MonoBehaviour
    {
        public Light sun;
        public Light moon;

        public Vector3 rotation = Vector3.zero;

        public Material[] skyboxMaterials;

        public bool autoRotateSun = false;
        [Range(0.0f, 1.0f)]
        public float autoRotateSpeed = 0.5f;

        public bool inverse = false;

        private void Update()
        {
            if (sun != null)
            {
                sun.transform.rotation = Quaternion.Euler(rotation);
                if (Vector3.Dot(-sun.transform.forward, Vector3.up) < 0.0f)
                {
                    sun.intensity = 0.0f;
                    sun.enabled = false;
                }
                else
                {
                    sun.intensity = 1.0f;
                    sun.enabled = true;
                }
            }

            if (moon != null && sun != null)
            {
                moon.transform.forward = -sun.transform.forward;
                if (Vector3.Dot(-moon.transform.forward, Vector3.up) < 0.0f)
                {
                    moon.intensity = 0.0f;
                    moon.enabled = false;
                }
                else
                {
                    moon.intensity = 0.2f;
                    moon.enabled = true;
                }
            }

            foreach (var material in skyboxMaterials)
            {
                material.SetVector("_SunDir", -(Vector4)sun.transform.forward);
                material.SetVector("_MoonDir", -(Vector4)moon.transform.forward);
            }

            var volume = VolumeManager.instance.stack.GetComponent<ScreenSpaceFog>();
            volume.sunDirection = -sun.transform.forward;
            volume.moonDirection = -moon.transform.forward;

            if (autoRotateSun)
            {
                float delta = Time.deltaTime * 60.0f * autoRotateSpeed * (inverse ? -1.0f : 1.0f);
                rotation.x += delta;
                if (rotation.x > 360.0f)
                {
                    rotation.x -= 360.0f;
                }
                else if (rotation.x < -360.0f)
                {
                    rotation.x += 360.0f;
                }
            }
        }
    }
}