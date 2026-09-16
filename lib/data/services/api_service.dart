import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// ── Response models ────────────────────────────────────────────────────────

class RegisterResponse {
  final String message;
  final String tempToken;

  RegisterResponse({required this.message, required this.tempToken});

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      message: json['message'] as String? ?? '',
      tempToken: json['temp_token'] as String? ?? '',
    );
  }
}

class LoginResponse {
  final String message;
  final String? token;
  final Map<String, dynamic>? user;

  LoginResponse({required this.message, this.token, this.user});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      message: json['message'] as String? ?? json['detail'] as String? ?? '',
      token: json['token'] as String? ?? json['access_token'] as String?,
      user: json['user'] as Map<String, dynamic>?,
    );
  }
}

class VerifyOtpResponse {
  final String message;

  VerifyOtpResponse({required this.message});

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponse(
      message: json['message'] as String? ?? '',
    );
  }
}

class ResetPasswordResponse {
  final String message;

  ResetPasswordResponse({required this.message});

  factory ResetPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ResetPasswordResponse(
      message: json['message'] as String? ?? '',
    );
  }
}

// ── ApiService ─────────────────────────────────────────────────────────────

class ApiService {
  static const String _baseUrl = 'https://outpost-amigo-require.ngrok-free.dev';

  /// The free ngrok tier shows an HTML "you're about to visit..." interstitial
  /// (with a 200 status) to requests that look like they're from a browser,
  /// instead of forwarding them to the tunnelled backend. This header tells
  /// ngrok to skip that page so requests actually reach the server.
  static const Map<String, String> _noAuthHeaders = {
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };

  /// Helper: build Authorization header from a token.
  Map<String, String> _authHeaders(String token) => {
        ..._noAuthHeaders,
        'Authorization': 'Bearer $token',
      };

  // ── Auth endpoints (no token) ──────────────────────────────────────────

  /// [email] is optional — registration is phone/OTP-based; pass it only if
  /// you want it on file (e.g. for password-reset emails).
  Future<RegisterResponse> register({
    required String firstName,
    required String lastName,
    required String country,
    required String number,
    required String city,
    String? email,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/api/register');
    final body = <String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
      'country': country,
      'number': number,
      'city': city,
      'password': password,
    };
    if (email != null && email.isNotEmpty) body['email'] = email;

    final response = await http.post(
      url,
      headers: _noAuthHeaders,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return RegisterResponse.fromJson(json);
    }
    throw Exception(_extractError(response));
  }

