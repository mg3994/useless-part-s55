import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stores/models/schema_class.dart';
import 'package:stores/models/schema_property.dart';

class SchemaService {
  SchemaService._internal();
  static final SchemaService instance = SchemaService._internal();

  final Dio _dio = Dio();
  bool isLoadingFullSchema = false;
  bool isFullSchemaLoaded = false;
  String? loadError;

  Map<String, SchemaClass> _classes = {};
  Map<String, SchemaProperty> _properties = {};
  Map<String, List<String>> _enumerationValues = {};

  Map<String, SchemaClass> get classes =>
      _classes.isEmpty ? _popularClasses : _classes;

  Map<String, SchemaProperty> get properties =>
      _properties.isEmpty ? _popularProperties : _properties;

  Map<String, List<String>> get enumerationValues => _enumerationValues;

  static const Map<String, SchemaClass> _popularClasses = {
    'schema:Thing': SchemaClass(
      id: 'schema:Thing',
      label: 'Thing',
      comment: 'The most generic type of item.',
      subClassOf: [],
    ),
    'schema:Person': SchemaClass(
      id: 'schema:Person',
      label: 'Person',
      comment: 'A person (alive, dead, undead, or fictional).',
      subClassOf: ['schema:Thing'],
    ),
    'schema:Organization': SchemaClass(
      id: 'schema:Organization',
      label: 'Organization',
      comment: 'An organization such as a school, NGO, corporation, club, etc.',
      subClassOf: ['schema:Thing'],
    ),
    'schema:LocalBusiness': SchemaClass(
      id: 'schema:LocalBusiness',
      label: 'LocalBusiness',
      comment: 'A particular physical business or branch of an organization.',
      subClassOf: ['schema:Organization', 'schema:Place'],
    ),
    'schema:Store': SchemaClass(
      id: 'schema:Store',
      label: 'Store',
      comment: 'A retail store.',
      subClassOf: ['schema:LocalBusiness'],
    ),
    'schema:Product': SchemaClass(
      id: 'schema:Product',
      label: 'Product',
      comment: 'Any offered product or service.',
      subClassOf: ['schema:Thing'],
    ),
    'schema:Offer': SchemaClass(
      id: 'schema:Offer',
      label: 'Offer',
      comment: 'An offer to transfer rights to an item or provide a service.',
      subClassOf: ['schema:Thing'],
    ),
    'schema:Event': SchemaClass(
      id: 'schema:Event',
      label: 'Event',
      comment: 'An event happening at a certain time and location.',
      subClassOf: ['schema:Thing'],
    ),
    'schema:Place': SchemaClass(
      id: 'schema:Place',
      label: 'Place',
      comment: 'Entities that have a somewhat fixed, physical extension.',
      subClassOf: ['schema:Thing'],
    ),
    'schema:PostalAddress': SchemaClass(
      id: 'schema:PostalAddress',
      label: 'PostalAddress',
      comment: 'The mailing address.',
      subClassOf: ['schema:Place'],
    ),
    'schema:WebSite': SchemaClass(
      id: 'schema:WebSite',
      label: 'WebSite',
      comment: 'A WebSite is a set of related web pages and other items.',
      subClassOf: ['schema:Thing'],
    ),
    'schema:Article': SchemaClass(
      id: 'schema:Article',
      label: 'Article',
      comment: 'An article, such as a news article or piece of investigative reporting.',
      subClassOf: ['schema:Thing'],
    ),
    'schema:GeoCoordinates': SchemaClass(
      id: 'schema:GeoCoordinates',
      label: 'GeoCoordinates',
      comment: 'The geographic coordinates of a place or event.',
      subClassOf: ['schema:Thing'],
    ),
    'schema:Service': SchemaClass(
      id: 'schema:Service',
      label: 'Service',
      comment: 'A service provided by an organization or business person.',
      subClassOf: ['schema:Thing'],
    ),
  };

