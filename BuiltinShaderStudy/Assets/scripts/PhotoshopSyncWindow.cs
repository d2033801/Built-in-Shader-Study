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

        // 监视路径设置
        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("监视文件夹:", GUILayout.Width(80));
        watchPath = EditorGUILayout.TextField(watchPath);
        if (GUILayout.Button("浏览...", GUILayout.Width(60)))
        {
            string newPath = EditorUtility.OpenFolderPanel("选择监视文件夹", watchPath, "");
            if (!string.IsNullOrEmpty(newPath))
            {
                watchPath = "Assets" + newPath.Replace(Application.dataPath, "");
            }
        }
        EditorGUILayout.EndHorizontal();

        // 控制按钮
        EditorGUILayout.BeginHorizontal();
        if (GUILayout.Button(isWatching ? "停止监视" : "开始监视", GUILayout.Width(100)))
        {
            if (isWatching) StopWatching();
            else StartWatching();
        }

        if (GUILayout.Button("刷新纹理列表", GUILayout.Width(100)))
        {
            RefreshTextureList();
        }

        autoRefresh = EditorGUILayout.Toggle("自动刷新", autoRefresh, GUILayout.Width(100));
        EditorGUILayout.EndHorizontal();

        // 纹理选择
        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("选择纹理:", GUILayout.Width(80));

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

        // 预览控制
        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("预览比例:");
        previewScale = EditorGUILayout.Slider(previewScale, 0.1f, 2f, GUILayout.Width(200));

        if (GUILayout.Button("重新加载", GUILayout.Width(80)))
        {
            LoadPreviewTexture();
        }

        showLayerInfo = EditorGUILayout.Toggle("显示图层信息", showLayerInfo, GUILayout.Width(120));
        EditorGUILayout.EndHorizontal();

        // 预览区域
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

            // 显示纹理信息
            EditorGUILayout.LabelField($"尺寸: {previewTexture.width}×{previewTexture.height} | 格式: {previewTexture.format}");
        }
        else
        {
            EditorGUILayout.HelpBox("没有选择纹理或纹理加载失败", MessageType.Info);
        }

        EditorGUILayout.EndVertical();
    }

    private void DrawLayerInfo(Rect textureRect)
    {
        // 模拟图层信息 - 实际应用中需要解析PSD文件
        GUIStyle layerStyle = new GUIStyle(EditorStyles.miniLabel);
        layerStyle.normal.textColor = Color.yellow;
        layerStyle.alignment = TextAnchor.UpperLeft;

        List<string> mockLayers = new List<string>()
        {
            "背景 (可见)",
            "角色 (可见)",
            "阴影 (可见)",
            "高光 (可见)",
            "特效 (隐藏)"
        };

        GUILayout.BeginArea(new Rect(textureRect.x + 10, textureRect.y + 10, 200, 150));
        EditorGUILayout.LabelField("PSD图层信息 (模拟):", EditorStyles.boldLabel);

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
            Debug.LogError($"无法加载纹理: {path}");
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
                Debug.LogError($"监视路径不存在: {fullPath}");
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

            Debug.Log($"开始监视: {fullPath}");
        }
        catch (Exception ex)
        {
            Debug.LogError($"启动监视器失败: {ex.Message}");
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
        Debug.Log("已停止监视");
    }

    private static void OnFileChanged(object source, FileSystemEventArgs e)
    {
        // 避免重复处理
        if (fileTimestamps.ContainsKey(e.FullPath) &&
            (DateTime.Now - fileTimestamps[e.FullPath]).TotalMilliseconds < 500)
            return;

        fileTimestamps[e.FullPath] = DateTime.Now;

        // 获取Unity项目中的相对路径
        string relativePath = "Assets" + e.FullPath.Replace(Application.dataPath, "").Replace('\\', '/');

        EditorApplication.delayCall += () => {
            if (File.Exists(e.FullPath))
            {
                Debug.Log($"检测到文件更新: {relativePath}");
                AssetDatabase.ImportAsset(relativePath, ImportAssetOptions.ForceUpdate);
            }
        };
    }
}