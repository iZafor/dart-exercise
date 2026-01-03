extension StringExtensions on String {
  Uri toUri() {
    final isHttp = this.startsWith('http://');
    final withoutProtocol = isHttp ? this.substring(7) : this.substring(8);
    final authoritySeparatorIndex = withoutProtocol.indexOf('/');
    final queryParamIndex = withoutProtocol.indexOf('?');

    final authority = withoutProtocol
        .substring(0, authoritySeparatorIndex)
        .split(':');
    final host = authority.first;
    final port = authority.length > 1 ? int.tryParse(authority[1]) : null;
    final path = authoritySeparatorIndex == -1
        ? ''
        : withoutProtocol.substring(
            authoritySeparatorIndex + 1,
            queryParamIndex == -1 ? null : queryParamIndex,
          );
    final queryParamsText = queryParamIndex == -1
        ? null
        : withoutProtocol.substring(queryParamIndex + 1);
    final queryParams = queryParamsText
        ?.split('&')
        .map((e) => e.split('='))
        .fold(
          <String, String>{},
          (prev, parts) => {...prev, parts[0]: parts[1]},
        );

    return Uri(
      scheme: isHttp ? "http" : "https",
      host: host,
      port: port,
      path: path,
      queryParameters: queryParams,
    );
  }
}

extension IntExtensions on int {
  static const List<String> sizes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];

  String formatByteSize([int width = 6]) {
    if (this <= 1000) {
      return this.toString().padLeft(width) + ' B';
    }

    var res = this.toDouble();
    var count = 0;
    while (res >= 1000) {
      res /= 1000;
      count++;
    }
    return res.toStringAsFixed(2).padLeft(width) + ' ' + sizes[count];
  }
}