  static const Map<String, SchemaProperty> _popularProperties = {
    'schema:name': SchemaProperty(
      id: 'schema:name',
      label: 'name',
      comment: 'The name of the item.',
      domains: ['schema:Thing'],
      ranges: ['schema:Text'],
    ),
    'schema:description': SchemaProperty(
      id: 'schema:description',
      label: 'description',
      comment: 'A description of the item.',
      domains: ['schema:Thing'],
      ranges: ['schema:Text'],
    ),
    'schema:url': SchemaProperty(
      id: 'schema:url',
      label: 'url',
      comment: 'URL of the item.',
      domains: ['schema:Thing'],
      ranges: ['schema:URL'],
    ),
    'schema:image': SchemaProperty(
      id: 'schema:image',
      label: 'image',
      comment: 'An image of the item.',
      domains: ['schema:Thing'],
      ranges: ['schema:URL', 'schema:ImageObject'],
    ),
    'schema:email': SchemaProperty(
      id: 'schema:email',
      label: 'email',
      comment: 'Email address.',
      domains: ['schema:Person', 'schema:Organization'],
      ranges: ['schema:Text'],
    ),
    'schema:telephone': SchemaProperty(
      id: 'schema:telephone',
      label: 'telephone',
      comment: 'The telephone number.',
      domains: ['schema:Person', 'schema:Organization', 'schema:Place'],
      ranges: ['schema:Text'],
    ),
    'schema:jobTitle': SchemaProperty(
      id: 'schema:jobTitle',
      label: 'jobTitle',
      comment: 'The job title of the person.',
      domains: ['schema:Person'],
      ranges: ['schema:Text'],
    ),
    'schema:address': SchemaProperty(
      id: 'schema:address',
      label: 'address',
      comment: 'Physical address of the item.',
      domains: ['schema:Person', 'schema:Organization', 'schema:Place'],
      ranges: ['schema:PostalAddress', 'schema:Text'],
    ),
    'schema:worksFor': SchemaProperty(
      id: 'schema:worksFor',
      label: 'worksFor',
      comment: 'Organizations that the person works for.',
      domains: ['schema:Person'],
      ranges: ['schema:Organization'],
    ),
    'schema:brand': SchemaProperty(
      id: 'schema:brand',
      label: 'brand',
      comment: 'The brand or manufacturer associated with the product.',
      domains: ['schema:Product'],
      ranges: ['schema:Organization', 'schema:Brand'],
    ),
    'schema:price': SchemaProperty(
      id: 'schema:price',
      label: 'price',
      comment: 'The offer price.',
      domains: ['schema:Offer'],
      ranges: ['schema:Number', 'schema:Text'],
    ),
    'schema:priceCurrency': SchemaProperty(
      id: 'schema:priceCurrency',
      label: 'priceCurrency',
      comment: 'The currency of the price in 3-letter ISO 4217 format.',
      domains: ['schema:Offer'],
      ranges: ['schema:Text'],
    ),
    'schema:availability': SchemaProperty(
      id: 'schema:availability',
      label: 'availability',
      comment: 'The availability of this item (e.g. InStock, OutOfStock).',
      domains: ['schema:Offer'],
      ranges: ['schema:ItemAvailability', 'schema:Text'],
    ),
    'schema:offers': SchemaProperty(
      id: 'schema:offers',
      label: 'offers',
      comment: 'An offer to provide this item.',
      domains: ['schema:Product', 'schema:Event'],
      ranges: ['schema:Offer'],
    ),
    'schema:streetAddress': SchemaProperty(
      id: 'schema:streetAddress',
      label: 'streetAddress',
      comment: 'The street address.',
      domains: ['schema:PostalAddress'],
      ranges: ['schema:Text'],
    ),
    'schema:addressLocality': SchemaProperty(
      id: 'schema:addressLocality',
      label: 'addressLocality',
      comment: 'The locality / city.',
      domains: ['schema:PostalAddress'],
      ranges: ['schema:Text'],
    ),
    'schema:addressRegion': SchemaProperty(
      id: 'schema:addressRegion',
      label: 'addressRegion',
      comment: 'The region / state.',
      domains: ['schema:PostalAddress'],
      ranges: ['schema:Text'],
    ),
    'schema:postalCode': SchemaProperty(
      id: 'schema:postalCode',
      label: 'postalCode',
      comment: 'The postal code.',
      domains: ['schema:PostalAddress'],
      ranges: ['schema:Text'],
    ),
    'schema:addressCountry': SchemaProperty(
      id: 'schema:addressCountry',
      label: 'addressCountry',
      comment: 'The country.',
      domains: ['schema:PostalAddress'],
      ranges: ['schema:Text'],
    ),
  };

