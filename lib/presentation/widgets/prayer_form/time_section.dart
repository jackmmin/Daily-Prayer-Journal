// lib/presentation/widgets/prayer_form/time_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../domain/entities/prayer_record.dart';
import '../../viewmodels/prayer_form_viewmodel.dart';
import '../timer_widget.dart';
import '../time_picker_field.dart';

/// 기도 기록 폼의 시간 입력 섹션 (직접입력 / 타이머 전환)
class PrayerTimeSection extends StatefulWidget {
  final PrayerRecord? editingRecord;
  final PrayerFormState state;
  final PrayerFormViewModel vm;
  final DateTime startTime;
  final DateTime? endTime;
  final bool useTimer;
  final bool manualTimeEdited;
  final ValueChanged<DateTime> onStartTimeChanged;
  final ValueChanged<DateTime?> onEndTimeChanged;
  final ValueChanged<bool> onUseTimerChanged;

  const PrayerTimeSection({
    super.key,
    required this.editingRecord,
    required this.state,
    required this.vm,
    required this.startTime,
    required this.endTime,
    required this.useTimer,
    required this.manualTimeEdited,
    required this.onStartTimeChanged,
    required this.onEndTimeChanged,
    required this.onUseTimerChanged,
  });

  @override
  State<PrayerTimeSection> createState() => _PrayerTimeSectionState();
}

class _PrayerTimeSectionState extends State<PrayerTimeSection> {
  void _switchToManual(WidgetRef ref) {
    // 타이머 진행 중이면 탭 전환 시 자동 멈춤
    if (widget.state.isTimerRunning) {
      widget.vm.stopTimer();
    }

    if (widget.useTimer && !widget.manualTimeEdited) {
      final timerState = ref.read(prayerFormViewModelProvider(widget.editingRecord));
      if (timerState.timerStartTime != null) {
        widget.onStartTimeChanged(timerState.timerStartTime!);
        if (timerState.isTimerStopped) {
          widget.onEndTimeChanged(
            timerState.timerStartTime!.add(timerState.elapsedDuration),
          );
        }
        widget.onUseTimerChanged(false);
        return;
      }
    }
    widget.onUseTimerChanged(false);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Icon(Icons.access_time, color: Theme.of(context).colorScheme.primary),
        title: Text(
          '기도 시간',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        trailing: _buildTimeSummary(context),
        // 타이머 진행 중 섹션이 접히면 자동 멈춤
        onExpansionChanged: (expanded) {
          if (!expanded && widget.useTimer && widget.state.isTimerRunning) {
            widget.vm.stopTimer();
          }
        },
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 입력 모드 전환 버튼
              Consumer(
                builder: (context, ref, _) => Row(
                  children: [
                    Expanded(
                      child: _ModeButton(
                        label: '직접 입력',
                        icon: Icons.keyboard,
                        isSelected: !widget.useTimer,
                        onTap: () => _switchToManual(ref),
                      ),
                    ),
                    const Gap(8),
                    Expanded(
                      child: _ModeButton(
                        label: '타이머 사용',
                        icon: Icons.timer_outlined,
                        isSelected: widget.useTimer,
                        onTap: () => widget.onUseTimerChanged(true),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(16),
              if (!widget.useTimer) ...[
                TimePickerField(
                  label: '시작 시간',
                  time: widget.startTime,
                  onChanged: (t) {
                    widget.onStartTimeChanged(t);
                    // 종료 시간이 시작 시간보다 앞서면 시작+1분으로 자동 보정
                    if (widget.endTime != null && !widget.endTime!.isAfter(t)) {
                      widget.onEndTimeChanged(t.add(const Duration(minutes: 1)));
                    }
                  },
                ),
                const Gap(12),
                TimePickerField(
                  label: '종료 시간',
                  time: widget.endTime,
                  onChanged: (t) {
                    if (!t.isAfter(widget.startTime)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('종료 시간은 시작 시간보다 늦어야 합니다'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    widget.onEndTimeChanged(t);
                  },
                ),
              ] else ...[
                TimerWidget(
                  state: widget.state,
                  onStart: widget.vm.startTimer,
                  onStop: widget.vm.stopTimer,
                  onResume: widget.vm.resumeTimer,
                  onReset: widget.vm.resetTimer,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// 접힌 상태에서 기도 시간(분)을 우측에 표시
  Widget? _buildTimeSummary(BuildContext context) {
    Duration? duration;

    if (widget.useTimer && widget.state.isTimerStopped && widget.state.elapsedDuration.inMinutes > 0) {
      duration = widget.state.elapsedDuration;
    } else if (!widget.useTimer && widget.manualTimeEdited && widget.endTime != null) {
      final startMin = DateTime(
        widget.startTime.year, widget.startTime.month, widget.startTime.day,
        widget.startTime.hour, widget.startTime.minute,
      );
      final endMin = DateTime(
        widget.endTime!.year, widget.endTime!.month, widget.endTime!.day,
        widget.endTime!.hour, widget.endTime!.minute,
      );
      final diff = endMin.difference(startMin);
      if (diff.isNegative || diff.inMinutes == 0) return null;
      duration = diff;
    }

    if (duration == null) return null;

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final label = hours > 0 ? '$hours시간 $minutes분' : '$minutes분';

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
}

// ─── 입력 모드 전환 버튼 ──────────────────────────────────────────────────────

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
            Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.grey),
            const Gap(6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
