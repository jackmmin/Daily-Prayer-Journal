// lib/core/utils/emoji_length_formatter.dart

import 'package:characters/characters.dart';
import 'package:flutter/services.dart';

/// 이모지를 포함한 텍스트를 Unicode grapheme cluster 단위로 길이를 세어 제한하는 formatter.
/// 기본 [LengthLimitingTextInputFormatter]는 UTF-16 code unit 기준으로 세기 때문에
/// 이모지(2 code units)를 2글자로 계산하여 제한 초과 시 이모지 중간에서 잘라 깨짐.
class EmojiLengthFormatter extends TextInputFormatter {
  final int maxLength;

  const EmojiLengthFormatter(this.maxLength);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final chars = newValue.text.characters;
    if (chars.length <= maxLength) return newValue;

    // grapheme cluster 단위로 maxLength까지만 자름
    final truncated = chars.take(maxLength).string;
    return TextEditingValue(
      text: truncated,
      selection: TextSelection.collapsed(offset: truncated.length),
    );
  }
}
