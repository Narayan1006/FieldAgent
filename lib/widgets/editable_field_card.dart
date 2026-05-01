import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EditableFieldCard extends StatefulWidget {
  final String label;
  final String value;
  final String hint;
  final TextInputType keyboardType;
  final Function(String) onChanged;
  final int index;

  const EditableFieldCard({
    super.key,
    required this.label,
    required this.value,
    this.hint = '',
    this.keyboardType = TextInputType.text,
    required this.onChanged,
    this.index = 0,
  });

  @override
  State<EditableFieldCard> createState() => _EditableFieldCardState();
}

class _EditableFieldCardState extends State<EditableFieldCard> {
  bool _isEditing = false;
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        _save();
      }
    });
  }

  @override
  void didUpdateWidget(EditableFieldCard old) {
    super.didUpdateWidget(old);
    if (!_isEditing && old.value != widget.value) {
      _controller.text = widget.value;
    }
  }

  void _startEdit() {
    setState(() => _isEditing = true);
    _focusNode.requestFocus();
  }

  void _save() {
    setState(() => _isEditing = false);
    widget.onChanged(_controller.text.trim());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: _isEditing ? AppColors.primaryLight.withOpacity(0.08) : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: _isEditing ? AppColors.primary : AppColors.divider,
          width: _isEditing ? 2 : 1,
        ),
        boxShadow: _isEditing
            ? [BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 8)]
            : [const BoxShadow(color: Colors.black12, blurRadius: 2)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: _isEditing ? null : _startEdit,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _isEditing
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _isEditing
                          ? TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              keyboardType: widget.keyboardType,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                hintText: widget.hint,
                              ),
                              onSubmitted: (_) => _save(),
                            )
                          : Text(
                              _controller.text.isEmpty ? widget.hint : _controller.text,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: _controller.text.isEmpty
                                    ? AppColors.textHint
                                    : AppColors.textPrimary,
                              ),
                            ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _isEditing
                    ? GestureDetector(
                        onTap: _save,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 18),
                        ),
                      )
                    : const Icon(Icons.edit_outlined,
                        size: 20, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
