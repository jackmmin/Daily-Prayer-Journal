// lib/presentation/screens/prayer_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../core/utils/emoji_length_formatter.dart';
import '../../core/utils/toast_utils.dart';
import '../../domain/entities/bank_plan.dart';
import '../../domain/entities/prayer_record.dart';
import '../viewmodels/prayer_form_viewmodel.dart';
import '../widgets/prayer_form/bank_plan_banner.dart';
import '../widgets/prayer_form/time_section.dart';

class PrayerFormScreen extends ConsumerStatefulWidget {
  final PrayerRecord? editingRecord;
  // 기도통장 계획에서 진입한 경우 해당 계획
  final BankPlan? bankPlan;
  // 일지 목록에서 선택된 날짜 (새 기록 작성 시 기본 시작시간의 날짜로 사용)
  final DateTime? initialDate;

  const PrayerFormScreen({super.key, this.editingRecord, this.bankPlan, this.initialDate});

  @override
  ConsumerState<PrayerFormScreen> createState() => _PrayerFormScreenState();
}

class _PrayerFormScreenState extends ConsumerState<PrayerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _titleFocusNode = FocusNode();
  // skipTraversal: true — textInputAction.next 자동 traversal로 이 필드에 도달하지 못하게 차단
  // onFieldSubmitted에서 명시적으로 이동시킴
  final _contentFocusNode = FocusNode(skipTraversal: true);

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
      if (record.endTime != null) _manualTimeEdited = true;
    } else {
      final now = DateTime.now();
      final base = widget.initialDate;
      // 선택된 날짜가 있으면 해당 날짜 + 현재 시각, 없으면 현재 시각
      _startTime = base != null
          ? DateTime(base.year, base.month, base.day, now.hour, now.minute)
          : now;
      // 직접입력 필수값이므로 기본 종료시간은 시작시간+1분
      _endTime = _startTime.add(const Duration(minutes: 1));
      _manualTimeEdited = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vmProvider = prayerFormViewModelProvider(widget.editingRecord);
    final state = ref.watch(vmProvider);
    final vm = ref.read(vmProvider.notifier);

    // 저장 완료 시 토스트 표시 후 화면 닫기
    ref.listen(vmProvider, (previous, next) {
      if (!context.mounted) return;
      if (!previous!.isSaved && next.isSaved) {
        showInfoToast(context, '저장되었습니다.');
        Navigator.of(context).pop();
      }
      if (next.errorMessage != null) {
        showErrorToast(context, next.errorMessage!);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editingRecord == null ? '기도 기록 추가' : '기도 기록 수정'),
        actions: [
          TextButton(
            onPressed: (state.isSaving || state.isSaved)
                ? null
                : () {
                    FocusScope.of(context).unfocus();
                    _save(vm);
                  },
            child: state.isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    '저장',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: GestureDetector(
        // input 영역 외 터치 시 키보드 숨기기 (opaque: 빈 영역 터치도 감지)
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.bankPlan != null) ...[
                  BankPlanBanner(plan: widget.bankPlan!),
                  const Gap(16),
                ],
                _buildTitleField(),
                const Gap(16),
                _buildContentField(),
                const Gap(20),
                PrayerTimeSection(
                  editingRecord: widget.editingRecord,
                  state: state,
                  vm: vm,
                  startTime: _startTime,
                  endTime: _endTime,
                  useTimer: _useTimer,
                  manualTimeEdited: _manualTimeEdited,
                  onStartTimeChanged: (t) => setState(() {
                    _startTime = t;
                    _manualTimeEdited = true;
                  }),
                  onEndTimeChanged: (t) => setState(() {
                    _endTime = t;
                    _manualTimeEdited = true;
                  }),
                  onUseTimerChanged: (v) => setState(() => _useTimer = v),
                ),
                const Gap(80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _titleController,
      builder: (context, value, _) {
        final count = value.text.characters.length;
        return TextFormField(
          controller: _titleController,
          focusNode: _titleFocusNode,
          decoration: InputDecoration(
            labelText: '기도 제목 * (최대 20자)',
            prefixIcon: const Icon(Icons.title),
            hintText: '기도 제목을 입력하세요',
            counterText: '',
            suffixText: '$count/20',
            suffixStyle: TextStyle(
              fontSize: 12,
              color: count > 20 ? Colors.red : Colors.grey,
            ),
          ),
          // maxLength 미사용: EmojiLengthFormatter가 grapheme 단위로 제한
          inputFormatters: const [EmojiLengthFormatter(20)],
          textInputAction: TextInputAction.next,
          // onFieldSubmitted로 명시 제어 — 자동 포커스 이동 방지
          onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_contentFocusNode),
          validator: (v) => (v == null || v.trim().isEmpty) ? '기도 제목을 입력해주세요' : null,
        );
      },
    );
  }

  Widget _buildContentField() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _contentController,
      builder: (context, value, _) {
        final count = value.text.characters.length;
        return TextFormField(
          controller: _contentController,
          focusNode: _contentFocusNode,
          decoration: InputDecoration(
            labelText: '기도 내용',
            prefixIcon: const Icon(Icons.edit_note),
            hintText: '기도 내용을 입력하세요',
            alignLabelWithHint: true,
            counterText: '',
            // 1000자 초과 시 빨간색으로 카운터 표시
            suffixText: '$count/1000',
            suffixStyle: TextStyle(
              fontSize: 12,
              color: count > 1000 ? Colors.red : Colors.grey,
            ),
          ),
          maxLines: 6,
          // maxLength 미사용: EmojiLengthFormatter가 grapheme 단위로 제한
          inputFormatters: const [EmojiLengthFormatter(1000)],
          textInputAction: TextInputAction.newline,
        );
      },
    );
  }

  void _save(PrayerFormViewModel vm) {
    if (_formKey.currentState?.validate() != true) return;

    // 타이머 탭 선택 시 기록된 시간이 없으면 저장 불가
    final state = ref.read(prayerFormViewModelProvider(widget.editingRecord));
    if (_useTimer && !state.isTimerStopped) {
      showInfoToast(context, '타이머 기록이 없습니다.');
      return;
    }

    // 미래 시간으로 저장 불가 검증
    final now = DateTime.now();
    if (_startTime.isAfter(now)) {
      showErrorToast(context, '시작 시간이 현재 시각보다 미래일 수 없습니다.');
      return;
    }
    if (_endTime != null && _endTime!.isAfter(now)) {
      showErrorToast(context, '종료 시간이 현재 시각보다 미래일 수 없습니다.');
      return;
    }

    vm.saveRecord(
      title: _titleController.text,
      content: _contentController.text,
      startTime: _startTime,
      endTime: _endTime,
      bankPlanId: widget.bankPlan?.id,
    );
  }
}
