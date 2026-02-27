import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/nlp_service.dart';

/// NlpInputField - 智能 NLP 输入组件
/// 
/// 设计特点：
/// - 圆角输入框设计
/// - 实时解析预览
/// - 流畅的动画过渡
/// - 触觉反馈
class NlpInputField extends StatefulWidget {
  final Function(NlpParseResult) onSubmit;
  final String? hintText;
  final bool autofocus;
  final VoidCallback? onClose;

  const NlpInputField({
    super.key,
    required this.onSubmit,
    this.hintText,
    this.autofocus = false,
    this.onClose,
  });

  @override
  State<NlpInputField> createState() => _NlpInputFieldState();
}

class _NlpInputFieldState extends State<NlpInputField>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _nlpService = NlpServiceImpl();

  NlpParseResult? _preview;
  bool _showPreview = false;
  bool _isFocused = false;
  bool _isComposing = false;

  late AnimationController _previewController;
  late AnimationController _focusController;
  late Animation<double> _previewAnimation;
  late Animation<double> _focusAnimation;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);

    if (widget.autofocus) {
      _focusNode.requestFocus();
    }

    // 预览动画控制器
    _previewController = AnimationController(
      duration: AppTheme.animationNormal,
      vsync: this,
    );

    // 聚焦动画控制器
    _focusController = AnimationController(
      duration: AppTheme.animationFast,
      vsync: this,
    );

    _previewAnimation = CurvedAnimation(
      parent: _previewController,
      curve: AppTheme.animationCurve,
    );

    _focusAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _focusController,
      curve: AppTheme.animationCurve,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _previewController.dispose();
    _focusController.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    if (_isFocused) {
      _focusController.forward();
    } else {
      _focusController.reverse();
    }
  }

  void _onTextChanged() {
    final text = _controller.text;
    if (text.isEmpty) {
      setState(() {
        _preview = null;
        _showPreview = false;
      });
      _previewController.reverse();
      return;
    }

    // 实时解析预览
    final result = _nlpService.parse(text);
    final showPreview = result.title.isNotEmpty;

    if (showPreview != _showPreview) {
      setState(() {
        _preview = result;
        _showPreview = showPreview;
      });
      if (showPreview) {
        _previewController.forward();
      } else {
        _previewController.reverse();
      }
    } else {
      setState(() {
        _preview = result;
      });
    }
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.mediumImpact();

    final result = _nlpService.parse(text);
    widget.onSubmit(result);

    _controller.clear();
    setState(() {
      _preview = null;
      _showPreview = false;
    });
    _previewController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 预览卡片
        AnimatedBuilder(
          animation: _previewAnimation,
          builder: (context, child) {
            return SizeTransition(
              sizeFactor: _previewAnimation,
              child: FadeTransition(
                opacity: _previewAnimation,
                child: child,
              ),
            );
          },
          child: _showPreview && _preview != null
              ? _buildPreviewCard(theme)
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: 8),

        // 输入框
        AnimatedBuilder(
          animation: _focusAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(
                  color: Color.lerp(
                    theme.dividerColor,
                    AppTheme.primaryColor.withOpacity(0.5),
                    _focusAnimation.value,
                  )!,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.1 * _focusAnimation.value),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Row(
            children: [
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.add_task,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: widget.hintText ?? '添加任务，试试：明天下午三点开会 P1',
                    hintStyle: TextStyle(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  maxLines: 3,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submit(),
                ),
              ),
              // 快捷操作按钮
              if (_controller.text.isNotEmpty)
                IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: theme.textTheme.bodySmall?.color,
                    size: 18,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _controller.clear();
                    setState(() {
                      _preview = null;
                      _showPreview = false;
                    });
                    _previewController.reverse();
                  },
                ),
              // 发送按钮
              GestureDetector(
                onTap: _submit,
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_upward,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewCard(ThemeData theme) {
    final result = _preview!;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 智能解析头部
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '智能解析',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '按回车发送',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.primaryColor.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),

            // 内容预览
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          result.title.isEmpty ? '（无标题）' : result.title,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: result.title.isEmpty 
                                ? theme.textTheme.bodySmall?.color 
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 解析详情
                  if (result.priority != TaskPriority.none || 
                      result.dueDate != null || 
                      result.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (result.priority != TaskPriority.none)
                          _buildPreviewTag(
                            AppTheme.getPriorityName(result.priority),
                            AppTheme.getPriorityColor(result.priority),
                            Icons.flag,
                          ),
                        if (result.dueDate != null)
                          _buildPreviewTag(
                            _formatDate(result.dueDate!),
                            result.dueDate!.isBefore(DateTime.now())
                                ? AppTheme.errorColor
                                : AppTheme.infoColor,
                            Icons.event,
                          ),
                        ...result.tags.map((tag) => _buildPreviewTag(
                          '#$tag',
                          AppTheme.primaryColor,
                          Icons.label_outline,
                        )),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewTag(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return '今天';
    } else if (dateOnly == today.add(const Duration(days: 1))) {
      return '明天';
    } else if (dateOnly == today.add(const Duration(days: 2))) {
      return '后天';
    } else if (dateOnly.year == today.year) {
      return '${date.month}月${date.day}日';
    } else {
      return '${date.year}年${date.month}月${date.day}日';
    }
  }
}