import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class EditNovaProject {
  const EditNovaProject({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.sourceAssetPath,
    this.currentAssetPath,
    this.exportHistory = const [],
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? sourceAssetPath;
  final String? currentAssetPath;
  final List<String> exportHistory;

  EditNovaProject copyWith({
    String? name,
    DateTime? updatedAt,
    String? sourceAssetPath,
    String? currentAssetPath,
    List<String>? exportHistory,
  }) {
    return EditNovaProject(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sourceAssetPath: sourceAssetPath ?? this.sourceAssetPath,
      currentAssetPath: currentAssetPath ?? this.currentAssetPath,
      exportHistory: exportHistory ?? this.exportHistory,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        if (sourceAssetPath != null) 'sourceAssetPath': sourceAssetPath,
        if (currentAssetPath != null) 'currentAssetPath': currentAssetPath,
        'exportHistory': exportHistory,
      };

  static EditNovaProject? fromJson(Map<String, dynamic> json) {
    try {
      return EditNovaProject(
        id: json['id'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        sourceAssetPath: json['sourceAssetPath'] as String?,
        currentAssetPath: json['currentAssetPath'] as String?,
        exportHistory: (json['exportHistory'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toList(),
      );
    } on Object {
      return null;
    }
  }
}

class ProjectRepository {
  const ProjectRepository._();

  static const _projectsKey = 'editnova.projects';

  static Future<List<EditNovaProject>> list() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_projectsKey);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(EditNovaProject.fromJson)
          .whereType<EditNovaProject>()
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } on Object {
      return [];
    }
  }

  static Future<EditNovaProject> create(String name) async {
    final now = DateTime.now().toUtc();
    final project = EditNovaProject(
      id: '${now.microsecondsSinceEpoch}',
      name: name.trim().isEmpty ? 'Untitled project' : name.trim(),
      createdAt: now,
      updatedAt: now,
    );
    final projects = await list();
    await _write([project, ...projects]);
    return project;
  }

  static Future<void> save(EditNovaProject project) async {
    final projects = await list();
    final updated = [
      project,
      ...projects.where((item) => item.id != project.id),
    ];
    await _write(updated);
  }

  static Future<void> delete(String id) async {
    final projects = await list();
    await _write(projects.where((project) => project.id != id).toList());
  }

  static Future<void> _write(List<EditNovaProject> projects) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _projectsKey,
      jsonEncode(projects.map((project) => project.toJson()).toList()),
    );
  }
}