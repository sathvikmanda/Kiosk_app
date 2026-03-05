import 'dart:convert';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import 'complaint_session.dart';


class ApiService {
  static const String baseUrl = "http://192.168.0.101:4000";
  //static const String baseUrl = "http://127.0.0.1:3000";
  static const String lockerId = "L00002";

  
  static void hitComplaintApi({required String action}) {
    try {
      http.post(
        Uri.parse('$baseUrl/api/complaint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': action,
          'source': 'kiosk-home'
        }),
      );
    } catch (_) {
      // intentionally ignored
    }
  }

  static Future<String?> startComplaintIfNeeded() async {
    final uri = Uri.parse('$baseUrl/api/complaint');

    final res = await http.post(uri);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['helpId'];
    }

    return null;
  }

static Future<void> stopComplaint(String helpId) async {
  try {
    await http.post(
      Uri.parse('$baseUrl/api/complaint/resolve'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'helpId': helpId}),
    );
  } catch (e) {
    print('stopComplaint error: $e');
  }
}



static Future<void> resolveComplaintIfAny() async {
  final helpId = ComplaintSession.helpId;
  if (helpId == null) return;

  await http.post(
    Uri.parse('$baseUrl/api/complaint/resolve'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'helpId': helpId}),
  );

  ComplaintSession.clear();
}



static Future<Map<String, dynamic>> unlock(String accessCode) async {
  final uri = Uri.parse('$baseUrl/api/locker/unlock-code');

  final res = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'accessCode': accessCode}),
  );

  final Map<String, dynamic> data = jsonDecode(res.body);

  if (res.statusCode == 402 && data['paymentRequired'] == true) {
    return data; // usageSummary INCLUDED
  }

  if (res.statusCode != 200 || data['success'] != true) {
    throw Exception(data['message'] ?? 'Unable to unlock locker');
  }

  return data;
}









  static Future<Map<String, bool>> getAvailableSizes(String lockerId) async {
  final uri = Uri.parse('$baseUrl/locker/L00002/available-sizes');
  final res = await http.get(uri);

  // 🔥 LOG EVERYTHING
  print('URL: $uri');
print('STATUS: ${res.statusCode}');
print('BODY: ${res.body}');


  if (res.statusCode != 200) {
    throw Exception('Failed to fetch availability');
  }

  final raw = jsonDecode(res.body) as Map<String, dynamic>;

  bool toBool(dynamic v) {
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true';
    return false;
  }

  return {
    'small': toBool(raw['small']),
    'medium': toBool(raw['medium']),
    'large': toBool(raw['large']),
  };
}




static Future<void> sendParcelLinkWhatsapp({
  required String phoneNumber,
}) async {
  final res = await http.post(
    Uri.parse('$baseUrl/api/whatsapp/send-parcel-link'),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'phone': phoneNumber, // 🔑 send ONLY 10-digit number
    }),
  );

  final data = jsonDecode(res.body);

  if (res.statusCode != 200 || data['success'] != true) {
    throw Exception(
      data['message'] ?? 'Failed to send WhatsApp message',
    );
  }
}



static Future<void> sendOtp({
  required String phone,
}) async {
  final res = await http.post(
    Uri.parse('$baseUrl/api/otp/send'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'phone': phone,
    }),
  );

  if (res.statusCode != 200) {
    throw Exception('Failed to send OTP');
  }
}



static Future<List<Map<String, dynamic>>> findPartners({
  required String phone,
}) async {
  final res = await http.post(
    Uri.parse('$baseUrl/find-partner'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'phone': phone}),
  );

  final data = jsonDecode(res.body);

  if (res.statusCode != 200 || data['success'] != true) {
    throw Exception(data['message'] ?? 'Failed to find partners');
  }

  return List<Map<String, dynamic>>.from(data['partners']);
}






 static Future<void> resendOtpWhatsapp({
    required String phone,
  }) async {
    final url = Uri.parse('$baseUrl/api/otp/resend-whatsapp');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'phone': phone, // 🔥 10-digit only (no +91)
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to resend OTP');
    }
  }
static Future<void> verifyOtp({
  required String phone,
  required String otp,
}) async {
  final uri = Uri.parse('$baseUrl/otp/verify');

  print('🔐 VERIFY OTP REQUEST');
  print('➡️ URL: $uri');
  print('➡️ PHONE: $phone');
  print('➡️ OTP: $otp');

  final res = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'phone': phone,
      'otp': otp,
    }),
  );

  print('⬅️ STATUS: ${res.statusCode}');
  print('⬅️ BODY: ${res.body}');

  if (res.statusCode != 200) {
    throw Exception(res.body);
  }
}






  
static Future<Map<String, dynamic>> createDropoffOrder({
  required String phone,
  required String size,
  required int hours,
  required String helpId,

}) async {
  final res = await http.post(
    Uri.parse('$baseUrl/terminal/dropoff'),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'phone': phone,
      'size': size,
      'hours': hours,
      "helpId": helpId,

    }),
  );

  print('DROP ORDER STATUS: ${res.statusCode}');
  print('DROP ORDER BODY: ${res.body}');

  if (res.statusCode != 200) {
    throw Exception('Failed to create order');
  }

  final data = jsonDecode(res.body);

  // 🔥 HARD VALIDATION
  if (data['orderId'] == null ||
      data['amount'] == null ||
      data['razorpayKeyId'] == null ||
      data['parcelId'] == null) {
    throw Exception('Invalid payment init response');
  }

  return data;
}

