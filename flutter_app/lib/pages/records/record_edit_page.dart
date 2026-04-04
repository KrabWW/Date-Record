import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/record_provider.dart';
import '../../widgets/mood_selector.dart';
import '../../widgets/emotion_tags.dart';

/// 记录编辑页面
class RecordEditPage extends ConsumerStatefulWidget {
  const RecordEditPage({super.key});

  @override
  ConsumerState<RecordEditPage> createState() => _RecordEditPageState();
}

class _RecordEditPageState extends ConsumerState<RecordEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _tagController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedMood = 'good';
  List<String> _selectedEmotionTags = [];
  List<String> _customTags = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRecord();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _loadRecord() async {
    final idStr = GoRouterState.of(context).pathParameters['id'];
    final isNew = idStr == 'new' || idStr == null;

    if (!isNew) {
      final id = int.tryParse(idStr ?? '') ?? 0;
      setState(() => _isLoading = true);

      final recordAsync = ref.read(currentRecordProvider(id));
      recordAsync.when(
        data: (record) {
          if (record != null) {
            setState(() {
              _titleController.text = record.title;
              _descriptionController.text = record.description ?? '';
              _locationController.text = record.location ?? '';
              _selectedDate = record.recordDate;
              _selectedMood = record.mood;
              _selectedEmotionTags = List.from(record.emotionTags);
              _customTags = List.from(record.tags);
              _isLoading = false;
            });
          } else {
            setState(() => _isLoading = false);
          }
        },
        loading: () => setState(() => _isLoading = true),
        error: (_, __) => setState(() => _isLoading = false),
      );
    }
  }

  bool get _isEditing {
    final idStr = GoRouterState.of(context).pathParameters['id'];
    return idStr != 'new' && idStr != null;
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final idStr = GoRouterState.of(context).pathParameters['id'];
      final isNew = idStr == 'new' || idStr == null;

      if (isNew) {
        await ref.read(currentRecordProvider(null).notifier).createRecord(
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              recordDate: _selectedDate,
              location: _locationController.text.trim().isEmpty
                  ? null
                  : _locationController.text.trim(),
              mood: _selectedMood,
              emotionTags: _selectedEmotionTags.isEmpty
                  ? null
                  : _selectedEmotionTags,
              tags: _customTags.isEmpty ? null : _customTags,
            );
        if (mounted) context.go('/records');
      } else {
        final id = int.tryParse(idStr ?? '') ?? 0;
        await ref.read(currentRecordProvider(id).notifier).updateRecord(
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              recordDate: _selectedDate,
              location: _locationController.text.trim().isEmpty
                  ? null
                  : _locationController.text.trim(),
              mood: _selectedMood,
              emotionTags: _selectedEmotionTags.isEmpty
                  ? null
                  : _selectedEmotionTags,
              tags: _customTags.isEmpty ? null : _customTags,
            );
        if (mounted) context.go('/records/$id');
      }
    } catch (e) {
      setState(() {
        _errorMessage = '保存失败，请稍后重试';
        _isSaving = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('zh', 'CN'),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _addCustomTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_customTags.contains(tag)) {
      setState(() {
        _customTags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeCustomTag(String tag) {
    setState(() {
      _customTags.remove(tag);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑记录' : '添加记录'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: _saveRecord,
              icon: const Icon(Icons.save),
              label: const Text('保存'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 错误提示
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          border: Border.all(color: AppTheme.error),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error, color: AppTheme.error, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: AppTheme.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 标题
                    _buildSectionTitle('记录标题 *'),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: '给这次约会起个标题吧...',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入记录标题';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // 日期
                    _buildSectionTitle('约会日期 *'),
                    InkWell(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: AppTheme.lovePink),
                            const SizedBox(width: 12),
                            Text(
                              _formatDate(_selectedDate),
                              style: const TextStyle(fontSize: 16),
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 地点
                    _buildSectionTitle('地点'),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        hintText: '在哪里度过了美好时光？',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 心情
                    _buildSectionTitle('今天的心情如何？'),
                    MoodSelector(
                      selectedMood: _selectedMood,
                      onMoodChange: (mood) {
                        setState(() {
                          _selectedMood = mood;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // 情感标签
                    _buildSectionTitle('这次约会的感觉 (最多3个)'),
                    EmotionTagsSelector(
                      selectedTags: _selectedEmotionTags,
                      onTagsChange: (tags) {
                        setState(() {
                          _selectedEmotionTags = tags;
                        });
                      },
                      maxTags: 3,
                    ),
                    const SizedBox(height: 24),

                    // 自定义标签
                    _buildSectionTitle('标签'),
                    if (_customTags.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _customTags.map((tag) {
                          return Chip(
                            label: Text(tag),
                            onDeleted: () => _removeCustomTag(tag),
                            backgroundColor: AppTheme.lovePink.withOpacity(0.1),
                            deleteIconColor: AppTheme.lovePink,
                            labelStyle: const TextStyle(color: AppTheme.lovePink),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _tagController,
                            decoration: const InputDecoration(
                              hintText: '如：浪漫、海边、生日...',
                              prefixIcon: Icon(Icons.local_offer),
                            ),
                            onFieldSubmitted: (_) => _addCustomTag(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addCustomTag,
                          child: const Text('添加'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 详细描述
                    _buildSectionTitle('详细描述'),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        hintText: '记录这次约会的美好细节...',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '可以记录约会的具体过程、感受、有趣的事情等',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 提交按钮
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveRecord,
                            child: Text(_isSaving ? '保存中...' : (_isEditing ? '更新记录' : '创建记录')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: _isSaving
                              ? null
                              : () {
                                  if (_isEditing) {
                                    final idStr = GoRouterState.of(context).pathParameters['id'];
                                    context.go('/records/$idStr');
                                  } else {
                                    context.go('/records');
                                  }
                                },
                          child: const Text('取消'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    const months = [
      '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'
    ];
    return '${date.year}年${months[date.month - 1]}月${date.day}日 ${weekdays[date.weekday - 1]}';
  }
}
