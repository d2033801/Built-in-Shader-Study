using UnityEngine;
using UnityEditor;
using System.IO;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine.UI;
using System;

public class PhotoshopSyncWindow : EditorWindow
{
    private static FileSystemWatcher watcher;
    private static bool isWatching = false;
    private static string watchPath = "Assets/";
    private static Dictionary<string, DateTime> fileTimestamps = new Dictionary<string, DateTime>();

    private Texture2D previewTexture;
    private Vector2 scrollPosition;
    private string[] allTextures;
    private int selectedTextureIndex = 0;
    private float previewScale = 1f;
    private bool autoRefresh = true;
    private bool showLayerInfo = true;

    [MenuItem("Tools/Photoshop Sync")]
    public static void ShowWindow()
    {
        GetWindow<PhotoshopSyncWindow>("Photoshop Sync");
    }

    private void OnEnable()
    {
        RefreshTextureList();
        StartWatching();
    }

    private void OnDisable()
    {
        StopWatching();
    }

    private void OnGUI()
    {
        DrawControls();
        DrawPreview();
    }

    private void DrawControls()
    {
        EditorGUILayout.BeginVertical(EditorStyles.helpBox, GUILayout.Height(80));

        // ����·������
        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("�����ļ���:", GUILayout.Width(80));
        watchPath = EditorGUILayout.TextField(watchPath);
        if (GUILayout.Button("���...", GUILayout.Width(60)))
        {
            string newPath = EditorUtility.OpenFolderPanel("ѡ������ļ���", watchPath, "");
            if (!string.IsNullOrEmpty(newPath))
            {
                watchPath = "Assets" + newPath.Replace(Application.dataPath, "");
            }
        }
        EditorGUILayout.EndHorizontal();

        // ���ư�ť
        EditorGUILayout.BeginHorizontal();
        if (GUILayout.Button(isWatching ? "ֹͣ����" : "��ʼ����", GUILayout.Width(100)))
        {
            if (isWatching) StopWatching();
            else StartWatching();
        }

        if (GUILayout.Button("ˢ�������б�", GUILayout.Width(100)))
        {
            RefreshTextureList();
        }

        autoRefresh = EditorGUILayout.Toggle("�Զ�ˢ��", autoRefresh, GUILayout.Width(100));
        EditorGUILayout.EndHorizontal();

        // ����ѡ��
        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("ѡ������:", GUILayout.Width(80));

        if (allTextures != null && allTextures.Length > 0)
        {
            int newIndex = EditorGUILayout.Popup(selectedTextureIndex, allTextures);
            if (newIndex != selectedTextureIndex)
            {
                selectedTextureIndex = newIndex;
                LoadPreviewTexture();
            }
        }

        EditorGUILayout.EndHorizontal();

        EditorGUILayout.EndVertical();
    }

    private void DrawPreview()
    {
        EditorGUILayout.BeginVertical(EditorStyles.helpBox);

        // Ԥ������
        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("Ԥ������:");
        previewScale = EditorGUILayout.Slider(previewScale, 0.1f, 2f, GUILayout.Width(200));

        if (GUILayout.Button("���¼���", GUILayout.Width(80)))
        {
            LoadPreviewTexture();
        }

        showLayerInfo = EditorGUILayout.Toggle("��ʾͼ����Ϣ", showLayerInfo, GUILayout.Width(120));
        EditorGUILayout.EndHorizontal();

        // Ԥ������
        EditorGUILayout.Space();

        if (previewTexture != null)
        {
            float width = previewTexture.width * previewScale;
            float height = previewTexture.height * previewScale;

            scrollPosition = EditorGUILayout.BeginScrollView(scrollPosition, GUILayout.Height(Mathf.Min(height, 600) + 20));

            Rect textureRect = GUILayoutUtility.GetRect(width, height);
            EditorGUI.DrawTextureTransparent(textureRect, previewTexture);

            if (showLayerInfo)
            {
                DrawLayerInfo(textureRect);
            }

            EditorGUILayout.EndScrollView();

            // ��ʾ������Ϣ
            EditorGUILayout.LabelField($"�ߴ�: {previewTexture.width}��{previewTexture.height} | ��ʽ: {previewTexture.format}");
        }
        else
        {
            EditorGUILayout.HelpBox("û��ѡ��������������ʧ��", MessageType.Info);
        }

        EditorGUILayout.EndVertical();
    }

