class_name JapaneseDeckLogic

var deck = []

var letters_dict = {
	'a': ['あ', 'ア'], 'i': ['い', 'イ'], 'u': ['う', 'ウ'], 'e': ['え', 'エ'], 'o': ['お', 'オ'],
	'ka': ['か', 'カ'], 'ki': ['き', 'キ'], 'ku': ['く', 'ク'], 'ke': ['け', 'ケ'], 'ko': ['こ', 'コ'],
	'sa': ['さ', 'サ'], 'shi': ['し', 'シ'], 'su': ['す', 'ス'], 'se': ['せ', 'セ'], 'so': ['そ', 'ソ'],
	'ta': ['た', 'タ'], 'chi': ['ち', 'チ'], 'tsu': ['つ', 'ツ'], 'te': ['て', 'テ'], 'to': ['と', 'ト'],
	'na': ['な', 'ナ'], 'ni': ['に', '二'], 'nu': ['ぬ', 'ヌ'], 'ne': ['ね', 'ネ'], 'no': ['の', 'ノ'],
	'ha': ['は', 'ハ'], 'hi': ['ひ', 'ヒ'], 'fu': ['ふ', 'フ'], 'he': ['へ', 'ヘ'], 'ho': ['ほ', 'ホ'],
	'ma': ['ま', 'マ'], 'mi': ['み', 'ミ'], 'mu': ['む', 'ム'], 'me': ['め', 'メ'], 'mo': ['も', 'モ'],
	'ya': ['や', 'ヤ'],                     'yu': ['ゆ', 'ユ'],                    'yo': ['よ', 'ヨ'],
	'ra': ['ら', 'ラ'], 'ri': ['り', 'リ'], 'ru': ['る', 'ル'], 're': ['れ', 'レ'], 'ro': ['ろ', 'ロ'],
	'wa': ['わ', 'ワ'],                                                            'wo': ['を', 'ヲ'],
	'n': ['ん', 'ン']
}

func _init(type: int, size: int = -1):
	if size == -1:
		for english in letters_dict:
			deck.append([english.to_upper(), letters_dict[english][type]])
	else:
		for english in letters_dict:
			deck.append([english.to_upper(), letters_dict[english][type]])
			size -= 1
			if size < 0:
				break


func shuffle():
	deck.shuffle()
