class Env {
  static late String apiBaseUrl;

  static void init({required String apiBaseUrl}) {
    Env.apiBaseUrl = apiBaseUrl;
  }
}
