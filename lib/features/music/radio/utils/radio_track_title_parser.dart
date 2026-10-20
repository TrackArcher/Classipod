class ParsedRadioTrack {
  const ParsedRadioTrack({this.artist, this.title});

  final String? artist;
  final String? title;
}

ParsedRadioTrack parseRadioStreamTitle(String streamTitle) {
  final trimmed = streamTitle.trim();
  if (trimmed.isEmpty) {
    return const ParsedRadioTrack();
  }
  final parts = trimmed.split(' - ');
  if (parts.length >= 2) {
    final artist = parts.first.trim();
    final title = parts.sublist(1).join(' - ').trim();
    return ParsedRadioTrack(
      artist: artist.isEmpty ? null : artist,
      title: title.isEmpty ? null : title,
    );
  }
  return ParsedRadioTrack(title: trimmed);
}
