import 'package:stores/models/schema_value.dart';
import 'package:stores/services/schema_service.dart';

class SchemaEntity {
  SchemaEntity({
    required this.id,
    required this.type,
    required this.properties,
    this.name = 'Untitled Document',
    this.baseUri,
  });

  final String id;
  String type;
  final Map<String, List<SchemaValue>> properties;
  String name;
  String? baseUri;

  static const Map<String, String> _namespaces = {
    'bibo': 'http://purl.org/ontology/bibo/',
    'brick': 'https://brickschema.org/schema/Brick#',
    'cmns-cls': 'https://www.omg.org/spec/Commons/Classifiers/',
    'cmns-col': 'https://www.omg.org/spec/Commons/Collections/',
    'cmns-dt': 'https://www.omg.org/spec/Commons/DatesAndTimes/',
    'cmns-ge': 'https://www.omg.org/spec/Commons/GeopoliticalEntities/',
    'cmns-id': 'https://www.omg.org/spec/Commons/Identifiers/',
    'cmns-loc': 'https://www.omg.org/spec/Commons/Locations/',
    'cmns-q': 'https://www.omg.org/spec/Commons/Quantities/',
    'cmns-txt': 'https://www.omg.org/spec/Commons/Text/',
    'csvw': 'http://www.w3.org/ns/csvw#',
    'dc': 'http://purl.org/dc/elements/1.1/',
    'dcat': 'http://www.w3.org/ns/dcat#',
    'dct': 'http://purl.org/dc/terms/',
    'eli': 'http://data.europa.eu/eli/ontology#',
    'foaf': 'http://xmlns.com/foaf/0.1/',
    'geo': 'http://www.opengis.net/ont/geosparql#',
    'gs1': 'https://ref.gs1.org/voc/',
    'owl': 'http://www.w3.org/2002/07/owl#',
    'rdf': 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
    'rdfs': 'http://www.w3.org/2000/01/rdf-schema#',
    'schema': 'https://schema.org/',
    'skos': 'http://www.w3.org/2004/02/skos/core#',
    'time': 'http://www.w3.org/2006/time#',
    'xsd': 'http://www.w3.org/2001/XMLSchema#',
  };

  bool _isEnumerationValue(String value) {
    for (var list in SchemaService.instance.enumerationValues.values) {
      if (list.contains(value)) {
        return true;
      }
    }
    return false;
  }

  void _collectUsedNamespaces(dynamic val, Set<String> used) {
    if (val is SchemaEntity) {
      final t = val.type;
      if (t.contains(':')) {
        final prefix = t.split(':').first;
        if (_namespaces.containsKey(prefix)) {
          used.add(prefix);
        }
      }
      for (var values in val.properties.values) {
        for (var sv in values) {
          _collectUsedNamespaces(sv.value, used);
        }
      }
    } else if (val is Map) {
      final t = val['@type']?.toString();
      if (t != null && t.contains(':')) {
        final prefix = t.split(':').first;
        if (_namespaces.containsKey(prefix)) {
          used.add(prefix);
        }
      }
      for (var entry in val.entries) {
        _collectUsedNamespaces(entry.value, used);
      }
    } else if (val is List) {
      for (var item in val) {
        _collectUsedNamespaces(item, used);
      }
    }
  }

