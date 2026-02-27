import 'package:flutter/material.dart';
import '../../../services/nlp_service.dart';

class NlpInputField extends StatefulWidget {
  final Function(NlpParseResult) onSubmit;
  final String? hintText;
  final bool autofocus;

  const NlpInputField({
    super.key,
    required this.onSubmit,
    this.hintText,
    this.autofocus = false,
  });

  @override
  State<NlpInputField> createState() => _NlpInputFieldState();
}

class _NlpInputFieldState extends State<NlpInputField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _nlpService = NlpServiceImpl();
  
  NlpParseResult? _preview;
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    if (widget.autofocus) {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text;
    if (text.isEmpty) {
      setState(() {
        _preview = null;
        _showPreview = false;
      });
      return;
    }

    // 实时解析预览
    final result = _nlpService.parse(text);
    setState(() {
      _preview = result;
      _showPreview = result.title.isNotEmpty;
    });
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final result = _nlpService.parse(text);
    widget.onSubmit(result);
    
    _controller.clear();
    setState(() {
      _preview = null;
      _showPreview = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 预览卡片
        if (_showPreview && _preview != null)
          _buildPreviewCard(),
        
        const SizedBox(height: 8),
        
        // 输入框
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focusNode.hasFocus
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).dividerColor,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(
                Icons.add_task,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: widget.hintText ?? '添加任务，试试：明天下午三点开会 P1',
                    hintStyle: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  maxLines: 3,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submit(),
                ),
              ),
              if (_controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    setState(() {
                      _preview = null;
                      _showPreview = false;
                    });
                  },
                ),
              IconButton(
                icon: const Icon(Icons.send),
                color: Theme.of(context).colorScheme.primary,
                onPressed: _submit,
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewCard() {
    final result = _preview!;
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.primary.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.smart_toy,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  '智能解析',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // 标题预览
            Text(
              result.title.isEmpty ? '（无标题）' : result.title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            
            // 解析详情
            if (result.priority != TaskPriority.none || 
                result.dueDate != null || 
                result.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (result.priority != TaskPriority.none)
                    _buildPreviewChip(
                      AppTheme.getPriorityName(result.priority),
                      AppTheme.getPriorityColor(result.priority),
                    ),
                  if (result.dueDate != null)
                    _buildPreviewChip(
                      _formatDate(result.dueDate!),
                      result.dueDate!.isBefore(DateTime.now())
                          ? Colors.red
                          : Colors.blue,
                    ),
                  if (result.tags.isNotEmpty)
                    ...result.tags.map((tag) => _buildPreviewChip(
                      '#$tag',
                      Colors.grey,
                    )),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
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
    } else {
      return '${date.month}/${date.day}';
    }
  }

  // 底部导航
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.today, '今天', 0),
              _buildNavItem(Icons.check_circle_outline, '待办', 1),
              _buildNavItem(Icons.calendar_today, '日历', 2),
              _buildNavItem(Icons.settings_outlined, '设置', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    final color = isSelected 
        ? Theme.of(context).colorScheme.primary 
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6);

    return GestureDetector(
      onTap: () {
        _tabController.animateTo(index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () => _showAddTaskDialog(context),
      icon: const Icon(Icons.add),
      label: const Text('任务'),
      elevation: 4,
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    // 实现添加任务对话框
  }

  void _onTaskTap(BuildContext context, Task task) {}
  void _onTaskComplete(BuildContext context, Task task, bool completed) {}
  void _onTaskDelete(BuildContext context, Task task) {}
  void _showPriorityFilter(BuildContext context) {}
  void _showProjectFilter(BuildContext context) {}
  void _showTagFilter(BuildContext context) {}
}