static Future<Map<String, dynamic>> personalDropoff({
    required String recipientPhone,
    required String deliveryPhone,
    required String size,
    required int hours,
    required String helpId,
    required int amount, 
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/personal/dropoff'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'recipientPhone': recipientPhone,
        'deliveryPhone': deliveryPhone,
        'size': size,
        'hours': hours,
         'helpId': helpId,
         'amount': amount,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }

    return jsonDecode(response.body);
  }








static Future<Map<String, dynamic>> deliveryDropoff({
  required String recipientPhone,
  required String deliveryPhone,
  required String partnerId,
  required String size,
  required int hours,
}) async {
  print('📡 CALLING DELIVERY DROPOFF API');
print('URL: $baseUrl/delivery/dropoff');

  final res = await http.post(
    Uri.parse('$baseUrl/delivery/dropoff'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'recipientPhone': recipientPhone,
      'deliveryPhone': deliveryPhone,
      'partnerId': partnerId,
      'size': size.toLowerCase(), // backend requires lowercase
      'hours': hours,             // backend still destructures this
    }),
  );

  final data = jsonDecode(res.body);

  if (res.statusCode != 200 || data['success'] != true) {
    throw Exception(data['error'] ?? 'Delivery dropoff failed');
  }

  return data;
}





static Future<Map<String, dynamic>> reserveLocker({
  required String lockerId,
  required String size,
  required String sessionId,
}) async {
  final res = await http.post(
    Uri.parse('$baseUrl/api/kiosk/reserve'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      "lockerId": lockerId,
      "size": size,
      "sessionId": sessionId,
    }),
  );

  return jsonDecode(res.body);
}

  // ---------- VERIFY PAYMENT ----------
  static Future<Map<String, dynamic>> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
    required String parcelId,
    String? helpId,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/terminal/payment/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'razorpay_order_id': orderId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature': signature,
        'parcelId': parcelId,
        'helpId': helpId,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Payment verification failed');
    }

    return jsonDecode(res.body);
  }


  static Future<void> trackLockerClick({
  required String service // "store" | "send" | "drop"
}) async {
  try {
    final uri = Uri.parse('$baseUrl/api/locker/$lockerId/click');

    await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'service': service}),
    );
  } catch (e) {
    // fire-and-forget: never block kiosk flow
    print('Click tracking failed: $e');
  }
}


  // ---------- DROP PAYMENT VERIFY ----------
static Future<Map<String, dynamic>> verifyDropPayment({
  required String orderId,
  required String paymentId,
  required String signature,
  required String parcelId,
}) async {
  final res = await http.post(
    Uri.parse('$baseUrl/terminal/payment/drop-verify'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'razorpay_order_id': orderId,
      'razorpay_payment_id': paymentId,
      'razorpay_signature': signature,
      'parcelId': parcelId,
       
    }),
  );

  if (res.statusCode != 200) {
    throw Exception('Drop payment verification failed');
  }

  return jsonDecode(res.body);
}
static Future<Map<String, dynamic>> createDropoffOrderAuth({
  required String senderPhone,
  required String recipientPhone,
  required String size,
  required int hours,
}) async {
  final res = await http.post(
    Uri.parse('$baseUrl/terminal/authdropoff'),
    headers: {
      'Content-Type': 'application/json',
      'x-client': 'flutter',
    },
    body: jsonEncode({
      'senderPhone': senderPhone,
      'receiverPhone': recipientPhone,
      'size': size.toLowerCase(),
      'hours': hours,
    }),
  );
   print('DROP ORDER STATUS: ${res.statusCode}');
  print('DROP ORDER BODY: ${res.body}');

  if (res.statusCode != 200) {
    throw Exception('Failed to create order');
  }

  return jsonDecode(res.body);
}