  Map<String, dynamic> toJsonLd({
    bool isRoot = false,
    Map<String, String>? docIdToName,
  }) {
    final Map<String, dynamic> result = {};
    if (isRoot) {
      final Set<String> usedPrefixes = {};
      _collectUsedNamespaces(this, usedPrefixes);

      final Map<String, String> extraContext = {};
      for (var prefix in usedPrefixes) {
        final nsUrl = _namespaces[prefix];
        if (nsUrl != null) {
          extraContext[prefix] = nsUrl;
        }
      }

      if (baseUri == null || baseUri!.trim().isEmpty) {
        if (extraContext.isNotEmpty) {
          result['@context'] = {
            '@vocab': 'https://schema.org/',
            ...extraContext,
          };
        } else {
          result['@context'] = 'https://schema.org';
        }
      } else {
        result['@context'] = {
          '@vocab': 'https://schema.org/',
          '@base': baseUri!.trim(),
          ...extraContext,
        };
      }
    }

    final String typeName =
        type.startsWith('schema:') ? type.substring(7) : type;
    final bool isKeyword = typeName.startsWith('@');

    if (!isKeyword) {
      result['@type'] = typeName;
    }

    bool isNameRenamed(String nameValue) {
      final clean = nameValue.trim();
      return clean.isNotEmpty &&
          clean != 'Untitled Document' &&
          clean != 'Untitled Object' &&
          clean != 'Schema Document' &&
          !clean.startsWith('New ') &&
          !clean.endsWith(' Reference') &&
          !clean.endsWith(' Markup');
    }

    final String effectiveBase =
        (baseUri != null && baseUri!.trim().isNotEmpty)
            ? baseUri!.trim()
            : 'https://example.com/things/';

    if (!isKeyword) {
      if (isNameRenamed(name)) {
        final safeId = name
            .trim()
            .toLowerCase()
            .replaceAll(RegExp(r'[^\w\s\-]'), '')
            .replaceAll(RegExp(r'\s+'), '-');
        result['@id'] = '#$safeId';
      } else if (id.startsWith(effectiveBase)) {
        result['@id'] = id.substring(effectiveBase.length);
      } else if (id.startsWith('http://') || id.startsWith('https://')) {
        result['@id'] = id;
      }
    }

    properties.forEach((propId, values) {
      if (values.isEmpty) {
        return;
      }
      final propName =
          propId.startsWith('schema:') ? propId.substring(7) : propId;
      final List<dynamic> jsonValues = [];
      for (var val in values) {
        if (val.value is SchemaEntity) {
          jsonValues.add(
            (val.value as SchemaEntity).toJsonLd(
              isRoot: false,
              docIdToName: docIdToName,
            ),
          );
        } else if (val.value is Map &&
            (val.value as Map).containsKey('@value')) {
          jsonValues.add(val.value);
        } else if (val.value is Map && (val.value as Map).containsKey('@id')) {
          final targetDocId = (val.value as Map)['@id'] as String;
          final targetDocName =
              docIdToName?[targetDocId] ??
              (val.value as Map)['docName'] ??
              '';
          if (isNameRenamed(targetDocName)) {
            final safeLinkedId = targetDocName
                .trim()
                .toLowerCase()
                .replaceAll(RegExp(r'[^\w\s\-]'), '')
                .replaceAll(RegExp(r'\s+'), '-');
            jsonValues.add({'@id': '#$safeLinkedId'});
          } else {
            if (targetDocId.startsWith(effectiveBase)) {
              jsonValues.add({
                '@id': targetDocId.substring(effectiveBase.length),
              });
            } else if (targetDocId.startsWith('http://') ||
                targetDocId.startsWith('https://') ||
                targetDocId.startsWith('#')) {
              jsonValues.add({'@id': targetDocId});
            } else {
              jsonValues.add({'@id': '#$targetDocId'});
            }
          }
        } else if (val.value is String) {
          final String strVal = val.value as String;
          if (strVal.startsWith('schema:') && _isEnumerationValue(strVal)) {
            jsonValues.add('https://schema.org/${strVal.substring(7)}');
          } else {
            jsonValues.add(val.value);
          }
        } else {
          jsonValues.add(val.value);
        }
      }
      if (jsonValues.isNotEmpty) {
        result[propName] =
            jsonValues.length == 1 ? jsonValues.first : jsonValues;
      }
    });

    return result;
  }

  SchemaEntity clone() {
    final Map<String, List<SchemaValue>> clonedProps = {};
    properties.forEach((key, list) {
      clonedProps[key] = list.map((v) {
        final val = v.value;
        return SchemaValue(
          id: v.id,
          value: val is SchemaEntity
              ? val.clone()
              : (val is Map ? Map.from(val) : val),
        );
      }).toList();
    });
    return SchemaEntity(
      id: 'nest_${DateTime.now().microsecondsSinceEpoch}_$id',
      type: type,
      properties: clonedProps,
      name: name,
      baseUri: baseUri,
    );
  }

  Map<String, dynamic> serializeProperties() {
    final Map<String, dynamic> serialized = {};
    if (baseUri != null) {
      serialized['_baseUri'] = baseUri;
    }
    properties.forEach((propId, values) {
      final List<dynamic> listData = [];
      for (var val in values) {
        if (val.value is SchemaEntity) {
          listData.add({
            'type': 'entity',
            'id': (val.value as SchemaEntity).id,
            'name': (val.value as SchemaEntity).name,
            'schemaType': (val.value as SchemaEntity).type,
            'properties': (val.value as SchemaEntity).serializeProperties(),
          });
        } else if (val.value is Map) {
          listData.add({
            'type': 'map',
            'value': Map<String, dynamic>.from(val.value as Map),
          });
        } else {
          listData.add({
            'type': 'primitive',
            'value': val.value,
          });
        }
      }
      serialized[propId] = listData;
    });
    return serialized;
  }