  static const Map<String, List<String>> _popularEnumerations = {
    'schema:ItemAvailability': [
      'schema:Discontinued',
      'schema:InStock',
      'schema:InStoreOnly',
      'schema:LimitedAvailability',
      'schema:OnlineOnly',
      'schema:OutOfStock',
      'schema:PreOrder',
      'schema:PreSale',
      'schema:SoldOut',
    ],
    'schema:DayOfWeek': [
      'schema:Monday',
      'schema:Tuesday',
      'schema:Wednesday',
      'schema:Thursday',
      'schema:Friday',
      'schema:Saturday',
      'schema:Sunday',
    ],
    'schema:PaymentMethod': [
      'schema:CreditCard',
      'schema:Cash',
      'schema:CheckInAdvance',
      'schema:COD',
      'schema:DirectDebit',
      'schema:PayPal',
    ],
  };

  Future<void> init() async {
    _classes = Map.from(_popularClasses);
    _properties = Map.from(_popularProperties);
    _enumerationValues = Map.from(_popularEnumerations);

    final hasCache = await _loadFromCache();
    if (hasCache) {
      isFullSchemaLoaded = true;
      // Fetch in background to update cache
      fetchAndCacheLatestSchema();
    } else {
      await fetchAndCacheLatestSchema();
    }
  }

  Future<bool> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedClasses = prefs.getString('schemaorg_classes_cached');
      final cachedProps = prefs.getString('schemaorg_properties_cached');
      final cachedEnums = prefs.getString('schemaorg_enums_cached');

