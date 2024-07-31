/// Annotation for Query parameter. 
class Query {
  const Query();
}

/// Annotation for Body parameter.
class Body {
  const Body();
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
  const Part();
}