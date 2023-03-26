using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Controller
{
    [ExecuteAlways]
    public class SunMoonController : MonoBehaviour
    {
        public Light sun;
        public Light moon;

        public Vector3 rotation = Vector3.zero;

        public Material[] skyboxMaterials;

        private void Update()
        {
            if (sun != null)
            {
                sun.transform.rotation = Quaternion.Euler(rotation);
                if (Vector3.Dot(-sun.transform.forward, Vector3.up) < 0.0f)
                {
                    sun.intensity = 0.0f;
                }
                else
                {
                    sun.intensity = 1.0f;
                }
            }

            if (moon != null && sun != null)
            {
                moon.transform.forward = -sun.transform.forward;
                if (Vector3.Dot(-moon.transform.forward, Vector3.up) < 0.0f)
                {
                    moon.intensity = 0.0f;
                }
                else
                {
                    moon.intensity = 0.4f;
                }
            }

            foreach (var material in skyboxMaterials)
            {
                material.SetVector("_SunDir", -(Vector4)sun.transform.forward);
                material.SetVector("_MoonDir", -(Vector4)moon.transform.forward);
            }
        }
    }
}