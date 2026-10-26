/// Uma carta de trapper com atributos de RPG (tabela `cards`).
class TrapperCard {
  const TrapperCard({
    required this.id,
    required this.name,
    required this.title,
    required this.element,
    required this.rarity,
    required this.attack,
    required this.defense,
    required this.hp,
    required this.specialName,
    required this.specialType,
    required this.specialPower,
    required this.specialDesc,
    required this.lore,
    required this.isStarter,
  });

  final String id;
  final String name;
  final String title;
  final String element;
  final String rarity;
  final int attack;
  final int defense;
  final int hp;
  final String specialName;

  /// damage | pierce | aoe | drain | stun | heal
  final String specialType;
  final int specialPower;
  final String specialDesc;
  final String lore;
  final bool isStarter;

  /// Arte da carta (`lib/assets/cards/<id>.webp`).
  String get imageAsset => 'lib/assets/cards/$id.webp';

  /// Busca do artista no Spotify (abre no app/navegador).
  Uri get spotifyUrl => Uri.parse('https://open.spotify.com/search/${Uri.encodeComponent(name)}');

  /// Duas letras para o avatar: "FabGoDamn" -> "FG", "Teto" -> "TE".
  String get monogram {
    final capitals = name.split('').where((c) => c != c.toLowerCase()).toList();
    if (capitals.length >= 2) return capitals.take(2).join();
    return name.substring(0, name.length < 2 ? name.length : 2).toUpperCase();
  }

  factory TrapperCard.fromMap(Map<String, dynamic> map) => TrapperCard(
        id: map['id'] as String,
        name: map['name'] as String,
        title: map['title'] as String,
        element: map['element'] as String,
        rarity: map['rarity'] as String,
        attack: map['attack'] as int,
        defense: map['defense'] as int,
        hp: map['hp'] as int,
        specialName: map['special_name'] as String,
        specialType: map['special_type'] as String,
        specialPower: map['special_power'] as int,
        specialDesc: map['special_desc'] as String,
        lore: (map['lore'] as String?) ?? '',
        isStarter: (map['is_starter'] as bool?) ?? false,
      );
}