  static Map<String, List<SchemaValue>> deserializeProperties(
    Map<String, dynamic> data,
  ) {
    final Map<String, List<SchemaValue>> parsed = {};
    data.forEach((propId, valList) {
      if (valList is List) {
        final List<SchemaValue> sValues = [];
        for (var item in valList) {
          if (item is Map<String, dynamic>) {
            final type = item['type']?.toString();
            if (type == 'entity') {
              final nested = SchemaEntity(
                id: item['id']?.toString() ??
                    'nest_${DateTime.now().microsecondsSinceEpoch}',
                name: item['name']?.toString() ?? 'Untitled Nested',
                type: item['schemaType']?.toString() ?? 'schema:Thing',
                properties: deserializeProperties(
                  item['properties'] as Map<String, dynamic>? ?? {},
                ),
              );
              sValues.add(
                SchemaValue(
                  id: 'val_${DateTime.now().microsecondsSinceEpoch}_${item.hashCode}',
                  value: nested,
                ),
              );
            } else if (type == 'map') {
              sValues.add(
                SchemaValue(
                  id: 'val_${DateTime.now().microsecondsSinceEpoch}_${item.hashCode}',
                  value: item['value'],
                ),
              );
            } else {
              sValues.add(
                SchemaValue(
                  id: 'val_${DateTime.now().microsecondsSinceEpoch}_${item.hashCode}',
                  value: item['value'],
                ),
              );
            }
          }
        }
        if (sValues.isNotEmpty) {
          parsed[propId] = sValues;
        }
      }
    });
    return parsed;
  }

  static SchemaEntity fromJsonLd(
    Map<String, dynamic> json, {
    String? defaultType,
    String? docName,
  }) {
    final String type =
        json['@type']?.toString() ?? defaultType ?? 'schema:Thing';
    final String normalizedType = type.contains(':') ? type : 'schema:$type';
    final Map<String, List<SchemaValue>> properties = {};

    json.forEach((key, val) {
      if (key == '@context' || key == '@type') {
        return;
      }
      final String propId = key.startsWith('@')
          ? 'schema:$key'
          : (key.contains(':') ? key : 'schema:$key');
      final List<SchemaValue> values = [];

      void parseValue(dynamic singleVal) {
        if (singleVal is Map<String, dynamic>) {
          if (singleVal.containsKey('@value')) {
            values.add(
              SchemaValue(
                id: '${DateTime.now().microsecondsSinceEpoch}_${singleVal.hashCode}',
                value: Map<String, dynamic>.from(singleVal),
              ),
            );
          } else if (singleVal.containsKey('@id')) {
            final refId = singleVal['@id'].toString().replaceAll('#', '');
            values.add(
              SchemaValue(
                id: '${DateTime.now().microsecondsSinceEpoch}_${singleVal.hashCode}',
                value: {
                  '@id': refId,
                  'docName':
                      '${refId.replaceAll('doc_', 'Document ')} Reference',
                },
              ),
            );
          } else {
            values.add(
              SchemaValue(
                id: '${DateTime.now().microsecondsSinceEpoch}_${singleVal.hashCode}',
                value: SchemaEntity.fromJsonLd(
                  singleVal,
                  defaultType: key.startsWith('@') ? 'schema:$key' : null,
                ),
              ),
            );
          }
        } else if (singleVal != null) {
          var parsedVal = singleVal;
          if (singleVal is String) {
            final String s = singleVal.trim();
            if (s.startsWith('https://schema.org/') ||
                s.startsWith('http://schema.org/')) {
              final String suffix = s.substring(s.lastIndexOf('/') + 1);
              final String candidate = 'schema:$suffix';
              bool matched = false;
              for (var list
                  in SchemaService.instance.enumerationValues.values) {
                if (list.contains(candidate)) {
                  matched = true;
                  break;
                }
              }
              if (matched ||
                  (suffix.isNotEmpty &&
                      suffix[0] == suffix[0].toUpperCase())) {
                parsedVal = candidate;
              }
            }
          }
          values.add(
            SchemaValue(
              id: '${DateTime.now().microsecondsSinceEpoch}_${singleVal.hashCode}',
              value: parsedVal,
            ),
          );
        }
      }

      if (val is List) {
        for (var item in val) {
          parseValue(item);
        }
      } else {
        parseValue(val);
      }

      if (values.isNotEmpty) {
        properties[propId] = values;
      }
    });

    return SchemaEntity(
      id: '${DateTime.now().microsecondsSinceEpoch}_${json.hashCode}',
      type: normalizedType,
      properties: properties,
      name: docName ?? '${type.split(':').last} Markup',
    );
  }
}
