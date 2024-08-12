/// Annotation for Query parameter. 
class Query {
  final String? as;
  const Query({this.as});
}

/// Annotation for Body parameter.
class Body {
  final String? as;
  const Body({this.as});
}

/// Annotation for Header parameter.
class Header {
  /// Header name.
  final String name;
  
  const Header(this.name);
}

/// Annotation for Part parameter.
/// Used for multipart requests.
class Part {
  final String? as;
  const Part({this.as});
}