      if (cachedClasses != null && cachedProps != null) {
        final List<dynamic> decodedClasses = json.decode(cachedClasses);
        final List<dynamic> decodedProps = json.decode(cachedProps);
        final Map<String, SchemaClass> tempClasses = {};
        final Map<String, SchemaProperty> tempProps = {};

        for (var item in decodedClasses) {
          final cls = SchemaClass.fromJson(item as Map<String, dynamic>);
          tempClasses[cls.id] = cls;
        }
        for (var item in decodedProps) {
          final prop = SchemaProperty.fromJson(item as Map<String, dynamic>);
          tempProps[prop.id] = prop;
        }

        if (cachedEnums != null) {
          final Map<String, dynamic> decodedEnums = json.decode(cachedEnums);
          _enumerationValues = decodedEnums.map(
            (k, v) => MapEntry(k, List<String>.from(v as List)),
          );
        }

        if (tempClasses.isNotEmpty && tempProps.isNotEmpty) {
          _classes = tempClasses;
          _properties = tempProps;
          return true;
        }
      }
    } catch (e) {
      debugPrint('Error loading Schema.org cache from SharedPreferences: $e');
    }
    return false;
  }

  Future<void> fetchAndCacheLatestSchema() async {
    if (isLoadingFullSchema) return;
    isLoadingFullSchema = true;
    loadError = null;

    try {
      final response = await _dio.get(
        'https://schema.org/version/latest/schemaorg-current-https.jsonld',
        options: Options(responseType: ResponseType.plain),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.data as String);
        final List<dynamic> graph = data['@graph'] as List<dynamic>? ?? [];
        final Map<String, SchemaClass> parsedClasses = {};
        final Map<String, SchemaProperty> parsedProperties = {};
        final Map<String, List<String>> parsedEnums = {};

        for (var item in graph) {
          if (item is! Map<String, dynamic>) continue;
          final String id = item['@id'] as String? ?? '';
          if (id.isEmpty) continue;

          final dynamic typeVal = item['@type'];
          final List<String> types = _extractIds(typeVal);
          final String label = _extractString(
            item['rdfs:label'] ?? id.split(':').last,
          );
          final String comment = _extractString(item['rdfs:comment'] ?? '');

          if (types.contains('rdfs:Class')) {
            final List<String> subClasses = _extractIds(
              item['rdfs:subClassOf'],
            );
            parsedClasses[id] = SchemaClass(
              id: id,
              label: label,
              comment: comment,
              subClassOf: subClasses,
            );
          } else if (types.contains('rdf:Property')) {
            final List<String> domains = _extractIds(
              item['schema:domainIncludes'],
            );
            final List<String> ranges = _extractIds(
              item['schema:rangeIncludes'],
            );
            parsedProperties[id] = SchemaProperty(
              id: id,
              label: label,
              comment: comment,
              domains: domains,
              ranges: ranges,
            );
          } else {
            for (var typeId in types) {
              if (typeId != 'rdfs:Class' && typeId != 'rdf:Property') {
                if (!parsedEnums.containsKey(typeId)) {
                  parsedEnums[typeId] = [];
                }
                if (!parsedEnums[typeId]!.contains(id)) {
                  parsedEnums[typeId]?.add(id);
                }
              }
            }
          }
        }

        if (parsedClasses.isNotEmpty && parsedProperties.isNotEmpty) {
          _classes = parsedClasses;
          _properties = parsedProperties;
          _enumerationValues = parsedEnums;
          isFullSchemaLoaded = true;

          final prefs = await SharedPreferences.getInstance();
          final serializedClasses =
              parsedClasses.values.map((c) => c.toJson()).toList();
          final serializedProps =
              parsedProperties.values.map((p) => p.toJson()).toList();

          await prefs.setString(
            'schemaorg_classes_cached',
            json.encode(serializedClasses),
          );
          await prefs.setString(
            'schemaorg_properties_cached',
            json.encode(serializedProps),
          );
          await prefs.setString(
            'schemaorg_enums_cached',
            json.encode(parsedEnums),
          );
          debugPrint(
            'Cached ${parsedClasses.length} Schema.org classes, ${parsedProperties.length} properties, and ${parsedEnums.length} enums!',
          );
        }
      }
    } catch (e) {
      loadError = e.toString();
      debugPrint('Error fetching latest Schema.org schema: $e');
    } finally {
      isLoadingFullSchema = false;
    }
  }

  String _normalizeId(String id) {
    var normalized = id.trim();
    if (normalized.startsWith('https://schema.org/')) {
      normalized = normalized.substring('https://schema.org/'.length);
    } else if (normalized.startsWith('http://schema.org/')) {
      normalized = normalized.substring('http://schema.org/'.length);
    } else if (normalized.startsWith('schema:')) {
      normalized = normalized.substring('schema:'.length);
    }
    return normalized;
  }

  bool isSubclassOf(String childId, String parentId) {
    final normChild = _normalizeId(childId);
    final normParent = _normalizeId(parentId);
    if (normChild == normParent || normParent == 'Thing') {
      return true;
    }

    SchemaClass? cls;
    for (var entry in classes.entries) {
      if (_normalizeId(entry.key) == normChild) {
        cls = entry.value;
        break;
      }
    }
    if (cls == null) return false;

    for (var parent in cls.subClassOf) {
      if (isSubclassOf(parent, parentId)) {
        return true;
      }
    }
    return false;
  }

  List<String> getEnumOptions(List<String> ranges) {
    final List<String> options = [];
    for (var rangeId in ranges) {
      final values = _enumerationValues[rangeId];
      if (values != null) {
        options.addAll(values);
      }
    }
    options.sort();
    return options;
  }

  String _extractString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map<String, dynamic> && value.containsKey('@value')) {
      return value['@value'].toString();
    }
    if (value is List && value.isNotEmpty) {
      return _extractString(value.first);
    }
    return value.toString();
  }

  List<String> _extractIds(dynamic value) {
    if (value == null) return [];
    if (value is String) return [value];
    if (value is Map<String, dynamic> && value.containsKey('@id')) {
      return [value['@id'].toString()];
    }
    if (value is List) {
      final List<String> result = [];
      for (var item in value) {
        result.addAll(_extractIds(item));
      }
      return result;
    }
    return [];
  }

  List<SchemaProperty> getPropertiesForClass(String classId) {
    final List<String> ancestorClasses = _getAncestors(classId);
    ancestorClasses.add(classId);
    if (!ancestorClasses.contains('schema:Thing')) {
      ancestorClasses.add('schema:Thing');
    }

    final List<SchemaProperty> matching = [];
    for (var prop in properties.values) {
      for (var domain in prop.domains) {
        if (ancestorClasses.contains(domain) ||
            ancestorClasses.any((a) => _normalizeId(a) == _normalizeId(domain))) {
          matching.add(prop);
          break;
        }
      }
    }
    matching.sort((a, b) => a.label.compareTo(b.label));
    return matching;
  }

  List<String> _getAncestors(String classId) {
    final List<String> ancestors = [];
    final queue = <String>[classId];
    final visited = <String>{};

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final normCurrent = _normalizeId(current);
      if (visited.contains(normCurrent)) continue;
      visited.add(normCurrent);

      SchemaClass? cls;
      for (var entry in classes.entries) {
        if (_normalizeId(entry.key) == normCurrent) {
          cls = entry.value;
          break;
        }
      }

      if (cls != null) {
        for (var parent in cls.subClassOf) {
          final normParent = _normalizeId(parent);
          if (!ancestors.any((anc) => _normalizeId(anc) == normParent)) {
            ancestors.add(parent);
            queue.add(parent);
          }
        }
      }
    }
    return ancestors;
  }
}
