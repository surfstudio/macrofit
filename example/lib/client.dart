import 'package:example/entities/post_entity.dart';
import 'package:macrofit/macrofit.dart';

@RestClient()
class Client {
  Client(
    this._dio, {
    this.baseUrl,
  });

  @GET('/posts')
  external Future<List<PostEntity>> getPosts();

  @GET('/posts/{id}')
  external Future<PostEntity> getPostById(int id);

  @POST('/posts')
  external Future<PostEntity> createPost(@Body() PostEntity post);

  @PUT('/posts/{id}')
  external Future<PostEntity> updatePost(int id, @Body() PostEntity post);

  @Custom('/posts/{id}', methodName: 'PATCH')
  external Future<PostEntity> patchPost(int id, String title);

  @DELETE('/posts/{id}')
  external Future<void> deletePost(int id);

  @GET('/posts')
  external Future<List<PostEntity>> getPostsByUserId(@Query() int userId);
}