    private void DrawLayerInfo(Rect textureRect)
    {
        // ģ��ͼ����Ϣ - ʵ��Ӧ������Ҫ����PSD�ļ�
        GUIStyle layerStyle = new GUIStyle(EditorStyles.miniLabel);
        layerStyle.normal.textColor = Color.yellow;
        layerStyle.alignment = TextAnchor.UpperLeft;

        List<string> mockLayers = new List<string>()
        {
            "���� (�ɼ�)",
            "��ɫ (�ɼ�)",
            "��Ӱ (�ɼ�)",
            "�߹� (�ɼ�)",
            "��Ч (����)"
        };

        GUILayout.BeginArea(new Rect(textureRect.x + 10, textureRect.y + 10, 200, 150));
        EditorGUILayout.LabelField("PSDͼ����Ϣ (ģ��):", EditorStyles.boldLabel);

        foreach (string layer in mockLayers)
        {
            EditorGUILayout.LabelField(layer, layerStyle);
        }

        GUILayout.EndArea();
    }

    private void RefreshTextureList()
    {
        allTextures = AssetDatabase.FindAssets("t:Texture2D")
            .Select(guid => AssetDatabase.GUIDToAssetPath(guid))
            .Where(path => Path.GetExtension(path).ToLower() == ".psd" ||
                          Path.GetExtension(path).ToLower() == ".png" ||
                          Path.GetExtension(path).ToLower() == ".jpg")
            .ToArray();

        if (allTextures.Length > 0)
        {
            LoadPreviewTexture();
        }
    }

    private void LoadPreviewTexture()
    {
        if (allTextures == null || allTextures.Length == 0) return;

        string path = allTextures[selectedTextureIndex];
        previewTexture = AssetDatabase.LoadAssetAtPath<Texture2D>(path);

        if (previewTexture == null)
        {
            Debug.LogError($"�޷���������: {path}");
        }
    }

    private static void StartWatching()
    {
        if (isWatching) return;

        try
        {
            string fullPath = Path.GetFullPath(watchPath);
            if (!Directory.Exists(fullPath))
            {
                Debug.LogError($"����·��������: {fullPath}");
                return;
            }

            watcher = new FileSystemWatcher
            {
                Path = fullPath,
                NotifyFilter = NotifyFilters.LastWrite,
                Filter = "*.psd;*.png;*.jpg;*.jpeg",
                IncludeSubdirectories = true
            };

            watcher.Changed += OnFileChanged;
            watcher.EnableRaisingEvents = true;
            isWatching = true;

            Debug.Log($"��ʼ����: {fullPath}");
        }
        catch (Exception ex)
        {
            Debug.LogError($"����������ʧ��: {ex.Message}");
        }
    }

    private static void StopWatching()
    {
        if (!isWatching) return;

        if (watcher != null)
        {
            watcher.EnableRaisingEvents = false;
            watcher.Dispose();
        }

        isWatching = false;
        Debug.Log("��ֹͣ����");
    }

    private static void OnFileChanged(object source, FileSystemEventArgs e)
    {
        // �����ظ�����
        if (fileTimestamps.ContainsKey(e.FullPath) &&
            (DateTime.Now - fileTimestamps[e.FullPath]).TotalMilliseconds < 500)
            return;

        fileTimestamps[e.FullPath] = DateTime.Now;

        // ��ȡUnity��Ŀ�е����·��
        string relativePath = "Assets" + e.FullPath.Replace(Application.dataPath, "").Replace('\\', '/');

        EditorApplication.delayCall += () => {
            if (File.Exists(e.FullPath))
            {
                Debug.Log($"��⵽�ļ�����: {relativePath}");
                AssetDatabase.ImportAsset(relativePath, ImportAssetOptions.ForceUpdate);
            }
        };
    }
}