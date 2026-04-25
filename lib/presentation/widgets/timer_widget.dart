// lib/presentation/widgets/timer_widget.dart

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../viewmodels/prayer_form_viewmodel.dart';

class TimerWidget extends StatelessWidget {
  final PrayerFormState state;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onReset;

  const TimerWidget({
    super.key,
    required this.state,
    required this.onStart,
    required this.onStop,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                _formatDuration(state.elapsedDuration),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
              ),
              if (state.timerStartTime != null) ...[
                const Gap(4),
                Text(
                  _getStatusText(),
                  style: TextStyle(
                    color: colorScheme.primary.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
        const Gap(16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (state.timerStatus == TimerStatus.idle) ...[
              _buildTimerButton(
                context: context,
                onPressed: onStart,
                icon: Icons.play_arrow_rounded,
                label: '시작',
                color: Colors.green,
              ),
            ] else if (state.timerStatus == TimerStatus.running) ...[
              _buildTimerButton(
                context: context,
                onPressed: onStop,
                icon: Icons.stop_rounded,
                label: '종료',
                color: Colors.orange,
              ),
            ] else ...[
              _buildTimerButton(
                context: context,
                onPressed: onReset,
                icon: Icons.refresh_rounded,
                label: '초기화',
                color: Colors.grey,
              ),
            ],
          ],
        ),
        if (state.isTimerStopped) ...[
          const Gap(8),
          Text(
            '기도 시간이 기록되었습니다. 저장 버튼을 눌러주세요.',
            style: TextStyle(
              color: Colors.green.shade700,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildTimerButton({
    required BuildContext context,
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String _getStatusText() {
    if (state.isTimerRunning) return '기도 중...';
    if (state.isTimerStopped) {
      final dur = state.elapsedDuration;
      final m = dur.inMinutes;
      final s = dur.inSeconds.remainder(60);
      return m > 0 ? '$m분 $s초 기도했습니다' : '$s초 기도했습니다';
    }
    return '';
  }
}
