import 'package:equatable/equatable.dart';

class QrisProofResult extends Equatable {
  final bool isValid;
  final int detectedAmount;
  final String referenceNumber;
  final DateTime? transactionTimestamp;
  final String rawText;
  final String? errorMessage;
  final String? proofImagePath;

  const QrisProofResult({
    required this.isValid,
    required this.detectedAmount,
    required this.referenceNumber,
    this.transactionTimestamp,
    required this.rawText,
    this.errorMessage,
    this.proofImagePath,
  });

  @override
  List<Object?> get props => [
        isValid,
        detectedAmount,
        referenceNumber,
        transactionTimestamp,
        rawText,
        errorMessage,
        proofImagePath,
      ];
}
