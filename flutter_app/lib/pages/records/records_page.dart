import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../models/record.dart';
import '../../providers/record_provider.dart';
import '../../widgets/mood_selector.dart';
import '../../widgets/emotion_tags.dart';

/// 记录列表页面
class RecordsPage extends ConsumerStatefulWidget {
  const RecordsPage({super.key});

  @override
  ConsumerState<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends ConsumerState<RecordsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, recent, amazing, happy, good, okay, meh
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadRecords();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadRecords() async {
    await ref.read(recordListProvider.notifier).refresh();
  }

  Future<void> _loadMore() async {
    final records = ref.read(recordListProvider);
    if (records.hasValue && records.value!.isNotEmpty) {
      final page = (records.value!.length / 20).ceil() + 1;
      await ref.read(recordListProvider.notifier).loadMore(page: page);
    }
  }

  Future<void> _onSearch(String query) async {
    setState(() {
      _searchQuery = query;
    });
    await ref.read(recordListProvider.notifier).search(query: query);
  }

  Future<void> _onFilterChanged(String filter) async {
    setState(() {
      _selectedFilter = filter;
    });

    if (filter == 'all') {
      await ref.read(recordListProvider.notifier).search(query: _searchQuery);
    } else if (filter == 'recent') {
      // 最近30天由前端过滤
      await ref.read(recordListProvider.notifier).search(query: _searchQuery);
    } else {
      await ref.read(recordListProvider.notifier).search(
            query: _searchQuery,
            mood: filter,
          );
    }
  }

  List<DatingRecord> _filterRecords(List<DatingRecord> records) {
    if (_selectedFilter == 'all') return records;
    if (_selectedFilter == 'recent') {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      return records.where((r) => r.recordDate.isAfter(thirtyDaysAgo)).toList();
    }
    return records.where((r) => r.mood == _selectedFilter).toList();
  }

  String _formatDate(DateTime date) {
    const months = [
      '1月', '2月', '3月', '4月', '5月', '6月',
      '7月', '8月', '9月', '10月', '11月', '12月'
    ];
    return '${months[date.month - 1]}${date.day}日';
  }

  Map<String, int> _getCounts(List<DatingRecord> records) {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return {
      'all': records.length,
      'recent': records.where((r) => r.recordDate.isAfter(thirtyDaysAgo)).length,
      'amazing': records.where((r) => r.mood == 'amazing').length,
      'happy': records.where((r) => r.mood == 'happy').length,
      'good': records.where((r) => r.mood == 'good').length,
      'okay': records.where((r) => r.mood == 'okay').length,
      'meh': records.where((r) => r.mood == 'meh').length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(recordListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('约会记录'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: _RecordSearchDelegate(
                  onSearch: _onSearch,
                  records: recordsAsync.value ?? [],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          _buildSearchBar(),
          // 筛选 chips
          _buildFilterChips(recordsAsync.value ?? []),
          // 记录列表
          Expanded(
            child: recordsAsync.when(
              data: (records) {
                final filtered = _filterRecords(records);
                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }
                return RefreshIndicator(
                  onRefresh: _loadRecords,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _RecordCard(
                        record: filtered[index],
                        onTap: () => context.go('/records/${filtered[index].id}'),
                        formatDate: _formatDate,
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (_, __) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('加载失败，请稍后重试'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadRecords,
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/records/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索记录标题、地点、描述...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearch('');
                  },
                )
              : null,
        ),
        onChanged: (value) {
          // 防抖搜索
          Future.delayed(const Duration(milliseconds: 500), () {
            if (_searchController.text == value) {
              _onSearch(value);
            }
          });
        },
      ),
    );
  }

  Widget _buildFilterChips(List<DatingRecord> records) {
    final counts = _getCounts(records);
    final filters = [
      {'key': 'all', 'label': '全部', 'icon': null},
      {'key': 'recent', 'label': '最近', 'icon': Icons.schedule},
      {'key': 'amazing', 'label': '', 'icon': null, 'emoji': '🥰'},
      {'key': 'happy', 'label': '', 'icon': null, 'emoji': '😊'},
      {'key': 'good', 'label': '', 'icon': null, 'emoji': '😌'},
      {'key': 'okay', 'label': '', 'icon': null, 'emoji': '😐'},
      {'key': 'meh', 'label': '', 'icon': null, 'emoji': '😕'},
    ];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final key = filter['key'] as String;
          final label = filter['label'] as String;
          final icon = filter['icon'] as IconData?;
          final emoji = filter['emoji'] as String?;
          final count = counts[key] ?? 0;
          final isSelected = _selectedFilter == key;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (emoji != null) Text(emoji) else if (icon != null) Icon(icon, size: 16),
                  if (label.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(label),
                  ],
                  const SizedBox(width: 4),
                  Text('($count)'),
                ],
              ),
              selected: isSelected,
              onSelected: (_) => _onFilterChanged(key),
              selectedColor: AppTheme.lovePink.withOpacity(0.2),
              checkmarkColor: AppTheme.lovePink,
              backgroundColor: Colors.grey.shade100,
              side: BorderSide(
                color: isSelected ? AppTheme.lovePink : Colors.transparent,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _selectedFilter != 'all'
                ? '没有找到匹配的记录'
                : '还没有约会记录',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedFilter != 'all'
                ? '试试调整搜索条件或过滤选项'
                : '添加你们的第一个约会记录，开始记录美好时光',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          if (_searchQuery.isEmpty && _selectedFilter == 'all') ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/records/new'),
              icon: const Icon(Icons.add),
              label: const Text('添加记录'),
            ),
          ],
        ],
      ),
    );
  }
}

/// 记录卡片
class _RecordCard extends StatelessWidget {
  final DatingRecord record;
  final VoidCallback onTap;
  final String Function(DateTime) formatDate;

  const _RecordCard({
    required this.record,
    required this.onTap,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final moodOption = MoodOptions.options[record.mood];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左侧心情图标
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Center(
                  child: Text(
                    moodOption?.emoji ?? '💕',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 主要内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            record.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        MoodDisplay(mood: record.mood, showLabel: false),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formatDate(record.recordDate),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        if (record.location != null) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              record.location!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (record.description != null && record.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        record.description!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (record.emotionTags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      EmotionTagsDisplay(
                        tags: record.emotionTags,
                        maxDisplay: 3,
                      ),
                    ],
                    if (record.photos.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.photo_library,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${record.photos.length} 张照片',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // 右侧箭头
              const Icon(
                Icons.chevron_right,
                color: AppTheme.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 搜索委托
class _RecordSearchDelegate extends SearchDelegate<String> {
  final Function(String) onSearch;
  final List<DatingRecord> records;

  _RecordSearchDelegate({
    required this.onSearch,
    required this.records,
  });

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          onSearch('');
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return const Center(
        child: Text('输入关键词搜索记录'),
      );
    }

    final filtered = records.where((record) {
      final searchLower = query.toLowerCase();
      return record.title.toLowerCase().contains(searchLower) ||
          (record.location?.toLowerCase().contains(searchLower) ?? false) ||
          (record.description?.toLowerCase().contains(searchLower) ?? false);
    }).toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Text('没有找到匹配的记录'),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final record = filtered[index];
        return ListTile(
          title: Text(record.title),
          subtitle: Text(record.location ?? '无地点'),
          trailing: MoodDisplay(mood: record.mood, showLabel: false),
          onTap: () {
            onSearch(query);
            close(context, query);
          },
        );
      },
    );
  }
}
