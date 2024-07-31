// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:macrofit/signatures.dart';
import 'package:macros/macros.dart';

/// Type of returned value.
enum _ResponseType {
  /// Response returns single value.
  single,
  /// Response returns collection. E.g. Future<List<SampleResponse>>.
  list,
  /// Response returns nothing. E.g. Future<void>.
  empty,
}

/// Type of part parameter in multipart request.
enum _PartParamType {
  /// Part parameter is file.
  file,
  /// Part parameter is string.
  string,
  /// Part parameter is not string.
  notString,
}

macro class ClientMacro implements ClassDeclarationsMacro {
  const ClientMacro();
  
  @override
  FutureOr<void> buildDeclarationsForClass(ClassDeclaration clazz, MemberDeclarationBuilder builder) {
    builder.declareInLibrary(DeclarationCode.fromString("import 'package:dio/dio.dart';"));
  }
}

macro class GET implements  MethodDefinitionMacro {
  final String path;
  const GET(this.path);
  
  @override
  FutureOr<void> buildDefinitionForMethod(MethodDeclaration method, FunctionDefinitionBuilder builder) async {  
    return _buildMethod('GET', path, method, builder,);
  }
}

macro class POST implements MethodDefinitionMacro {
  final String path;
  const POST(this.path);
  
  @override
  FutureOr<void> buildDefinitionForMethod(MethodDeclaration method, FunctionDefinitionBuilder builder) async {  
    return _buildMethod('POST', path, method, builder,);
  }
}

macro class DELETE implements MethodDefinitionMacro {
  final String path;
  const DELETE(this.path);
  
  @override
  FutureOr<void> buildDefinitionForMethod(MethodDeclaration method, FunctionDefinitionBuilder builder) async {  
    return _buildMethod('DELETE', path, method, builder,);
  }
}

macro class PUT implements MethodDefinitionMacro {
  final String path;
  const PUT(this.path);
  
  @override
  FutureOr<void> buildDefinitionForMethod(MethodDeclaration method, FunctionDefinitionBuilder builder) async {  
    return _buildMethod('PUT', path, method, builder,);
  }
}

macro class Custom implements MethodDefinitionMacro {
  final String path;
  final String methodName;
  const Custom(this.path, {required this.methodName});
  
  @override
  FutureOr<void> buildDefinitionForMethod(MethodDeclaration method, FunctionDefinitionBuilder builder) async {  
    return _buildMethod(methodName, path, method, builder,);
  }
}

macro class MultiPart implements MethodDefinitionMacro {
  final String path;
  
  final String? queryParams;

  const MultiPart(this.path, {this.queryParams});
  
  @override
  FutureOr<void> buildDefinitionForMethod(MethodDeclaration method, FunctionDefinitionBuilder builder) async {  
    return _buildMethod('POST', path, method, builder, contentType: 'multipart/form-data');
  }
}



