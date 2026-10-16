import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_umkm/features/checkout/domain/entities/digital_receipt.dart';
import 'package:pos_umkm/features/checkout/domain/usecases/process_checkout_usecase.dart';
import 'package:pos_umkm/features/pos/domain/entities/cart_item.dart';

// Events
abstract class CheckoutEvent extends Equatable {
  const CheckoutEvent();

  @override
  List<Object?> get props => [];
}

class ProcessCashPaymentEvent extends CheckoutEvent {
  final List<CartItem> cartItems;
  final int subtotal;
  final int discountAmount;
  final int totalAmount;
  final int cashTendered;
  final String cashierName;
  final String deviceName;

  const ProcessCashPaymentEvent({
    required this.cartItems,
    required this.subtotal,
    required this.discountAmount,
    required this.totalAmount,
    required this.cashTendered,
    this.cashierName = 'Kasir 1',
    this.deviceName = 'HP-KASIR-1',
  });

  @override
  List<Object?> get props => [
        cartItems,
        subtotal,
        discountAmount,
        totalAmount,
        cashTendered,
        cashierName,
        deviceName,
      ];
}

class ProcessQrisPaymentEvent extends CheckoutEvent {
  final List<CartItem> cartItems;
  final int subtotal;
  final int discountAmount;
  final int totalAmount;
  final String? qrisReferenceNo;
  final String? qrisScannedTimestamp;
  final String? qrisProofImagePath;
  final String cashierName;
  final String deviceName;

  const ProcessQrisPaymentEvent({
    required this.cartItems,
    required this.subtotal,
    required this.discountAmount,
    required this.totalAmount,
    this.qrisReferenceNo,
    this.qrisScannedTimestamp,
    this.qrisProofImagePath,
    this.cashierName = 'Kasir 1',
    this.deviceName = 'HP-KASIR-1',
  });

  @override
  List<Object?> get props => [
        cartItems,
        subtotal,
        discountAmount,
        totalAmount,
        qrisReferenceNo,
        qrisScannedTimestamp,
        qrisProofImagePath,
        cashierName,
        deviceName,
      ];
}

class ResetCheckoutEvent extends CheckoutEvent {
  const ResetCheckoutEvent();
}

// States
abstract class CheckoutState extends Equatable {
  const CheckoutState();

  @override
  List<Object?> get props => [];
}

class CheckoutInitial extends CheckoutState {
  const CheckoutInitial();
}

class CheckoutProcessing extends CheckoutState {
  const CheckoutProcessing();
}

class CheckoutSuccess extends CheckoutState {
  final DigitalReceipt receipt;
  const CheckoutSuccess(this.receipt);

  @override
  List<Object?> get props => [receipt];
}

class CheckoutError extends CheckoutState {
  final String message;
  const CheckoutError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  final ProcessCheckoutUseCase processCheckoutUseCase;

  CheckoutBloc({required this.processCheckoutUseCase})
      : super(const CheckoutInitial()) {
    on<ProcessCashPaymentEvent>(_onProcessCashPayment);
    on<ProcessQrisPaymentEvent>(_onProcessQrisPayment);
    on<ResetCheckoutEvent>(_onResetCheckout);
  }

  Future<void> _onProcessCashPayment(
    ProcessCashPaymentEvent event,
    Emitter<CheckoutState> emit,
  ) async {
    if (event.cashTendered < event.totalAmount) {
      final shortfall = event.totalAmount - event.cashTendered;
      emit(CheckoutError('Nominal pembayaran kurang Rp $shortfall. Masukkan jumlah uang yang sesuai.'));
      return;
    }

    final changeDue = event.cashTendered - event.totalAmount;
    emit(const CheckoutProcessing());

    try {
      final receipt = await processCheckoutUseCase.execute(
        cartItems: event.cartItems,
        subtotal: event.subtotal,
        discountAmount: event.discountAmount,
        totalAmount: event.totalAmount,
        paymentMethod: 'CASH',
        cashTendered: event.cashTendered,
        changeDue: changeDue,
        cashierName: event.cashierName,
        deviceName: event.deviceName,
      );
      emit(CheckoutSuccess(receipt));
    } catch (e) {
      emit(CheckoutError(e.toString()));
    }
  }

  Future<void> _onProcessQrisPayment(
    ProcessQrisPaymentEvent event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(const CheckoutProcessing());

    try {
      final receipt = await processCheckoutUseCase.execute(
        cartItems: event.cartItems,
        subtotal: event.subtotal,
        discountAmount: event.discountAmount,
        totalAmount: event.totalAmount,
        paymentMethod: 'QRIS',
        cashTendered: event.totalAmount,
        changeDue: 0,
        qrisReferenceNo: event.qrisReferenceNo,
        qrisScannedTimestamp: event.qrisScannedTimestamp,
        qrisProofImagePath: event.qrisProofImagePath,
        cashierName: event.cashierName,
        deviceName: event.deviceName,
      );
      emit(CheckoutSuccess(receipt));
    } catch (e) {
      emit(CheckoutError(e.toString()));
    }
  }

  void _onResetCheckout(ResetCheckoutEvent event, Emitter<CheckoutState> emit) {
    emit(const CheckoutInitial());
  }
}
