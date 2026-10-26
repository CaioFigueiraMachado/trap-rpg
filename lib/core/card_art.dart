import 'package:flutter/widgets.dart';

/// Enquadramento do rosto em cada arte de carta (para os avatares redondos).
/// `focus` = posição do rosto na imagem (0..1), `zoom` = quantas vezes a
/// largura da imagem é maior que o avatar, `aspect` = altura / largura.
typedef CardArtInfo = ({Offset focus, double zoom, double aspect});

class CardArt {
  static const _tall = 1536 / 1024;
  static const _wide = 1448 / 1086;

  static const _info = <String, CardArtInfo>{
    'klisman': (focus: Offset(0.55, 0.42), zoom: 2.3, aspect: _tall),
    'phlnoturnboy': (focus: Offset(0.53, 0.42), zoom: 2.4, aspect: _tall),
    'alee': (focus: Offset(0.51, 0.39), zoom: 2.3, aspect: _tall),
    'leviano': (focus: Offset(0.54, 0.25), zoom: 2.3, aspect: _wide),
    'teto': (focus: Offset(0.46, 0.28), zoom: 2.7, aspect: _wide),
    'matue': (focus: Offset(0.52, 0.22), zoom: 2.6, aspect: _wide),
    'fabgodamn': (focus: Offset(0.48, 0.24), zoom: 2.5, aspect: _wide),
    'stef': (focus: Offset(0.50, 0.21), zoom: 2.7, aspect: _tall),
    'reid': (focus: Offset(0.50, 0.27), zoom: 2.2, aspect: _tall),
    'fabin': (focus: Offset(0.50, 0.27), zoom: 2.4, aspect: _tall),
  };

  static CardArtInfo? of(String cardId) => _info[cardId];

  /// Filtro preto e branco para cartas bloqueadas / nocauteadas.
  static const grayscale = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0,
  ]);
}