FutureOr<void> _buildMethod(String methodType, String path, MethodDeclaration method, FunctionDefinitionBuilder builder, {String? contentType}) async {  
    final type = method.returnType;

    /// Type of value in response.
    TypeAnnotation? valueType;

    var responseType = _ResponseType.single;

    /// Resolve types from dart:core and dio packages.
    final stringType = await builder.resolveIdentifier(Uri.parse(dartCoreUri), stringSignature);
    final dynamicType = await builder.resolveIdentifier(Uri.parse(dartCoreUri), dynamicSignature);
    final mapType = await builder.resolveIdentifier(Uri.parse(dartCoreUri), mapSignature);
    final optionsType = await builder.resolveIdentifier(Uri.parse('package:dio/src/options.dart'), 'Options');
    final listType = await builder.resolveIdentifier(Uri.parse(dartCoreUri), listSignature);

    /// Shortcut for `<String, dynamic>`.
    final stringDynamicMapType = ['<', stringType, ', ', dynamicType ,'>'];

    /// Try to get type of response.
    if (type is NamedTypeAnnotation) {
        /// This is generic type. E.g. Future<SampleResponse>.
        final argType = type.typeArguments.firstOrNull;
        
        /// If type is generic, then get type of value. This will be used to generate code for parsing response.
        valueType = argType is NamedTypeAnnotation ? argType : null;

        /// If response type also generic, then get type of value. 
        if (argType is NamedTypeAnnotation) {
          /// Check if response is list. E.g. Future<List<SampleResponse>>. In that case we have to use map method to parse response.
          responseType  = switch (argType.identifier.name) {
            listSignature => _ResponseType.list,
            voidSignature => _ResponseType.empty,
            _ => _ResponseType.single,
          };
        }

        /// If response is list, then get type of value from list. E.g. Future<List<SampleResponse>>.
        if (valueType is NamedTypeAnnotation && responseType != _ResponseType.single) {
          final innerArgType = (valueType).typeArguments.firstOrNull;
          valueType = innerArgType is NamedTypeAnnotation ? innerArgType.code : valueType;
        }
    }
    else {
      throw StateError('Unsupported return type: $type');
    }

    /// Resolve generic for Dio.fetch method:
    /// - if this a single value, then Map<String, dynamic>;
    /// - if this a list, then List<dynamic>;
    /// - if this a void, then void.
    final fetchResolvedType = {
      _ResponseType.single: [mapType, ...stringDynamicMapType],
      _ResponseType.list: [listType, '<', dynamicType, '>',],
      _ResponseType.empty: [voidSignature],
    };

    /// Get all parameters of method.
    final fields = [...method.positionalParameters, ...method.namedParameters];
    
    /// Code of method body.
    final parts = <Object>[
    'async {\n',
    '\t\tconst _extra = ', ...stringDynamicMapType,'{};\n',
    ..._buildQueryParams(fields, stringDynamicMapType),
    ..._buildHeader(fields, stringDynamicMapType),
    ...(await _buildBody(fields, stringDynamicMapType, builder)),
    '\t\t', responseType != _ResponseType.empty ? 'final _result  = ' : '',
    'await $dioVarSignature.fetch<', 
    ...fetchResolvedType[responseType]!, '>(', optionsType,'(\n',
    "\t\t  method: '$methodType',\n",
    '\t\t  headers: $headerVarSignature,\n',
    '\t\t  extra: _extra,\n',
    if (contentType != null) '\t\t\tcontentType: \'$contentType\',\n',
    '\t\t)\n',
    '\t\t.compose(\n',
    '\t\t\t$dioVarSignature.options,\n',
    '\t\t\t"${_buildPath(fields, path)}",\n',
    '\t\t\tqueryParameters: $queryVarSignature,\n',
    '\t\t\tdata: $bodyVarSignature,\n',
    '\t\t)\n',
    '    .copyWith(baseUrl: $baseUrlVarSignature ?? $dioVarSignature.options.baseUrl));\n',
    
    if (valueType == null) ...[]
    else 
    ...(switch (responseType) {
      _ResponseType.single => ['\t\tfinal value = ',valueType.code,'.fromJson(_result.data!);\n'],
      _ResponseType.list => ['\t\tfinal value = (_result.data! as ', listType, ').map((e) => ', valueType.code, '.fromJson(e)).toList();\n'],
      _ResponseType.empty => [],
    }),
    if (responseType != _ResponseType.empty)'\t\treturn value;\n'
    ];
    
    parts.add('\t}');

    builder.augment(FunctionBodyCode.fromParts(parts));
  }

  bool _isBody(FormalParameterDeclaration field) {
    return field.metadata.any((e) => e.hasAnnotationOf(bodySignature));
  }
  
  bool _isHeader(FormalParameterDeclaration field) {
    return field.metadata.any((e) => e.hasAnnotationOf(headerSignature));
  }
  
  bool _isQuery(FormalParameterDeclaration field) {
    return field.metadata.any((e) => e.hasAnnotationOf(querySignature));
  }
  
  bool _isPart(FormalParameterDeclaration field) {
    return field.metadata.any((e) => e.hasAnnotationOf(partSignature));
  }


  extension AnnotationCheck on MetadataAnnotation {
    bool hasAnnotationOf(String classname) {
      final a = this;
      return a is ConstructorMetadataAnnotation && a.type.identifier.name == classname;
    }
  }

  Future<List<Object>> _buildBody(List<FormalParameterDeclaration> fields,  List<Object> stringDynamicMapType, FunctionDefinitionBuilder builder) async {
    final bodyCreationCode = <Object>[];

    /// Get all parameters with @Body annotation.
    final bodyParams = fields.where(_isBody).toList();

    /// Get all parameters with @Part annotation.
    final partParams = fields.where(_isPart).toList();
    
    /// Here are 3 cases:
    /// - if there are only body parameters, then we have to create a map from them;
    /// - if there are part parameters, then we have to create FormData object and add fields and files to it;
    /// - if there are no body and part parameters, then we have to create an empty map.
    if (bodyParams.isNotEmpty && partParams.isEmpty) {
      /// final _data = <String, dynamic>{};
      bodyCreationCode.addAll([
        '\t\tfinal $bodyVarSignature = ', ...stringDynamicMapType, '{};\n',
      ]);

      /// Collect all primitive parameters and add them to the map.
      final primitiveParams = bodyParams.where((e) {
        final type = e.type;
        return type is NamedTypeAnnotation ? primitiveTypeSignatures.contains(type.identifier.name) : false;
      }).toList();
      
      /// Add all primitive parameters to the map as key-value pairs.
      if (primitiveParams.isNotEmpty) {
        /// Example:
        /// _data.addAll({
        ///  'param1': param1,
        ///  'param2': param2,
        /// });
        bodyCreationCode.addAll([
          '\t\t$bodyVarSignature.addAll({\n',
          ...primitiveParams.map((f) => "\t\t\t'${f.name}': ${f.name},\n"),
          '\t\t});\n',
        ]);
      }

      /// Collect all complex parameters.
      final complexParams = bodyParams.where((e) {
        final type = e.type;
        return type is NamedTypeAnnotation ? !primitiveTypeSignatures.contains(type.identifier.name) : false;
      }).toList();

      /// It is supposed that complex parameters have toJson method.
      for (final param in complexParams) {
        /// Example:
        /// _data.addAll(param3.toJson());
        /// _data.addAll(param4.toJson());
        bodyCreationCode.addAll([
          '\t\t$bodyVarSignature.addAll(', param.name, '.toJson());\n',
        ]);
      }
    }
    else if (partParams.isNotEmpty) {
      final formDataType = await builder.resolveIdentifier(Uri.parse('package:dio/src/form_data.dart'), 'FormData');
      final multipartFileType = await builder.resolveIdentifier(Uri.parse('package:dio/src/multipart_file.dart'), 'MultipartFile');
      final platformType = await builder.resolveIdentifier(Uri.parse('dart:io'), 'Platform');
      final mapEntryType = await builder.resolveIdentifier(Uri.parse(dartCoreUri), 'MapEntry');
      
      /// Example:
      /// final _data = FormData();
      /// _data.fields.add(MapEntry('param1', param1));
      /// _data.fields.add(MapEntry('param2', param2));
      /// _data.files.add(MapEntry('file1', MultipartFile.fromFileSync(file1.path, filename: file1.path.split(Platform.pathSeparator).last)));
      
      bodyCreationCode.addAll([
        '\t\tfinal $bodyVarSignature = ', formDataType, '();\n',
        ...partParams.map((part) {
          final type = part.type;
          final partParamType = type is NamedTypeAnnotation ? switch (type.identifier.name) {
            stringSignature => _PartParamType.string,
            fileSignature => _PartParamType.file,
            _ => _PartParamType.notString,
          } : _PartParamType.notString;

          switch (partParamType) {
            case _PartParamType.string:
              return [
                '\t\t$bodyVarSignature.fields.add(',mapEntryType,'(\n',
                "\t\t\t'${part.name}',\n",
                '\t\t\t${part.name},\n',
                '\t\t));\n',
              ];
            case _PartParamType.file:
              return <Object>[
                '\t\t$bodyVarSignature.files.add(',mapEntryType,'(\n',
                "\t\t\t'${part.name}',\n",
                '\t\t\t', multipartFileType, '.fromFileSync(${part.name}.path, filename: ${part.name}.path.split(', platformType ,'.pathSeparator).last),\n',
                '\t\t));\n',
              ];
            case _PartParamType.notString:
              return [
                '\t\t$bodyVarSignature.fields.add(',mapEntryType,'(',
                "\t\t\t'${part.name}',",
                '\t\t\t${part.name}.toString(),',
                '\t\t));\n',
              ];
          }
        }).expand((e) => e),
      ]);
    }
    else {
      /// Example:
      /// final _data = <String, dynamic>{};
      
      bodyCreationCode.addAll([
        '\t\tfinal $bodyVarSignature = ', ...stringDynamicMapType, '{};\n',
      ]);
    }

    return bodyCreationCode;
  }

  List<Object> _buildQueryParams(List<FormalParameterDeclaration> fields, List<Object> stringDynamicMapType) {
    final queryParamsCreationCode = <Object>[];

    /// Get all parameters with @Query annotation.
    final queryParams = fields.where(_isQuery).toList();

    if (queryParams.isNotEmpty) {
      /// Example:
      /// final queryParameters = <String, dynamic>{
      ///  'param1': param1,
      /// 'param2': param2,
      /// };
      
      queryParamsCreationCode.addAll([
        '\t\tfinal $queryVarSignature = ', ...stringDynamicMapType,'{\n',
        ...queryParams.map((e) => "\t\t\t'${e.name}': ${e.name},\n"),
        '\t\t};\n',
      ]);
    }
    else {
      /// Example:
      /// final queryParameters = <String, dynamic>{};
      
      queryParamsCreationCode.addAll([
        '\t\tfinal $queryVarSignature = ', ...stringDynamicMapType,'{};\n',
      ]);
    }

    return queryParamsCreationCode;
  }

  List<Object> _buildHeader(List<FormalParameterDeclaration> fields, List<Object> stringDynamicMapType) {
   /// Get all parameters with @Header annotation.
   final headerParams = fields.where(_isHeader).toList();

    final headerParamsCreationCode = <Object>[];

    if (headerParams.isNotEmpty) {
      /// Example:
      /// final _headers = <String, dynamic>{
      /// 'param1': param1,
      /// 'param2': param2,
      /// };
      
      headerParamsCreationCode.addAll([
        '\t\tfinal $headerVarSignature = ', ...stringDynamicMapType,'{\n',
        ...headerParams.map((e) {
          /// Search for @Header annotation.
          final meta = e.metadata.firstWhereOrNull((e) => e.hasAnnotationOf(headerSignature)) as ConstructorMetadataAnnotation;
          /// Header annotation has a single positional argument - name.
          final headerName = meta.positionalArguments.firstOrNull;

          if (headerName == null) {
            throw ArgumentError('Header name is not provided');
          }
          
          return ['\t\t\t ', headerName,": ${e.name},\n"];
        }).expand((e) => e),
        '\t\t};\n',
      ]);
    }
    else {
      /// Example:
      /// final _headers = <String, dynamic>{};

      headerParamsCreationCode.addAll([
        '\t\tfinal $headerVarSignature = ', ...stringDynamicMapType,'{};\n',
      ]);
    }

    return headerParamsCreationCode;
  }

  String _buildPath(List<FormalParameterDeclaration> fields, String initialPath) {
    /// Replace all path parameters with actual values.
    /// 
    /// Example:
    /// /posts/{id} -> /posts/${id}
    return initialPath.replaceAllMapped(RegExp(r'{(\w+)}'), (match) {
      final paramName = match.group(1);
      final param = fields.firstWhere((element) => element.identifier.name == paramName, orElse: () => throw ArgumentError('Parameter \'$paramName\' not found'));
      return '\${${param.identifier.name}}';
    });
  }

