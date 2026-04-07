import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/catalog_models.dart';

class ApiService {
  Catalog? _catalog;

  Future<Catalog> getCatalog() async {
    if (_catalog != null) return _catalog!;
    final String response = await rootBundle.loadString('assets/catalog.json');
    _catalog = Catalog.fromJson(json.decode(response));
    return _catalog!;
  }

  Future<Collection?> getCollection(String id) async {
    final cat = await getCatalog();
    return cat.collections.firstWhere((c) => c.id == id);
  }
}
