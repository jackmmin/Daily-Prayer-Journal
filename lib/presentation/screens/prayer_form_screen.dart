// lib/presentation/screens/prayer_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../domain/entities/prayer_record.dart';
import '../viewmodels/prayer_form_viewmodel.dart';
import '../widgets/timer_widget.dart';
import '../widgets/time_picker_field.dart';

class PrayerFormScreen extends ConsumerStatefulWidget {
  final PrayerRecord? editingRecord;

  const PrayerFormScreen({super.key, this.editingRecord});

  @override
  ConsumerState<PrayerFormScreen> createState() => _PrayerFormScreenState();
}

class _PrayerFormScreenState extends ConsumerState<PrayerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  late DateTime _startTime;
  DateTime? _endTime;
  bool _useTimer = false;
  bool _manualTimeEdited = false;

  @override
  void initState() {
    super.initState();
    final record = widget.editingRecord;
    if (record != null) {
      _titleController.text = record.title;
      _contentController.text = record.content;
      _startTime = record.startTime;
      _endTime = record.endTime;
    } else {
      _startTime = DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vmProvider = prayerFormViewModelProvider(widget.editingRecord);
    final state = ref.watch(vmProvider);
    final vm = ref.read(vmProvider.notifier);

    // 저장 완료 시 화면 닫기
    ref.listen(vmProvider, (previous, next) {
      if (!previous!.isSaved && next.isSaved) {
        Navigator.of(context).pop();
      }
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editingRecord == null ? '기도 기록 추가' : '기도 기록 수정'),
        actions: [
          TextButton(
            onPressed: state.isSaving ? null : () => _save(vm),
            child: state.isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    '저장',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTitleField(),
              const Gap(16),
              _buildContentField(),
              const Gap(20),
              _buildTimeSection(state, vm),
              const Gap(80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: '기도 제목 *',
        prefixIcon: Icon(Icons.title),
        hintText: '기도 제목을 입력하세요',
      ),
      textInputAction: TextInputAction.next,
      validator: (v) => (v == null || v.trim().isEmpty) ? '기도 제목을 입력해주세요' : null,
    );
  }

  Widget _buildContentField() {
    return TextFormField(
      controller: _contentController,
      decoration: const InputDecoration(
        labelText: '기도 내용',
        prefixIcon: Icon(Icons.edit_note),
        hintText: '기도 내용을 입력하세요',
        alignLabelWithHint: true,
      ),
      maxLines: 6,
      textInputAction: TextInputAction.newline,
    );
  }

  Widget _buildTimeSection(PrayerFormState state, PrayerFormViewModel vm) {
    return Card(
      child: ExpansionTile(
        // 기본값: 접힌 상태
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Icon(
          Icons.access_time,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          '기도 시간',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        trailing: _buildTimeSummary(state),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildModeButton(
                      label: '직접 입력',
                      icon: Icons.keyboard,
                      isSelected: !_useTimer,
                      onTap: () {
                        if (_useTimer && !_manualTimeEdited) {
                          // 직접 입력에서 수동 편집 이력이 없을 때만 타이머 시간을 필드에 반영
                          final timerState = ref.read(prayerFormViewModelProvider(widget.editingRecord));
                          if (timerState.timerStartTime != null) {
                            setState(() {
                              _startTime = timerState.timerStartTime!;
                              if (timerState.isTimerStopped) {
                                _endTime = timerState.timerStartTime!.add(timerState.elapsedDuration);
                              }
                              _useTimer = false;
                            });
                            return;
                          }
                        }
                        setState(() => _useTimer = false);
                      },
                    ),
                  ),
                  const Gap(8),
                  Expanded(
                    child: _buildModeButton(
                      label: '타이머 사용',
                      icon: Icons.timer_outlined,
                      isSelected: _useTimer,
                      onTap: () => setState(() => _useTimer = true),
                    ),
                  ),
                ],
              ),
              const Gap(16),
              if (!_useTimer) ...[
                TimePickerField(
                  label: '시작 시간',
                  time: _startTime,
                  onChanged: (t) => setState(() {
                    _startTime = t;
                    _manualTimeEdited = true;
                  }),
                ),
                const Gap(12),
                TimePickerField(
                  label: '종료 시간 (선택)',
                  time: _endTime,
                  onChanged: (t) => setState(() {
                    _endTime = t;
                    _manualTimeEdited = true;
                  }),
                  onCleared: () => setState(() {
                    _endTime = null;
                    _manualTimeEdited = true;
                  }),
                  nullable: true,
                ),
              ] else ...[
                TimerWidget(
                  state: state,
                  onStart: vm.startTimer,
                  onStop: vm.stopTimer,
                  onResume: vm.resumeTimer,
                  onReset: vm.resetTimer,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // 접힌 상태에서 시작/종료 시간이 모두 있을 때 기도 시간(분)을 우측에 표시
  Widget? _buildTimeSummary(PrayerFormState state) {
    Duration? duration;

    if (_useTimer && state.isTimerStopped && state.elapsedDuration.inSeconds > 0) {
      duration = state.elapsedDuration;
    } else if (!_useTimer && _endTime != null) {
      final diff = _endTime!.difference(_startTime);
      if (diff.isNegative || diff.inSeconds == 0) return null;
      duration = diff;
    }

    if (duration == null) return null;

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    String label;
    if (hours > 0) {
      label = '$hours시간 $minutes분';
    } else if (minutes > 0) {
      label = '$minutes분 $seconds초';
    } else {
      label = '$seconds초';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildModeButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          border: Border.all(color: isSelected ? color : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18, color: isSelected ? Colors.white : Colors.grey),
            const Gap(6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save(PrayerFormViewModel vm) {
    if (_formKey.currentState?.validate() != true) return;
    vm.saveRecord(
      title: _titleController.text,
      content: _contentController.text,
      startTime: _startTime,
      endTime: _endTime,
    );
  }
}
