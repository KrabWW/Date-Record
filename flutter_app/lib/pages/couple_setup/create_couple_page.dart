import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/couple_provider.dart';
import '../../models/couple.dart';

/// 创建情侣空间页面
class CreateCouplePage extends ConsumerStatefulWidget {
  const CreateCouplePage({super.key});

  @override
  ConsumerState<CreateCouplePage> createState() => _CreateCouplePageState();
}

class _CreateCouplePageState extends ConsumerState<CreateCouplePage> {
  final _formKey = GlobalKey<FormState>();
  final _coupleNameController = TextEditingController();

  DateTime? _anniversaryDate;
  bool _isLoading = false;
  String? _errorMessage;
  Couple? _createdCouple;
  bool _copied = false;

  @override
  void dispose() {
    _coupleNameController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final couple = await ref.read(currentCoupleProvider.notifier).createCouple(
        coupleName: _coupleNameController.text.trim(),
        anniversaryDate: _anniversaryDate,
      );

      if (mounted) {
        setState(() {
          _createdCouple = couple;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _copyInviteCode() async {
    if (_createdCouple?.inviteCode == null) return;

    await Clipboard.setData(
      ClipboardData(text: _createdCouple!.inviteCode),
    );

    setState(() {
      _copied = true;
    });

    // 2秒后重置
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copied = false;
        });
      }
    });
  }

  Future<void> _goToHome() async {
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('创建情侣空间'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _createdCouple == null
                  ? _buildCreateForm()
                  : _buildSuccessView(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 标题说明
          _buildHeader(),

          const SizedBox(height: 32),

          // 情侣空间名称
          TextFormField(
            key: const Key('create_couple_name'),
            controller: _coupleNameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: '情侣空间名称',
              hintText: '例如：小明 & 小红的爱情空间',
              prefixIcon: Icon(Icons.favorite_border),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入情侣空间名称';
              }
              if (value.length < 2) {
                return '名称至少需要2个字符';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // 纪念日选择
          InkWell(
            onTap: _pickAnniversaryDate,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: _anniversaryDate != null
                      ? AppTheme.lovePink
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    color: _anniversaryDate != null
                        ? AppTheme.lovePink
                        : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _anniversaryDate == null
                          ? '纪念日（可选）'
                          : _formatDate(_anniversaryDate!),
                      style: TextStyle(
                        color: _anniversaryDate != null
                            ? AppTheme.textPrimary
                            : AppTheme.textHint,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (_anniversaryDate != null)
                    InkWell(
                      onTap: () {
                        setState(() {
                          _anniversaryDate = null;
                        });
                      },
                      child: Icon(
                        Icons.clear,
                        size: 20,
                        color: AppTheme.textSecondary,
                      ),
                    )
                  else
                    Icon(
                      Icons.arrow_drop_down,
                      color: AppTheme.textSecondary,
                    ),
                ],
              ),
            ),
          ),

          if (_anniversaryDate == null)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8),
              child: Text(
                '设置你们的纪念日，比如初次约会或确定关系的日期',
                style: TextStyle(
                  color: AppTheme.textHint,
                  fontSize: 12,
                ),
              ),
            ),

          const SizedBox(height: 24),

          // 错误提示
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: AppTheme.error.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppTheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: AppTheme.error,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 创建按钮
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleCreate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lovePink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      '创建空间',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.shadowSmall,
          ),
          child: const Icon(
            Icons.favorite,
            size: 36,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '为你们的爱情故事命名',
          style: TextStyle(
            fontSize: 18,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      children: [
        // 成功图标
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.success.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle,
            size: 48,
            color: AppTheme.success,
          ),
        ),

        const SizedBox(height: 24),

        Text(
          '创建成功！',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          _createdCouple?.coupleName ?? '',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondary,
          ),
        ),

        const SizedBox(height: 32),

        // 邀请码卡片
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.lovePink.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: AppTheme.lovePink.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Text(
                '邀请码',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _createdCouple?.inviteCode ?? '',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: AppTheme.lovePink,
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _copyInviteCode,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.lovePink,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _copied ? Icons.check : Icons.copy,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _copied ? '已复制' : '复制邀请码',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 说明文字
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppTheme.info,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '请将邀请码发送给您的伴侣，他们可以使用邀请码加入这个空间',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // 进入首页按钮
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _goToHome,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lovePink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
            child: const Text(
              '进入首页',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickAnniversaryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _anniversaryDate ?? now,
      firstDate: DateTime(now.year - 50),
      lastDate: DateTime(now.year + 10),
      locale: const Locale('zh', 'CN'),
      helpText: '选择纪念日',
      confirmText: '确定',
      cancelText: '取消',
      fieldLabelText: '纪念日',
      fieldHintText: '年/月/日',
    );

    if (picked != null) {
      setState(() {
        _anniversaryDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }
}
