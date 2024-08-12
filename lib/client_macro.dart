import 'dart:async';

import 'package:macrofit/signatures.dart';
import 'package:macros/macros.dart';

macro class RestClient implements ClassDeclarationsMacro {
  const RestClient();

  @override
  FutureOr<void> buildDeclarationsForClass(ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    final fields = await builder.fieldsOf(clazz);

    builder.declareInLibrary(DeclarationCode.fromString('import \'package:dio/dio.dart\';'));
    builder.declareInLibrary(DeclarationCode.fromString('import \'dart:core\';'));

    /// Check if the class has a baseUrl field.
    final indexOfBaseUrl = fields.indexWhere((element) => element.identifier.name == baseUrlVarSignature);
    if (indexOfBaseUrl == -1) {
      builder.declareInType(DeclarationCode.fromParts(['\tfinal String? $baseUrlVarSignature;']));
    } else {
      final baseUrlField = fields[indexOfBaseUrl];
      final type = baseUrlField.type;
      if (type is! NamedTypeAnnotation) {
        throw ArgumentError('$baseUrlVarSignature field must be of type $stringSignature');
      }
      if (type.identifier.name != stringSignature) {
        throw ArgumentError('$baseUrlVarSignature field must be of type $stringSignature');
      }
    }

    /// Check if the class has a Dio field.
    final indexOfDio = fields.indexWhere((element) => element.identifier.name == dioVarSignature);
    if (indexOfDio == -1) {
      builder.declareInType(DeclarationCode.fromParts(['\tfinal $dioSignature $dioVarSignature;']));
    } else {
      final dioField = fields[indexOfDio];
      final type = dioField.type;
      if (type is! NamedTypeAnnotation) {
        throw ArgumentError('$dioVarSignature field must be of type $dioSignature');
      }
      if (type.identifier.name != dioSignature) {
        throw ArgumentError('$dioVarSignature field must be of type $dioSignature');
      }
    }
  }
}
