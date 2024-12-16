import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../db_connection.dart';


Future<List<Map<String, dynamic>>> getComponents({
  String? brand,
  int? year,
  double? minPrice,
  double? maxPrice,
  String? category,
}) async {

  final db = await connectToDb();

  final query = StringBuffer('SELECT * FROM components WHERE 1=1');
  if (brand != null) query.write(' AND brand ILIKE @brand');
  if (year != null) query.write(' AND year = @year');
  if (minPrice != null) query.write(' AND price >= @min_price');
  if (maxPrice != null) query.write(' AND price <= @max_price');
  if (category != null) query.write(' AND category ILIKE @category');

  final result = await db.mappedResultsQuery(
    query.toString(),
    substitutionValues: {
      'brand': '%$brand%',
      'year': year,
      'min_price': minPrice,
      'max_price': maxPrice,
      'category': '%$category%',
    },
  );

  await db.close();

  return result.map((row) => row['components']!).toList();
}


Future<Response> handleGetComponents(Request request) async {
  final queryParams = request.url.queryParameters;

  final brand = queryParams['brand'];
  final year = int.tryParse(queryParams['year'] ?? '');
  final minPrice = double.tryParse(queryParams['min_price'] ?? '0');
  final maxPrice = double.tryParse(queryParams['max_price'] ?? '999999');
  final category = queryParams['category'];

  final components = await getComponents(
    brand: brand,
    year: year,
    minPrice: minPrice,
    maxPrice: maxPrice,
    category: category,
  );

  return Response.ok(jsonEncode(components), headers: {'Content-Type': 'application/json'});
}