  Future<VerifyOtpResponse> verifyOtp({
    required String tempToken,
    required String code,
  }) async {
    final url = Uri.parse('$_baseUrl/api/register/verify');
    final response = await http.post(
      url,
      headers: _noAuthHeaders,
      body: jsonEncode({
        'temp_token': tempToken,
        'code': code,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return VerifyOtpResponse.fromJson(json);
    }
    throw Exception(_extractError(response));
  }

  /// Login is phone-based (not email) — [number] must match the number the
  /// account was registered/verified with.
  Future<LoginResponse> login({
    required String number,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/api/login');
    final response = await http.post(
      url,
      headers: _noAuthHeaders,
      body: jsonEncode({
        'number': number,
        'password': password,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return LoginResponse.fromJson(json);
    }
    throw Exception(_extractError(response));
  }

  // ── Password reset (no auth) ──────────────────────────────────────────

  /// POST /api/forgot-password — sends reset email/link.
  /// Sends an OTP to [number] for password reset. Response is intentionally
  /// non-enumerable — it returns 200 with the same message whether or not
  /// the number is registered.
  Future<void> forgotPassword({required String number}) async {
    final url = Uri.parse('$_baseUrl/api/forgot-password');
    final response = await http.post(
      url,
      headers: _noAuthHeaders,
      body: jsonEncode({'number': number}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_extractError(response));
    }
  }

  /// POST /api/reset-password — reset password with the OTP code sent by
  /// [forgotPassword].
  Future<ResetPasswordResponse> resetPassword({
    required String number,
    required String code,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/api/reset-password');
    final response = await http.post(
      url,
      headers: _noAuthHeaders,
      body: jsonEncode({
        'number': number,
        'code': code,
        'password': password,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ResetPasswordResponse.fromJson(json);
    }
    throw Exception(_extractError(response));
  }

  /// DELETE /api/account — permanently deletes the signed-in user's
  /// account. Unconfirmed against the live backend (no sample given) —
  /// inferred from the same "singleton resource scoped to the bearer
  /// token, no id in the path" convention as /api/business.
  Future<void> deleteAccount({required String token}) async {
    final url = Uri.parse('$_baseUrl/api/account');
    final response = await http.delete(url, headers: _authHeaders(token));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(_extractError(response));
    }
  }

  // ── Business / Shop endpoints (Bearer token) ──────────────────────────

  /// GET /api/business — get shop profile.
  Future<Map<String, dynamic>> getBusiness(String token) async {
    final url = Uri.parse('$_baseUrl/api/business');
    final response = await http.get(url, headers: _authHeaders(token));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(_extractError(response));
  }

  /// POST /api/business — create or upsert shop profile.
  Future<Map<String, dynamic>> createBusiness({
    required String token,
    required String name,
    required String type,
    required String currency,
    String? address,
    String? phoneNumber,
    String? logoUrl,
    String? city,
    String? country,
  }) async {
    final url = Uri.parse('$_baseUrl/api/business');
    final body = <String, dynamic>{
      'name': name,
      'business_type': type,
      'currency': currency,
    };
    if (address != null) body['address'] = address;
    if (phoneNumber != null) body['phone'] = phoneNumber;
    if (logoUrl != null) body['logo'] = logoUrl;
    if (city != null) body['city'] = city;
    if (country != null) body['country'] = country;

    final response = await http.post(
      url,
      headers: _authHeaders(token),
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(_extractError(response));
  }

  /// PUT /api/business — partial update shop profile.
  Future<Map<String, dynamic>> updateBusiness({
    required String token,
    required Map<String, dynamic> fields,
  }) async {
    final url = Uri.parse('$_baseUrl/api/business');
    final response = await http.put(
      url,
      headers: _authHeaders(token),
      body: jsonEncode(fields),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(_extractError(response));
  }

  // ── Product endpoints (Bearer token) ──────────────────────────────────

  /// GET /api/list/product?page=&limit=&search=&category=
  Future<Map<String, dynamic>> getProducts({
    required String token,
    int? page,
    int? limit,
    String? search,
    String? category,
  }) async {
    final queryParams = <String, String>{};
    if (page != null) queryParams['page'] = page.toString();
    if (limit != null) queryParams['limit'] = limit.toString();
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }

    final uri = Uri.parse('$_baseUrl/api/list/product')
        .replace(queryParameters: queryParams.isEmpty ? null : queryParams);
    final response = await http.get(uri, headers: _authHeaders(token));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Handle both { products: [...] } and bare [...]
      if (data is List) {
        return {'products': data, 'total': data.length};
      }
      return data as Map<String, dynamic>;
    }
    throw Exception(_extractError(response));
  }

  /// POST /api/products/add — create a new product.
  Future<Map<String, dynamic>> createProduct({
    required String token,
    required Map<String, dynamic> productData,
  }) async {
    final url = Uri.parse('$_baseUrl/api/products/add');
    final response = await http.post(
      url,
      headers: _authHeaders(token),
      body: jsonEncode(productData),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(_extractError(response));
  }

  /// PUT /api/products/update/{id} — partial update product.
  Future<Map<String, dynamic>> updateProduct({
    required String token,
    required String productId,
    required Map<String, dynamic> productData,
  }) async {
    final url = Uri.parse('$_baseUrl/api/products/update/$productId');
    final response = await http.put(
      url,
      headers: _authHeaders(token),
      body: jsonEncode(productData),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(_extractError(response));
  }

  /// DELETE /api/products/{id} — returns 204 on success.
  Future<void> deleteProduct({
    required String token,
    required String productId,
  }) async {
    final url = Uri.parse('$_baseUrl/api/products/$productId');
    final response = await http.delete(url, headers: _authHeaders(token));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(_extractError(response));
    }
  }

  /// PATCH /api/products/{id}/stock — {"quantity": 10, "type": "add"|"remove"}.
  Future<Map<String, dynamic>> adjustStock({
    required String token,
    required String productId,
    required int quantity,
    required String type, // "add" or "remove"
  }) async {
    final url = Uri.parse('$_baseUrl/api/products/$productId/stock');
    final response = await http.patch(
      url,
      headers: _authHeaders(token),
      body: jsonEncode({
        'quantity': quantity,
        'type': type,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(_extractError(response));
  }

  // ── Customer endpoints (Bearer token) ───────────────────────────────────

  /// GET /api/list/customer?page=&limit=&search=
  Future<Map<String, dynamic>> getCustomers({
    required String token,
    int? page,
    int? limit,
    String? search,
  }) async {
    final queryParams = <String, String>{};
    if (page != null) queryParams['page'] = page.toString();
    if (limit != null) queryParams['limit'] = limit.toString();
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final uri = Uri.parse('$_baseUrl/api/list/customer')
        .replace(queryParameters: queryParams.isEmpty ? null : queryParams);
    final response = await http.get(uri, headers: _authHeaders(token));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Handle both { items: [...] } and bare [...]
      if (data is List) {
        return {'items': data, 'total': data.length};
      }
      return data as Map<String, dynamic>;
    }
    throw Exception(_extractError(response));
  }

  /// POST /api/customers — create a customer, or {"name","phone"}.
  /// The backend dedupes by (owner_id, phone): a repeat phone number for the
  /// same logged-in owner returns the existing customer at 200 instead of
  /// creating a duplicate; a new phone number returns 201 with a new id
  /// (exposed as the `customer_<n>` string form).
  Future<Map<String, dynamic>> createCustomer({
    required String token,
    required String name,
    required String phone,
  }) async {
    final url = Uri.parse('$_baseUrl/api/customers');
    final response = await http.post(
      url,
      headers: _authHeaders(token),
      body: jsonEncode({
        'name': name,
        'phone': phone,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(_extractError(response));
  }

  /// DELETE /api/customers/{id}.
  Future<void> deleteCustomer({
    required String token,
    required String customerId,
  }) async {
    final url = Uri.parse('$_baseUrl/api/customers/$customerId');
    final response = await http.delete(url, headers: _authHeaders(token));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(_extractError(response));
    }
  }

  /// GET /api/customers/{customerId} — customer detail with money totals
  /// (totalPurchases, totalPaid, outstandingBalance).
  Future<Map<String, dynamic>> getCustomerDetail({
    required String token,
    required String customerId,
  }) async {
    final url = Uri.parse('$_baseUrl/api/customers/$customerId');
    final response = await http.get(url, headers: _authHeaders(token));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(_extractError(response));
  }

  /// POST /api/customers/{customerId}/payments — record a payment against a
  /// customer's outstanding balance (clears udhaar). Returns the updated
  /// customer detail (same shape as [getCustomerDetail]).
  Future<Map<String, dynamic>> recordCustomerPayment({
    required String token,
    required String customerId,
    required double amount,
    String? note,
  }) async {
    final url = Uri.parse('$_baseUrl/api/customers/$customerId/payments');
    final response = await http.post(
      url,
      headers: _authHeaders(token),
      body: jsonEncode({
        'amount': amount,
        if (note != null && note.isNotEmpty) 'note': note,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(_extractError(response));
  }

  // ── Invoice endpoints (Bearer token) ────────────────────────────────────

  /// POST /api/invoices — create an invoice. Stock is decremented
  /// automatically on success; throws (400) if any item's quantity exceeds
  /// available stock, in which case nothing is written server-side.
  Future<Map<String, dynamic>> createInvoice({
    required String token,
    String? customerId,
    required List<Map<String, dynamic>> items,
    double discount = 0,
    double tax = 0,
    double paidAmount = 0,
  }) async {
    final url = Uri.parse('$_baseUrl/api/invoices');
    final response = await http.post(
      url,
      headers: _authHeaders(token),
      body: jsonEncode({
        if (customerId != null) 'customerId': customerId,
        'items': items,
        'discount': discount,
        'tax': tax,
        'paidAmount': paidAmount,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(_extractError(response));
  }

  /// GET /api/list/invoice?page=&limit=&search=
  Future<Map<String, dynamic>> getInvoices({
    required String token,
    int? page,
    int? limit,
    String? search,
  }) async {
    final queryParams = <String, String>{};
    if (page != null) queryParams['page'] = page.toString();
    if (limit != null) queryParams['limit'] = limit.toString();
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final uri = Uri.parse('$_baseUrl/api/list/invoice')
        .replace(queryParameters: queryParams.isEmpty ? null : queryParams);
    final response = await http.get(uri, headers: _authHeaders(token));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return {'items': data, 'total': data.length};
      }
      return data as Map<String, dynamic>;
    }
    throw Exception(_extractError(response));
  }

  /// GET /api/invoices/{id}.
  Future<Map<String, dynamic>> getInvoiceDetail({
    required String token,
    required String invoiceId,
  }) async {
    final url = Uri.parse('$_baseUrl/api/invoices/$invoiceId');
    final response = await http.get(url, headers: _authHeaders(token));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(_extractError(response));
  }

  // ── Upload endpoint (Bearer token) ──────────────────────────────────────

  /// POST /api/upload — multipart file upload (jpg/jpeg/png/webp/gif, max
  /// 5MB). Returns the hosted URL to use as a product's imgURL or the shop
  /// logo field.
  Future<String> uploadImage({
    required String token,
    required File file,
  }) async {
    final url = Uri.parse('$_baseUrl/api/upload');
    final request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['ngrok-skip-browser-warning'] = 'true'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['url'] as String;
    }
    throw Exception(_extractError(response));
  }

  // ── Dashboard endpoint (Bearer token) ───────────────────────────────────

  /// GET /api/dashboard/summary — totalRevenue (all-time), totalOutstanding
  /// (all customers, clamped at 0 per customer), lowStockCount. Computed
  /// live server-side on every request, so it can't drift between devices.
  Future<Map<String, dynamic>> getDashboardSummary({required String token}) async {
    final url = Uri.parse('$_baseUrl/api/dashboard/summary');
    final response = await http.get(url, headers: _authHeaders(token));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(_extractError(response));
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  String _extractError(http.Response response) {
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['detail'] is String) return json['detail'] as String;
      if (json['detail'] is List) {
        return (json['detail'] as List).map((e) => e.toString()).join(', ');
      }
      return json['message'] as String? ??
          'Request failed (${response.statusCode})';
    } catch (_) {
      return 'Request failed (${response.statusCode})';
    }
  }
}
