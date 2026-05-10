import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../models/quote_model.dart';

class QuoteService {
  static const List<QuoteModel> _fallbackQuotes = [
    QuoteModel(
      content: 'The secret of getting ahead is getting started.',
      author: 'Mark Twain',
    ),
    QuoteModel(
      content: 'Small daily improvements are the key to staggering results.',
      author: 'Robin Sharma',
    ),
    QuoteModel(
      content:
          'Success is the sum of small efforts repeated day in and day out.',
      author: 'Robert Collier',
    ),
    QuoteModel(
      content:
          'Discipline is choosing between what you want now and what you want most.',
      author: 'Abraham Lincoln',
    ),
    QuoteModel(
      content: 'Focus on being productive instead of busy.',
      author: 'Tim Ferriss',
    ),
  ];

  Future<QuoteModel> fetchQuote() async {
    try {
      final response = await http
          .get(
            Uri.parse(
              'https://api.quotable.io/quotes/random?maxLength=140&tags=inspirational|wisdom|success',
            ),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw HttpException('Quote service returned ${response.statusCode}');
      }
      final body = jsonDecode(response.body);
      if (body is List && body.isNotEmpty && body.first is Map) {
        return QuoteModel.fromJson(Map<String, dynamic>.from(body.first));
      }
      if (body is Map<String, dynamic>) {
        return QuoteModel.fromJson(body);
      }
      throw const FormatException('Unexpected quote response');
    } on SocketException {
      return _fallbackQuote();
    } on TimeoutException {
      return _fallbackQuote();
    } catch (_) {
      return _fallbackQuote();
    }
  }

  QuoteModel _fallbackQuote() {
    return _fallbackQuotes[Random().nextInt(_fallbackQuotes.length)]
        .asFallback();
  }
}