static Future<Map<String, dynamic>> getDeliveryEstimate({
  required String dropPincode,
}) async {
  final res = await http.post(
    Uri.parse('$baseUrl/estimate'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'pickupPincode': '500081', // 🔥 your locker pincode
      'dropPincode': dropPincode,
      'weightKg': 1,
    }),
  );

  final data = jsonDecode(res.body);

  if (res.statusCode != 200 || data['success'] != true) {
    throw Exception('Delivery estimation failed');
  }

  return data;
}
static Future<List<Map<String, dynamic>>> fetchSavedReceivers({
    required String senderPhone,
  }) async {
    final uri = Uri.parse('$baseUrl/api/address-book/receivers');

    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'senderPhone': senderPhone,
      }),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode != 200 || data['success'] != true) {
      throw Exception(
        data['message'] ?? 'Failed to fetch saved receivers',
      );
    }

    final List receivers = data['receivers'] ?? [];

    return receivers.cast<Map<String, dynamic>>();
  }


  static Future<Map<String, dynamic>> createParcel({
    required String senderPhone,
    required Map<String, dynamic> receiver,
    required String size, // small | medium | large
  }) async {
    final body = {
      'senderPhone': senderPhone,

      'receiverName': receiver['receiverName'],
      'receiverPhone': receiver['receiverPhone'],

      'delivery_address': receiver['delivery_address'],
      'delivery_city': receiver['delivery_city'],
      'delivery_state': receiver['delivery_state'],
      'delivery_pincode': receiver['delivery_pincode'],

      'size': size,
    };

    final res = await http.post(
      Uri.parse('$baseUrl/api/parcel/create'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Parcel creation failed');
    }

    final data = jsonDecode(res.body);

    return {
      'parcelId': data['parcelId'],
    };
  }

  // ============================================================
  // 2️⃣ FETCH COURIER RATES FOR PARCEL
  // ============================================================

  static Future<List<dynamic>> getParcelRates({
  required String parcelId,
}) async {
  final res = await http.get(
    Uri.parse('$baseUrl/api/parcel/rate/$parcelId'),
  );

  if (res.statusCode != 200) {
    throw Exception('Failed to fetch parcel rates');
  }

  final data = jsonDecode(res.body);
  

  return data['couriers'] as List<dynamic>;
}

static Future<void> selectCourier({
  required String parcelId,
  required int courierCode,
}) async {
  final res = await http.post(
    Uri.parse('$baseUrl/api/parcel/select-courier/$parcelId'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'courier_code': courierCode,
    }),
  );

  if (res.statusCode != 200) {
    throw Exception('Failed to lock courier');
  }
}


 static Future<Map<String, dynamic>> createRazorpayOrder({
    required String parcelId,
    required int amount, // 🔥 amount in paise
  }) async {
    final Uri uri = Uri.parse('$baseUrl/api/razorpay/order');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'parcelId': parcelId,
          'amount': amount,
        }),
      );

      print('CREATE ORDER STATUS => ${response.statusCode}');
      print('CREATE ORDER BODY => ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to create Razorpay order: ${response.body}');
      }

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (data['orderId'] == null ||
          data['amount'] == null ||
          data['key'] == null) {
        throw Exception('Invalid Razorpay order response: $data');
      }

      return {
        'orderId': data['orderId'],
        'amount': data['amount'], // must be in paise
        'key': data['key'],
      };
    } catch (e) {
      print('CREATE ORDER ERROR => $e');
      rethrow;
    }
  }

static Future<Map<String, dynamic>> unlockWithCode(
    String accessCode) async {
  final res = await http.post(
    Uri.parse('$baseUrl/api/locker/unlock-code'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'accessCode': accessCode}),
  );

  final data = jsonDecode(res.body);

  if (res.statusCode >= 500) {
    throw Exception('Server error');
  }

  return data;
}


static Future<Map<String, dynamic>> verifyOverstayPayment({
  required String parcelId,
  required String razorpayOrderId,
  required String razorpayPaymentId,
  required String razorpaySignature,
}) async {
  final uri = Uri.parse('$baseUrl/api/overstay/payment/verify');

  final res = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'parcelId': parcelId,
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_signature': razorpaySignature,
    }),
  );

  final data = jsonDecode(res.body);

  if (res.statusCode != 200 || data['success'] != true) {
    throw Exception(
      data['message'] ?? 'Payment verified but unlock failed',
    );
  }

  return data; // 👈 IMPORTANT
}



static Future<void> verifyRazorpayPayment({
  required String parcelId,
  required String razorpayOrderId,
  required String razorpayPaymentId,
  required String razorpaySignature,
}) async {
  final res = await http.post(
    Uri.parse('$baseUrl/api/razorpay/verify'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'parcelId': parcelId,
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_signature': razorpaySignature,
    }),
  );

  if (res.statusCode != 200) {
    throw Exception('Payment verification failed');
  }
}



static Future<Map<String, dynamic>> createShipment(
    String parcelId) async {
  final res = await http.post(
    Uri.parse('$baseUrl/api/parcel/shiprocket/$parcelId'),
  );

  if (res.statusCode != 200) {
    throw Exception('Shipment creation failed');
  }

  return jsonDecode(res.body);
}


static Future<Map<String, dynamic>> getAllLocked() async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/lockers/all-locked'),
    headers: {
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to fetch locker state');
  }

  return jsonDecode(response.body) as Map<String, dynamic>;
}



}