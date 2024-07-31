import 'package:dio/dio.dart';
import 'package:example/client.dart';
import 'package:example/entities/post_entity.dart';
import 'package:collection/collection.dart';

void main() async {
  final dio = Dio()..interceptors.add(LogInterceptor(logPrint: print));
  final client = Client(dio, baseUrl: 'https://jsonplaceholder.typicode.com');

  const idOfExistingPost = 1;

  final posts = await client.getPosts();

  final userId = posts.firstWhereOrNull((p) => p.userId != null)?.userId;

  if (userId == null) {
    return;
  }

  await client.getPostsByUserId(userId);


  await client.getPostById(idOfExistingPost);


  await client.createPost(
    PostEntity(
      userId: 1111,
      title: 'new post',
      body: 'new post body',
      id: 9999,
    ),
  );

  await client.updatePost(
    idOfExistingPost,
    PostEntity(
      userId: 2222,
      title: 'updated post',
      body: 'updated post body',
      id: idOfExistingPost,
    ),
  );

  await client.patchPost(idOfExistingPost, 'patched title');

  await client.deletePost(idOfExistingPost);
}
