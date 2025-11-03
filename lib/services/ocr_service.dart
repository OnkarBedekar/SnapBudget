import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<Map<String, dynamic>> extractReceiptData(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      String fullText = recognizedText.text;
      
      // Extract amount
      double? amount = _extractAmount(fullText);
      
      // Extract date
      DateTime? date = _extractDate(fullText);

      return {
        'amount': amount,
        'date': date,
        'fullText': fullText,
      };
    } catch (e) {
      print('OCR Error: $e');
      return {
        'amount': null,
        'date': null,
        'fullText': '',
      };
    }
  }

  double? _extractAmount(String text) {
    // Pattern to match currency amounts
    // Matches: $12.34, 12.34, $12, 12, etc.
    final patterns = [
      RegExp(r'\$?\s*(\d{1,5}[,.]?\d{0,2})\s*(?:total|amount|sum|subtotal|grand total)', caseSensitive: false),
      RegExp(r'(?:total|amount|sum|subtotal|grand total)\s*:?\s*\$?\s*(\d{1,5}[,.]?\d{0,2})', caseSensitive: false),
      RegExp(r'\$\s*(\d{1,5}[,.]\d{2})'),
      RegExp(r'\b(\d{1,4}\.\d{2})\b'),
    ];

    List<double> foundAmounts = [];

    for (var pattern in patterns) {
      final matches = pattern.allMatches(text);
      for (var match in matches) {
        String? amountStr = match.group(1);
        if (amountStr != null) {
          // Remove commas and parse
          amountStr = amountStr.replaceAll(',', '');
          double? amount = double.tryParse(amountStr);
          if (amount != null && amount > 0 && amount < 10000) {
            foundAmounts.add(amount);
          }
        }
      }
    }

    // Return the largest amount found (usually the total)
    if (foundAmounts.isNotEmpty) {
      foundAmounts.sort((a, b) => b.compareTo(a));
      return foundAmounts.first;
    }

    return null;
  }

  DateTime? _extractDate(String text) {
    // Common date patterns
    final patterns = [
      // MM/DD/YYYY or MM-DD-YYYY
      RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})'),
      // DD/MM/YYYY
      RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})'),
      // Month DD, YYYY
      RegExp(r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+(\d{1,2}),?\s+(\d{4})', caseSensitive: false),
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          if (match.groupCount == 3) {
            if (match.group(1)!.contains(RegExp(r'[A-Za-z]'))) {
              // Month name format
              int month = _monthNameToNumber(match.group(1)!);
              int day = int.parse(match.group(2)!);
              int year = int.parse(match.group(3)!);
              return DateTime(year, month, day);
            } else {
              // Numeric format
              int month = int.parse(match.group(1)!);
              int day = int.parse(match.group(2)!);
              int year = int.parse(match.group(3)!);
              
              // Handle 2-digit years
              if (year < 100) {
                year += 2000;
              }
              
              // Validate date
              if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
                return DateTime(year, month, day);
              }
            }
          }
        } catch (e) {
          continue;
        }
      }
    }

    return null;
  }

  int _monthNameToNumber(String monthName) {
    const months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };
    return months[monthName.toLowerCase().substring(0, 3)] ?? 1;
  }

  void dispose() {
    _textRecognizer.close();
  }
}