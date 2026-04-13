package Wikibase::Datatype::Languages;

use base qw(Exporter);
use strict;
use utf8;
use warnings;

use Readonly;

# Constants.
Readonly::Array our @EXPORT => qw(all_language_codes all_term_language_codes);
Readonly::Hash our %TERM_LANGUAGES => (
	# Special codes.
	'mul' => 'multiple languages', # Q20923490

	# Codes in https://doc.wikimedia.org/mediawiki-core/master/php/Names_8php_source.html
	# Repository: https://github.com/wikimedia/mediawiki.git
	# Updated 2026-04-12 in mediawiki/includes/Languages/Data/Names.php, commit 5360f7180c90c188b11047e2e8be18da9b6cf332
	'aa' => 'Qafár af', # Afar
	'aae' => 'Arbërisht', # Arbëresh
	'ab' => 'аԥсшәа', # Abkhaz
	'abr' => 'Abron', # Bono
	'abs' => 'bahasa ambon', # Ambonese Malay, T193566
	'ace' => 'Acèh', # Aceh
	'acf' => 'Kwéyòl Sent Lisi', # Saint Lucian Creole
	'acm' => 'عراقي', # Iraqi (Mesopotamian) Arabic
	'ady' => 'адыгабзэ', # Adyghe
	'ady-cyrl' => 'адыгабзэ', # Adyghe
	'aeb' => 'تونسي / Tûnsî', # Tunisian Arabic (multiple scripts - defaults to Arabic)
	'aeb-arab' => 'تونسي', # Tunisian Arabic (Arabic Script)
	'aeb-latn' => 'Tûnsî', # Tunisian Arabic (Latin Script)
	'af' => 'Afrikaans', # Afrikaans
	'aig' => 'Aanteegan an\' Baabyuudan', # Antiguan and Barbudan Creole English
	'aln' => 'Gegë', # Gheg Albanian
	'als' => 'Alemannisch', # Alemannic -- not a valid code, for compatibility. See gsw.
	'alt' => 'алтай тил', # Altai, T254854
	'am' => 'አማርኛ', # Amharic
	'ami' => 'Pangcah', # Amis
	'an' => 'aragonés', # Aragonese
	'ang' => 'Ænglisc', # Old English, T25283
	'ann' => 'Obolo', # Obolo
	'anp' => 'अंगिका', # Angika
	'apc' => 'شامي', # Levantine Arabic
	'ar' => 'العربية', # Arabic
	'arc' => 'ܐܪܡܝܐ', # Aramaic
	'arn' => 'mapudungun', # Mapuche, Mapudungu, Araucanian (Araucano)
	'arq' => 'جازايرية', # Algerian Spoken Arabic
	'ary' => 'الدارجة', # Moroccan Spoken Arabic
	'arz' => 'مصرى', # Egyptian Spoken Arabic
	'as' => 'অসমীয়া', # Assamese
	'ase' => 'American sign language', # American sign language
	'ast' => 'asturianu', # Asturian
	'atj' => 'Atikamekw', # Atikamekw
	'av' => 'авар', # Avar
	'avk' => 'Kotava', # Kotava
	'awa' => 'अवधी', # Awadhi
	'ay' => 'Aymar aru', # Aymara
	'az' => 'azərbaycanca', # Azerbaijani
	'azb' => 'تۆرکجه', # South Azerbaijani
	'ba' => 'башҡортса', # Bashkir
	'ban' => 'Basa Bali', # Balinese (Latin script)
	'ban-bali' => 'ᬩᬲᬩᬮᬶ', # Balinese (Balinese script)
	'bar' => 'Boarisch', # Bavarian (Austro-Bavarian and South Tyrolean)
	'bat-smg' => 'žemaitėška', # Samogitian (deprecated code, 'sgs' in ISO 639-3 since 2010-06-30 )
	'bbc' => 'Batak Toba', # Batak Toba (falls back to bbc-latn)
	'bbc-latn' => 'Batak Toba', # Batak Toba
	'bcc' => 'جهلسری بلوچی', # Southern Balochi
	'bci' => 'wawle', # Baoulé
	'bcl' => 'Bikol Central', # Bikol: Central Bicolano language
	'bdr' => 'Bajau Sama', # West Coast Bajau
	'be' => 'беларуская', # Belarusian normative
	'be-tarask' => 'беларуская (тарашкевіца)', # Belarusian in Taraskievica orthography
	'be-x-old' => 'беларуская (тарашкевіца)', # (be-tarask compat)
	'bew' => 'Betawi', # Betawi
	'bg' => 'български', # Bulgarian
	'bgc' => 'हरियाणवी', # Haryanvi
	'bgn' => 'روچ کپتین بلوچی', # Western Balochi
	'bh' => 'भोजपुरी', # Bihari macro language. Falls back to Bhojpuri (bho)
	'bho' => 'भोजपुरी', # Bhojpuri
	'bi' => 'Bislama', # Bislama
	'bjn' => 'Banjar', # Banjarese
	'blk' => 'ပအိုဝ်ႏဘာႏသာႏ', # Pa'O
	'bm' => 'bamanankan', # Bambara
	'bn' => 'বাংলা', # Bengali
	'bo' => 'བོད་ཡིག', # Tibetan
	'bol' => 'bòo pìkkà', # Bole
	'bpy' => 'বিষ্ণুপ্রিয়া মণিপুরী', # Bishnupriya Manipuri
	'bqi' => 'بختیاری', # Bakthiari
	'br' => 'brezhoneg', # Breton
	'brh' => 'Bráhuí', # Brahui
	'bs' => 'bosanski', # Bosnian
	'btm' => 'Batak Mandailing', # Batak Mandailing
	'bto' => 'Iriga Bicolano', # Rinconada Bikol
	'bug' => 'Basa Ugi', # Buginese
	'bug-bugi' => 'ᨅᨔ ᨕᨘᨁᨗ', # Buginese (Buginese script), T389916
	'bxr' => 'буряад', # Buryat (Russia)
	'ca' => 'català', # Catalan
	'cbk-zam' => 'Chavacano de Zamboanga', # Zamboanga Chavacano, T124657
	'ccp' => '𑄌𑄋𑄴𑄟𑄳𑄦', # Chakma
	'cdo' => '閩東語 / Mìng-dĕ̤ng-ngṳ̄', # Mindong (multiple scripts - defaults to Latin)
	'cdo-hant' => '閩東語（傳統漢字）', # Mindong (Traditional Han script)
	'cdo-latn' => 'Mìng-dĕ̤ng-ngṳ̄ (Bàng-uâ-cê)', # Mindong (Latin script)
	'ce' => 'нохчийн', # Chechen
	'ceb' => 'Cebuano', # Cebuano
	'ch' => 'Chamoru', # Chamorro
	'chn' => 'chinuk wawa', # Chinook Jargon
	'cho' => 'Chahta anumpa', # Choctaw
	'chr' => 'ᏣᎳᎩ', # Cherokee
	'chy' => 'Tsetsêhestâhese', # Cheyenne
	'ckb' => 'کوردی', # Central Kurdish
	'co' => 'corsu', # Corsican
	'cop' => 'ϯⲙⲉⲧⲣⲉⲙⲛ̀ⲭⲏⲙⲓ', # Coptic
	'cps' => 'Capiceño', # Capiznon
	'cpx' => '莆仙語 / Pó-sing-gṳ̂', # Puxian (multiple scripts - defaults to Traditional Han)
	'cpx-hans' => '莆仙语（简体）', # Puxian (Simplified Han script)
	'cpx-hant' => '莆仙語（繁體）', # Puxian (Traditional Han script)
	'cpx-latn' => 'Pó-sing-gṳ̂ (Báⁿ-uā-ci̍)', # Puxian (Latin script)
	'cr' => 'Nēhiyawēwin / ᓀᐦᐃᔭᐍᐏᐣ', # Cree
	'crh' => 'qırımtatarca', # Crimean Tatar (multiple scripts - defaults to Latin)
	'crh-cyrl' => 'къырымтатарджа (Кирилл)', # Crimean Tatar (Cyrillic)
	'crh-latn' => 'qırımtatarca (Latin)', # Crimean Tatar (Latin)
	'crh-ro' => 'tatarşa', # Crimean Tatar (Romania)
	'cs' => 'čeština', # Czech
	'csb' => 'kaszëbsczi', # Cassubian
	'cu' => 'словѣньскъ / ⰔⰎⰑⰂⰡⰐⰠⰔⰍⰟ', # Old Church Slavonic (ancient language)
	'cv' => 'чӑвашла', # Chuvash
	'cy' => 'Cymraeg', # Welsh
	'da' => 'dansk', # Danish
	'dag' => 'dagbanli', # Dagbani
	'de' => 'Deutsch', # German ("Du")
	'de-at' => 'Österreichisches Deutsch', # Austrian German
	'de-ch' => 'Schweizer Hochdeutsch', # Swiss Standard German
	'de-formal' => 'Deutsch (Sie-Form)', # German - formal address ("Sie")
	'dga' => 'Dagaare', # Southern Dagaare
	'din' => 'Thuɔŋjäŋ', # Dinka
	'diq' => 'Zazaki', # Zazaki
	'dlg' => 'долган тыла', # Dolgan
	'dsb' => 'dolnoserbski', # Lower Sorbian
	'dtp' => 'Kadazandusun', # Central Dusun
	'dty' => 'डोटेली', # Doteli
	'dua' => 'Duálá', # Duala
	'dv' => 'ދިވެހިބަސް', # Dhivehi
	'dz' => 'ཇོང་ཁ', # Dzongkha (Bhutan)
	'ee' => 'eʋegbe', # Éwé
	'efi' => 'Efịk', # Efik
	'egl' => 'Emiliàn', # Emilian
	'el' => 'Ελληνικά', # Greek
	'eml' => 'emiliàn e rumagnòl', # Emiliano-Romagnolo / Sammarinese
	'en' => 'English', # English
	'en-ca' => 'Canadian English', # Canadian English
	'en-gb' => 'British English', # British English
	'en-x-piglatin' => 'Igpay Atinlay', # Pig Latin, for variant development
	'eo' => 'Esperanto', # Esperanto
	'es' => 'español', # Spanish
	'es-419' => 'español de América Latina', # Spanish for the Latin America and Caribbean region
	'es-formal' => 'español (formal)', # Spanish formal address
	'et' => 'eesti', # Estonian
	'eu' => 'euskara', # Basque
	'ext' => 'estremeñu', # Extremaduran
	'fa' => 'فارسی', # Persian
	'fat' => 'mfantse', # Fante
	'ff' => 'Fulfulde', # Fulfulde, Maasina
	'fi' => 'suomi', # Finnish
	'fit' => 'meänkieli', # Tornedalen Finnish
	'fiu-vro' => 'võro', # Võro (deprecated code, 'vro' in ISO 639-3 since 2009-01-16)
	'fj' => 'Na Vosa Vakaviti', # Fijian
	'fo' => 'føroyskt', # Faroese
	'fon' => 'fɔ̀ngbè', # Fon
	'fr' => 'français', # French
	'frc' => 'français cadien', # Cajun French
	'frp' => 'arpetan', # Franco-Provençal/Arpitan
	'frr' => 'Nordfriisk', # North Frisian
	'fur' => 'furlan', # Friulian
	'fvr' => 'poor’íŋ belé’ŋ', # Fur
	'fy' => 'Frysk', # Frisian
	'ga' => 'Gaeilge', # Irish
	'gaa' => 'Ga', # Ga
	'gag' => 'Gagauz', # Gagauz
	'gan' => '贛語', # Gan (multiple scripts - defaults to Traditional Han)
	'gan-hans' => '赣语（简体）', # Gan (Simplified Han)
	'gan-hant' => '贛語（繁體）', # Gan (Traditional Han)
	'gcf' => 'kréyòl Gwadloup', # Guadeloupean Creole
	'gcr' => 'kriyòl gwiyannen', # Guianan Creole
	'gd' => 'Gàidhlig', # Scots Gaelic
	'gl' => 'galego', # Galician
	'gld' => 'на̄ни', # Nanai
	'glk' => 'گیلکی', # Gilaki
	'gn' => 'Avañe\'ẽ', # Guaraní, Paraguayan
	'gom' => 'गोंयची कोंकणी / Gõychi Konknni', # Goan Konkani
	'gom-deva' => 'गोंयची कोंकणी', # Goan Konkani (Devanagari script)
	'gom-latn' => 'Gõychi Konknni', # Goan Konkani (Latin script)
	'gor' => 'Bahasa Hulontalo', # Gorontalo
	'got' => '𐌲𐌿𐍄𐌹𐍃𐌺', # Gothic
	'gpe' => 'Ghanaian Pidgin', # Ghanaian Pidgin
	'grc' => 'Ἀρχαία ἑλληνικὴ', # Ancient Greek
	'gsw' => 'Alemannisch', # Alemannic
	'gu' => 'ગુજરાતી', # Gujarati
	'guc' => 'wayuunaiki', # Wayuu
	'gur' => 'farefare', # Farefare
	'guw' => 'gungbe', # Gun
	'gv' => 'Gaelg', # Manx
	'ha' => 'Hausa', # Hausa
	'hak' => '客家語 / Hak-kâ-ngî', # Hakka (multiple scripts)
	'hak-hans' => '客家语（简体）', # Hakka (Simplified Han script)
	'hak-hant' => '客家語（繁體）', # Hakka (Traditional Han script)
	'hak-latn' => 'Hak-kâ-ngî (Pha̍k-fa-sṳ)', # Hakka (Latin script)
	'haw' => 'Hawaiʻi', # Hawaiian
	'he' => 'עברית', # Hebrew
	'hi' => 'हिन्दी', # Hindi
	'hif' => 'Fiji Hindi', # Fijian Hindi (multiple scripts - defaults to Latin)
	'hif-latn' => 'Fiji Hindi', # Fiji Hindi (Latin script)
	'hil' => 'Ilonggo', # Hiligaynon
	'hke' => 'kihunde', # Hunde
	'hno' => 'ہندکو', # Hindko
	'ho' => 'Hiri Motu', # Hiri Motu
	'hoc-latn' => 'Ho', # Ho (Latin script), T393086
	'hr' => 'hrvatski', # Croatian
	'hrx' => 'Hunsrik', # Riograndenser Hunsrückisch
	'hsb' => 'hornjoserbsce', # Upper Sorbian
	'hsn' => '湘語', # Xiang
	'ht' => 'Kreyòl ayisyen', # Haitian Creole French
	'hu' => 'magyar', # Hungarian
	'hu-formal' => 'magyar (formal)', # Hungarian formal address
	'hy' => 'հայերեն', # Armenian, T202611
	'hyw' => 'Արեւմտահայերէն', # Western Armenian, T201276, T219975
	'hz' => 'Otsiherero', # Herero
	'ia' => 'interlingua', # Interlingua (IALA)
	'iba' => 'Jaku Iban', # Iban
	'ibb' => 'ibibio', # Ibibio
	'id' => 'Bahasa Indonesia', # Indonesian
	'ie' => 'Interlingue', # Interlingue (Occidental)
	'ig' => 'Igbo', # Igbo
	'igl' => 'Igala', # Igala
	'ii' => 'ꆇꉙ', # Sichuan Yi
	'ik' => 'Iñupiatun', # Inupiaq
	'ike-cans' => 'ᐃᓄᒃᑎᑐᑦ', # Inuktitut, Eastern Canadian (Unified Canadian Aboriginal Syllabics)
	'ike-latn' => 'inuktitut', # Inuktitut, Eastern Canadian (Latin script)
	'ilo' => 'Ilokano', # Ilokano
	'inh' => 'гӀалгӀай', # Ingush
	'io' => 'Ido', # Ido
	'is' => 'íslenska', # Icelandic
	'isv' => 'medžuslovjansky', # Interslavic
	'isv-cyrl' => 'меджусловјанскы', # Interslavic (Cyrillic)
	'isv-latn' => 'medžuslovjansky', # Interslavic (Latin)
	'it' => 'italiano', # Italian
	'iu' => 'ᐃᓄᒃᑎᑐᑦ / inuktitut', # Inuktitut (macro language, see ike/ikt, falls back to ike-cans)
	'ja' => '日本語', # Japanese
	'jam' => 'Patois', # Jamaican Creole English
	'jbo' => 'la .lojban.', # Lojban
	'jut' => 'jysk', # Jutish / Jutlandic
	'jv' => 'Jawa', # Javanese
	'jv-java' => 'ꦗꦮ', # Javanese (Javanese script)
	'ka' => 'ქართული', # Georgian
	'kaa' => 'Qaraqalpaqsha', # Karakalpak
	'kab' => 'Taqbaylit', # Kabyle
	'kai' => 'Karai-karai', # Karekare
	'kaj' => 'Jju', # Jju
	'kbd' => 'адыгэбзэ', # Kabardian
	'kbd-cyrl' => 'адыгэбзэ', # Kabardian (Cyrillic)
	'kbp' => 'Kabɩyɛ', # Kabiyè
	'kcg' => 'Tyap', # Tyap
	'kea' => 'kabuverdianu', # Cape Verdean Creole
	'kg' => 'Kongo', # Kongo, (FIXME!) should probably be KiKongo or KiKoongo
	'kge' => 'Kumoring', # Komering
	'khw' => 'کھوار', # Khowar
	'ki' => 'Gĩkũyũ', # Gikuyu
	'kiu' => 'Kırmancki', # Kirmanjki
	'kj' => 'Kwanyama', # Kwanyama
	'kjh' => 'хакас', # Khakas
	'kjp' => 'ဖၠုံလိက်', # Eastern Pwo
	'kk' => 'қазақша', # Kazakh (multiple scripts - defaults to Cyrillic)
	'kk-arab' => 'قازاقشا (تٴوتە)', # Kazakh Arabic
	'kk-cn' => 'قازاقشا (جۇنگو)', # Kazakh (China)
	'kk-cyrl' => 'қазақша (кирил)', # Kazakh Cyrillic
	'kk-kz' => 'қазақша (Қазақстан)', # Kazakh (Kazakhstan)
	'kk-latn' => 'qazaqşa (latın)', # Kazakh Latin
	'kk-tr' => 'qazaqşa (Türkïya)', # Kazakh (Turkey)
	'kl' => 'kalaallisut', # Inuktitut, Greenlandic/Greenlandic/Kalaallisut (kal)
	'km' => 'ភាសាខ្មែរ', # Khmer, Central
	'kn' => 'ಕನ್ನಡ', # Kannada
	'knc' => 'Yerwa Kanuri', # Central Kanuri
	'ko' => '한국어', # Korean
	'ko-kp' => '조선말', # Korean (DPRK), T190324
	'koi' => 'перем коми', # Komi-Permyak
	'kr' => 'kanuri', # Kanuri; deprecated, falls back to Central Kanuri (knc)
	'krc' => 'къарачай-малкъар', # Karachay-Balkar
	'kri' => 'Krio', # Krio
	'krj' => 'Kinaray-a', # Kinaray-a
	'krl' => 'karjal', # Karelian
	'ks' => 'کٲشُر', # Kashmiri (defaults to Perso-Arabic script)
	# Backwards compatibility
	'ks-arab' => 'کٲشُر', # Kashmiri (Perso-Arabic script)
	# Backwards compatibility, deprecated, to be removed
	'ks-deva' => 'कॉशुर', # Kashmiri (Devanagari script)
	'ksh' => 'Ripoarisch', # Ripuarian
	'ksw' => 'စှီၤ', # S'gaw Karen
	'ku' => 'kurdî', # Kurdish (multiple scripts - defaults to Latin)
	'ku-arab' => 'کوردی (عەرەبی)', # Northern Kurdish (Arabic script) (falls back to ckb; see also T368698)
	'ku-latn' => 'kurdî (latînî)', # Northern Kurdish (Latin script)
	'kum' => 'къумукъ', # Kumyk (Cyrillic, 'kum-latn' for Latin script)
	'kus' => 'Kʋsaal', # Kusaal
	'kv' => 'коми', # Komi-Zyrian (Cyrillic is common script but also written in Latin script)
	'kw' => 'kernowek', # Cornish
	'ky' => 'кыргызча', # Kirghiz
	'la' => 'Latina', # Latin
	'lad' => 'Ladino', # Ladino
	'lb' => 'Lëtzebuergesch', # Luxembourgish
	'lbe' => 'лакку', # Lak
	'lez' => 'лезги', # Lezgi
	'lfn' => 'Lingua Franca Nova', # Lingua Franca Nova
	'lg' => 'Luganda', # Ganda
	'li' => 'Limburgs', # Limburgian
	'lij' => 'Ligure', # Ligurian
	'liv' => 'Līvõ kēļ', # Livonian
	'ljp' => 'Lampung Api', # Lampung Api
	'lki' => 'لەکی', # Laki
	'lkt' => 'Lakȟótiyapi', # Lakota
	'lld' => 'Ladin', # Ladin
	'lmo' => 'lombard', # Lombard - T283423
	'ln' => 'lingála', # Lingala
	'lo' => 'ລາວ', # Laotian
	'loz' => 'Silozi', # Lozi
	'lrc' => 'لۊری شومالی', # Northern Luri
	'lt' => 'lietuvių', # Lithuanian
	'ltg' => 'latgaļu', # Latgalian
	'lua' => 'ciluba', # Luba-Lulua
	'lus' => 'Mizo ţawng', # Mizo/Lushai
	'luz' => 'لئری دوٙمینی', # Southern Luri
	'lv' => 'latviešu', # Latvian
	'lzh' => '文言', # Literary Chinese, T10217
	'lzz' => 'Lazuri', # Laz
	'mad' => 'Madhurâ', # Madurese, T264582
	'mag' => 'मगही', # Magahi
	'mai' => 'मैथिली', # Maithili
	'map-bms' => 'Basa Banyumasan', # Banyumasan ('jv-x-bms')
	'mdf' => 'мокшень', # Moksha
	'mg' => 'Malagasy', # Malagasy
	'mh' => 'Ebon', # Marshallese
	'mhr' => 'олык марий', # Eastern Mari
	'mi' => 'Māori', # Maori
	'min' => 'Minangkabau', # Minangkabau
	'mk' => 'македонски', # Macedonian
	'ml' => 'മലയാളം', # Malayalam
	'mn' => 'монгол', # Halh Mongolian (Cyrillic) (ISO 639-3: khk)
	'mnc' => 'manju gisun', # Manchu (Latin script)
	'mnc-latn' => 'manju gisun', # Manchu (Latin script)
	'mnc-mong' => 'ᠮᠠᠨᠵᡠ ᡤᡳᠰᡠᠨ', # Manchu (Mongolian script)
	'mni' => 'ꯃꯤꯇꯩ ꯂꯣꯟ', # Manipuri/Meitei
	'mnw' => 'ဘာသာမန်', # Mon
	'mo' => 'молдовеняскэ', # Moldovan, deprecated (ISO 639-2: ro-Cyrl-MD)
	'mos' => 'moore', # Mooré
	'mr' => 'मराठी', # Marathi
	'mrh' => 'Mara', # Mara
	'mrj' => 'кырык мары', # Hill Mari
	'ms' => 'Bahasa Melayu', # Malay
	'ms-arab' => 'بهاس ملايو', # Malay (Arabic Jawi script)
	'mt' => 'Malti', # Maltese
	'mui' => 'Baso Palembang', # Musi/Palembang
	'mus' => 'Mvskoke', # Muskogee/Creek
	'mwl' => 'Mirandés', # Mirandese
	'my' => 'မြန်မာဘာသာ', # Burmese
	'myv' => 'эрзянь', # Erzya
	'mzn' => 'مازِرونی', # Mazanderani
	'na' => 'Dorerin Naoero', # Nauruan
	'nah' => 'Nāhuatl', # Nahuatl (added to ISO 639-3 on 2006-10-31)
	'nan' => '閩南語 / Bân-lâm-gí', # Minnan (multiple scripts), T10217, T354937
	'nan-hant' => '閩南語（傳統漢字）', # Minnan (Traditional Han script), T354937
	'nan-latn-pehoeji' => 'Bân-lâm-gí (Pe̍h-ōe-jī)', # Minnan (Pe̍h-ōe-jī), T354937
	'nan-latn-tailo' => 'Bân-lâm-gí (Tâi-lô)', # Minnan (Tâi-lô), T354937
	'nap' => 'Napulitano', # Neapolitan, T45793
	'nb' => 'norsk bokmål', # Norwegian (Bokmal)
	'nds' => 'Plattdüütsch', # Low German ''or'' Low Saxon
	'nds-nl' => 'Nedersaksies', # aka Nedersaksisch: Dutch Low Saxon
	'ne' => 'नेपाली', # Nepali
	'new' => 'नेपाल भाषा', # Newar / Nepal Bhasha
	'ng' => 'Oshiwambo', # Ndonga
	'nia' => 'Li Niha', # Nias, T263968
	'nit' => 'కొలామి', # Southeastern Kolami
	'niu' => 'Niuē', # Niuean
	'nl' => 'Nederlands', # Dutch
	'nl-informal' => 'Nederlands (informeel)', # Dutch (informal address ("je"))
	'nmz' => 'nawdm', # Nawdm
	'nn' => 'norsk nynorsk', # Norwegian (Nynorsk)
	'no' => 'norsk', # Norwegian macro language (falls back to nb).
	'nod' => 'ᨣᩤᩴᨾᩮᩬᩥᨦ', # Northern Thai
	'nog' => 'ногайша', # Nogai
	'nov' => 'Novial', # Novial
	'nqo' => 'ߒߞߏ', # N'Ko
	'nr' => 'isiNdebele seSewula', # Southern Ndebele
	'nrm' => 'Nouormand', # Norman (invalid code; 'nrf' in ISO 639 since 2014)
	'nso' => 'Sesotho sa Leboa', # Northern Sotho
	'nup' => 'Nupe', # Nupe
	'nv' => 'Diné bizaad', # Navajo
	'ny' => 'Chi-Chewa', # Chichewa
	'nyn' => 'runyankore', # Nkore
	'nyo' => 'Orunyoro', # Nyoro
	'nys' => 'Nyunga', # Nyungar
	'oc' => 'occitan', # Occitan
	'ojb' => 'Ojibwemowin', # Ojibwe
	'olo' => 'livvinkarjala', # Livvi-Karelian
	'om' => 'Oromoo', # Oromo
	'or' => 'ଓଡ଼ିଆ', # Oriya
	'os' => 'ирон', # Ossetic, T31091
	'pa' => 'ਪੰਜਾਬੀ', # Eastern Punjabi (Gurmukhi script) (pan)
	'pag' => 'Pangasinan', # Pangasinan
	'pam' => 'Kapampangan', # Pampanga
	'pap' => 'Papiamentu', # Papiamentu
	'pap-aw' => 'Papiamento (Aruba)', # Papiamento (Aruba), T387000
	'pcd' => 'Picard', # Picard
	'pcm' => 'Naijá', # Nigerian Pidgin
	'pdc' => 'Deitsch', # Pennsylvania German
	'pdt' => 'Plautdietsch', # Plautdietsch/Mennonite Low German
	'pfl' => 'Pälzisch', # Palatinate German
	'pi' => 'पालि', # Pali
	'pih' => 'Norfuk / Pitkern', # Norfuk/Pitcairn/Norfolk
	'pl' => 'polski', # Polish
	'pms' => 'Piemontèis', # Piedmontese
	'pnb' => 'پنجابی', # Western Punjabi
	'pnt' => 'Ποντιακά', # Pontic/Pontic Greek
	'ppl' => 'Nawat', # Nawat
	'prg' => 'prūsiskan', # Prussian
	'ps' => 'پښتو', # Pashto
	'pt' => 'português', # Portuguese
	'pt-br' => 'português do Brasil', # Brazilian Portuguese
	'pwn' => 'pinayuanan', # Paiwan
	'qu' => 'Runa Simi', # Southern Quechua
	'qug' => 'Runa shimi', # Kichwa/Northern Quechua (temporarily used until Kichwa has its own)
	'rgn' => 'Rumagnôl', # Romagnol
	'rif' => 'Tarifit', # Tarifit
	'rki' => 'ရခိုင်', # Arakanese
	'rm' => 'rumantsch', # Raeto-Romance
	'rmc' => 'romaňi čhib', # Carpathian Romany
	'rmy' => 'romani čhib', # Vlax Romany
	'rn' => 'ikirundi', # Rundi (Kirundi)
	'ro' => 'română', # Romanian
	'roa-rup' => 'armãneashti', # Aromanian (deprecated code, 'rup' exists in ISO 639-3)
	'roa-tara' => 'tarandíne', # Tarantino ('nap-x-tara')
	'rsk' => 'руски', # Pannonian Rusyn
	'ru' => 'русский', # Russian
	'rue' => 'русиньскый', # Rusyn
	'rup' => 'armãneashti', # Aromanian
	'ruq' => 'Vlăheşte', # Megleno-Romanian (multiple scripts - defaults to Latin)
	'ruq-cyrl' => 'Влахесте', # Megleno-Romanian (Cyrillic script)
	'ruq-latn' => 'Vlăheşte', # Megleno-Romanian (Latin script)
	'rut' => 'мыхаӀбишды', # Rutul
	'rw' => 'Ikinyarwanda', # Kinyarwanda
	'ryu' => 'うちなーぐち', # Okinawan
	'sa' => 'संस्कृतम्', # Sanskrit
	'sah' => 'саха тыла', # Sakha
	'sas' => 'Sasak', # Sasak
	'sat' => 'ᱥᱟᱱᱛᱟᱲᱤ', # Santali
	'sc' => 'sardu', # Sardinian
	'scn' => 'sicilianu', # Sicilian
	'sco' => 'Scots', # Scots
	'sd' => 'سنڌي', # Sindhi
	'sdc' => 'Sassaresu', # Sassarese
	'sdh' => 'کوردی خوارگ', # Southern Kurdish
	'se' => 'davvisámegiella', # Northern Sami
	'se-fi' => 'davvisámegiella (Suoma bealde)', # Northern Sami (Finland)
	'se-no' => 'davvisámegiella (Norgga bealde)', # Northern Sami (Norway)
	'se-se' => 'davvisámegiella (Ruoŧa bealde)', # Northern Sami (Sweden)
	'sei' => 'Cmique Itom', # Seri
	'ses' => 'Koyraboro Senni', # Koyraboro Senni
	'sg' => 'Sängö', # Sango/Sangho
	'sgs' => 'žemaitėška', # Samogitian
	'sh' => 'srpskohrvatski / српскохрватски', # Serbo-Croatian (multiple scripts - defaults to Latin)
	'sh-cyrl' => 'српскохрватски (ћирилица)', # Serbo-Croatian (Cyrillic script)
	'sh-latn' => 'srpskohrvatski (latinica)', # Serbo-Croatian (Latin script) (default)
	'shi' => 'Taclḥit', # Tachelhit, Shilha (multiple scripts - defaults to Latin)
	'shi-latn' => 'Taclḥit', # Tachelhit (Latin script)
	'shi-tfng' => 'ⵜⴰⵛⵍⵃⵉⵜ', # Tachelhit (Tifinagh script)
	'shn' => 'တႆး', # Shan
	'shy' => 'tacawit', # Shawiya (Multiple scripts - defaults to Latin)
	'shy-latn' => 'tacawit', # Shawiya (Latin script) - T194047
	'si' => 'සිංහල', # Sinhalese
	'simple' => 'Simple English', # Simple English
	'sjd' => 'кӣллт са̄мь кӣлл', # Kildin Sami
	'sje' => 'bidumsámegiella', # Pite Sami
	'sk' => 'slovenčina', # Slovak
	'skr' => 'سرائیکی', # Saraiki (multiple scripts - defaults to Arabic)
	'skr-arab' => 'سرائیکی', # Saraiki (Arabic script)
	'sl' => 'slovenščina', # Slovenian
	'sli' => 'Schläsch', # Lower Silesian
	'sm' => 'Gagana Samoa', # Samoan
	'sma' => 'åarjelsaemien', # Southern Sami
	'smn' => 'anarâškielâ', # Inari Sami
	'sms' => 'nuõrttsääʹmǩiõll', # Skolt Sami
	'sn' => 'chiShona', # Shona
	'so' => 'Soomaaliga', # Somali
	'sq' => 'shqip', # Albanian
	'sr' => 'српски / srpski', # Serbian (multiple scripts - defaults to Cyrillic)
	'sr-ec' => 'српски (ћирилица)', # Serbian Cyrillic ekavian
	'sr-el' => 'srpski (latinica)', # Serbian Latin ekavian
	'srn' => 'Sranantongo', # Sranan Tongo
	'sro' => 'sardu campidanesu', # Campidanese Sardinian
	'ss' => 'SiSwati', # Swati
	'st' => 'Sesotho', # Southern Sotho
	'stq' => 'Seeltersk', # Saterland Frisian
	'sty' => 'себертатар', # Siberian Tatar
	'su' => 'Sunda', # Sundanese
	'sv' => 'svenska', # Swedish
	'sw' => 'Kiswahili', # Swahili
	'syl' => 'ꠍꠤꠟꠐꠤ', # Sylheti
	'szl' => 'ślůnski', # Silesian
	'szy' => 'Sakizaya', # Sakizaya - T174601
	'ta' => 'தமிழ்', # Tamil
	'tay' => 'Tayal', # Atayal
	'tcy' => 'ತುಳು', # Tulu
	'tdd' => 'ᥖᥭᥰ ᥖᥬᥲ ᥑᥨᥒᥰ', # Tai Nüa
	'te' => 'తెలుగు', # Telugu
	'tet' => 'tetun', # Tetun
	'tg' => 'тоҷикӣ', # Tajiki (falls back to tg-cyrl)
	'tg-cyrl' => 'тоҷикӣ', # Tajiki (Cyrllic script) (default)
	'tg-latn' => 'tojikī', # Tajiki (Latin script)
	'th' => 'ไทย', # Thai
	'ti' => 'ትግርኛ', # Tigrinya
	'tig' => 'ትግሬ', # Tigre
	'tk' => 'Türkmençe', # Turkmen
	'tl' => 'Tagalog', # Tagalog
	'tly' => 'tolışi', # Talysh
	'tly-cyrl' => 'толыши', # Talysh (Cyrillic)
	'tn' => 'Setswana', # Setswana
	'to' => 'lea faka-Tonga', # Tonga (Tonga Islands)
	'tok' => 'toki pona', # Toki Pona
	'tpi' => 'Tok Pisin', # Tok Pisin
	'tr' => 'Türkçe', # Turkish
	'tru' => 'Ṫuroyo', # Turoyo
	'trv' => 'Seediq', # Taroko
	'ts' => 'Xitsonga', # Tsonga
	'tt' => 'татарча / tatarça', # Tatar (multiple scripts - defaults to Cyrillic)
	'tt-cyrl' => 'татарча', # Tatar (Cyrillic script) (default)
	'tt-latn' => 'tatarça', # Tatar (Latin script)
	'ttj' => 'Orutooro', # Tooro
	'tum' => 'chiTumbuka', # Tumbuka
	'tw' => 'Twi', # Twi
	'ty' => 'reo tahiti', # Tahitian
	'tyv' => 'тыва дыл', # Tyvan
	'tzm' => 'ⵜⴰⵎⴰⵣⵉⵖⵜ', # Tamazight
	'udm' => 'удмурт', # Udmurt
	'ug' => 'ئۇيغۇرچە / Uyghurche', # Uyghur (multiple scripts - defaults to Arabic)
	'ug-arab' => 'ئۇيغۇرچە', # Uyghur (Arabic script) (default)
	'ug-latn' => 'Uyghurche', # Uyghur (Latin script)
	'uk' => 'українська', # Ukrainian
	'ur' => 'اردو', # Urdu
	'uz' => 'oʻzbekcha / ўзбекча', # Uzbek (multiple scripts - defaults to Latin)
	'uz-cyrl' => 'ўзбекча', # Uzbek Cyrillic
	'uz-latn' => 'oʻzbekcha', # Uzbek Latin (default)
	've' => 'Tshivenda', # Venda
	'vec' => 'vèneto', # Venetian
	'vep' => 'vepsän kel’', # Veps
	'vi' => 'Tiếng Việt', # Vietnamese
	'vls' => 'West-Vlams', # West Flemish
	'vmf' => 'Mainfränkisch', # Upper Franconian, Main-Franconian
	'vmw' => 'emakhuwa', # Makhuwa
	'vo' => 'Volapük', # Volapük
	'vot' => 'Vaďďa', # Vod/Votian
	'vro' => 'võro', # Võro
	'wa' => 'walon', # Walloon
	'wal' => 'wolaytta', # Wolaytta
	'war' => 'Winaray', # Waray-Waray
	'wls' => 'Fakaʻuvea', # Wallisian
	'wlx' => 'waale', # Wali
	'wo' => 'Wolof', # Wolof
	'wuu' => '吴语', # Wu (multiple scripts - defaults to Simplified Han)
	'wuu-hans' => '吴语（简体）', # Wu (Simplified Han)
	'wuu-hant' => '吳語（正體）', # Wu (Traditional Han)
	'xal' => 'хальмг', # Kalmyk-Oirat
	'xh' => 'isiXhosa', # Xhosan
	'xmf' => 'მარგალური', # Mingrelian
	'xsy' => 'saisiyat', # SaiSiyat - T216479
	'yi' => 'ייִדיש', # Yiddish
	'yo' => 'Yorùbá', # Yoruba
	'yrl' => 'Nhẽẽgatú', # Nheengatu
	'yua' => 'maaya t’aan', # Yucatec Maya
	'yue' => '粵語', # Cantonese (multiple scripts - defaults to Traditional Han)
	'yue-hans' => '粵语（简体）', # Cantonese (Simplified Han)
	'yue-hant' => '粵語（繁體）', # Cantonese (Traditional Han)
	'za' => 'Vahcuengh', # Zhuang
	'zea' => 'Zeêuws', # Zeeuws / Zeaws
	'zgh' => 'ⵜⴰⵎⴰⵣⵉⵖⵜ ⵜⴰⵏⴰⵡⴰⵢⵜ', # Moroccan Amazigh (multiple scripts - defaults to Neo-Tifinagh)
	'zgh-latn' => 'tamaziɣt tanawayt', # Moroccan Amazigh (Latin script)
	'zh' => '中文', # (Zhōng Wén) - Chinese
	'zh-classical' => '文言', # Classical Chinese/Literary Chinese -- (see T10217)
	'zh-cn' => '中文（中国大陆）', # Chinese (PRC)
	'zh-hans' => '中文（简体）', # Mandarin Chinese (Simplified Chinese script) (cmn-hans)
	'zh-hant' => '中文（繁體）', # Mandarin Chinese (Traditional Chinese script) (cmn-hant)
	'zh-hk' => '中文（香港）', # Chinese (Hong Kong)
	'zh-min-nan' => 'Bân-lâm-gú', # Min-nan -- (see T10217)
	'zh-mo' => '中文（澳門）', # Chinese (Macau)
	'zh-my' => '中文（马来西亚）', # Chinese (Malaysia)
	'zh-sg' => '中文（新加坡）', # Chinese (Singapore)
	'zh-tw' => '中文（臺灣）', # Chinese (Taiwan)
	'zh-yue' => '粵語', # Cantonese -- (see T10217)
	'zu' => 'isiZulu', # Zulu

	# Codes from https://github.com/wikimedia/mediawiki-extensions-Wikibase/blob/master/lib/includes/WikibaseContentLanguages.php
	# TODO Native names.
	# Updated 2025-01-01 from mediawiki-extensions-Wikibase/lib/includes/WikibaseContentLanguages.php, commit 1e626b913d5d8a28cb719a55baba4fdaa3324221
	'agq' => 'Aghem', # Aghem - T288335
	'bag' => 'Tuki', # Tuki - T263946
	'bas' => 'Basaa', # Basaa - T263946
	'bax' => 'Bamum', # Bamum - T263946
	'bbj' => "Ghomála'", # Ghomála' - T263946
	'bfd' => 'Bafut', # Bafut - T263946
	'bkc' => 'Baka', # Baka - T263946
	'bkh' => 'Bakoko', # Bakoko - T263946
	'bkm' => 'Kom', # Kom - T263946
	'bqz' => "Mka'a", # Mka'a - T263946
	'byv' => 'Medumba', # Medumba - T263946
	'cak' => 'Cakchiquel', # Cakchiquel - T278854
	'cal' => 'Carolinian', # Carolinian - T308062
	'cnh' => 'Chin', # Chin - T263946
	'dua' => 'Duala', # Duala - T263946
	'en-us' => 'American English', # American English - T154589
	'eto' => 'Eton', # Eton - T263946
	'etu' => 'Ejagham', # Ejagham - T263946
	'ewo' => 'Ewondo', # Ewondo - T263946
	'fkv' => 'Finnish (Kven)', # Finnish (Kven) - T167259
	'fmp' => "Fe'fe'", # Fe'fe' - T263946
	'gya' => 'Gbaya', # Gbaya - T263946
	'isu' => 'Isu', # Isu - T263946
	'kea' => 'Kabuverdianu', # Kabuverdianu - T127435
	'ker' => 'Kera', # Kera - T263946
	'ksf' => 'Bafia', # Bafia - T263946
	'lem' => 'Nomaande', # Nomaande - T263946
	'lns' => "Lamnso'", # Lamnso' - T263946
	'mcn' => 'Masana', # Masana - T293884
	'mcp' => 'Maka', # Maka - T263946
	'mua' => 'Mundang', # Mundang - T263946
	'nan-hani' => 'Min Nan Chinese', # Min Nan Chinese - T180771
	'nge' => 'Ngémba', # Ngémba - T263946
	'nla' => 'Ngombala', # Ngombala - T263946
	'nmg' => 'Kwasio', # Kwasio - T263946
	'nnh' => 'Ngiemboon', # Ngiemboon - T263946
	'nnz' => "Nda'nda'", # Nda'nda' - T263946
	'nod' => 'Thai (Northern)', # Thai (Northern) - T93880
	'osa-latn' => 'Osage', # Osage - T265297
	'ota' => 'Turkish, Ottoman (1500–1928)', # Turkish, Ottoman (1500–1928) - T59342
	'pap-aw' => 'Papiamento', # Papiamento - T275682
	'quc' => 'K’iche’', # K’iche’ - T278851
	'rmf' => 'Romani, Kalo Finnish', # Romani, Kalo Finnish - T226701
	'rwr' => 'Marwari', # Marwari - T61905
	'ryu' => 'Okinawan, Central', # Okinawan, Central - T271215
	'sjd' => 'Sami, Kildin', # Sami, Kildin - T226701
	'sju' => 'Sami, Ume', # Sami, Ume - T226701
	'smj' => 'Lule Sámi', # Lule Sámi - T146707
	'sms' => 'Skolt Sami', # Skolt Sami - T220118, T223544
	'srq' => 'Sirionó', # Sirionó - T113408
	'tpv' => 'Tanapag', # Tanapag - T308062
	'tvu' => 'Tunen', # Tunen - T263946
	'vut' => 'Vute', # Vute - T263946
	'wes' => 'Pidgin (Cameroon)', # Pidgin (Cameroon) - T263946
	'wya' => 'Wyandot', # Wyandot - T283364
	'yas' => 'Nugunu', # Nugunu - T263946
	'yat' => 'Yambeta', # Yambeta - T263946
	'yav' => 'Yangben', # Yangben - T263946
	'ybb' => 'Yemba', # Yemba - T263946

	# Other, used in Q111803082
	'ak' => 'Akan',
	# Other, used in Q3286974
	'fr-ca' => 'Canadian French',
);
Readonly::Hash our %LANGUAGES => (
	%TERM_LANGUAGES,

	# Special codes.
	'mis' => 'language without a specific language code', # Q22283016
	'und' => 'undetermined language', # Q22282914
	'zxx' => 'no linguistic content', # Q22282939
);

our $VERSION = 0.40;

sub all_language_codes {
	return keys %LANGUAGES;
}

sub all_term_language_codes {
	return keys %TERM_LANGUAGES;
}

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Languages - Wikibase datatype languages.

=head1 SYNOPSIS

 use Wikibase::Datatype::Languages qw(all_language_codes);

 my @language_codes = all_language_codes();
 my @term_language_codes = all_term_language_codes();

=head1 DESCRIPTION

Language codes used for multilingual information in Wikibase::Datatype objects.

It's imported from L<https://doc.wikimedia.org/mediawiki-core/master/php/Names_8php_source.html>
and from L<https://github.com/wikimedia/mediawiki-extensions-Wikibase/blob/master/lib/includes/WikibaseContentLanguages.php> (2023-04-22).

=head1 SUBROUTINES

=head2 C<all_language_codes>

 my @language_codes = all_language_codes();

Get language codes used in MediaWiki.

Returns array with codes.

=head2 C<all_term_language_codes>

 my @term_language_codes = all_term_language_codes();

Get language codes used in Wikibase for terms (label, description and alias).

Returns array with codes.

=head1 EXAMPLE1

=for comment filename=all_language_codes.pl

 use strict;
 use warnings;

 use Wikibase::Datatype::Languages qw(all_language_codes);

 my @language_codes = sort { $a cmp $b } all_language_codes();

 # Print out.
 print join "\n", @language_codes;
 print "\n";

 # Output:
 # aa
 # aae
 # ab
 # abr
 # abs
 # ace
 # acf
 # acm
 # ady
 # ady-cyrl
 # aeb
 # aeb-arab
 # aeb-latn
 # af
 # agq
 # aig
 # ak
 # aln
 # als
 # alt
 # am
 # ami
 # an
 # ang
 # ann
 # anp
 # apc
 # ar
 # arc
 # arn
 # arq
 # ary
 # arz
 # as
 # ase
 # ast
 # atj
 # av
 # avk
 # awa
 # ay
 # az
 # azb
 # ba
 # bag
 # ban
 # ban-bali
 # bar
 # bas
 # bat-smg
 # bax
 # bbc
 # bbc-latn
 # bbj
 # bcc
 # bci
 # bcl
 # bdr
 # be
 # be-tarask
 # be-x-old
 # bew
 # bfd
 # bg
 # bgc
 # bgn
 # bh
 # bho
 # bi
 # bjn
 # bkc
 # bkh
 # bkm
 # blk
 # bm
 # bn
 # bo
 # bol
 # bpy
 # bqi
 # bqz
 # br
 # brh
 # bs
 # btm
 # bto
 # bug
 # bug-bugi
 # bxr
 # byv
 # ca
 # cak
 # cal
 # cbk-zam
 # ccp
 # cdo
 # cdo-hant
 # cdo-latn
 # ce
 # ceb
 # ch
 # chn
 # cho
 # chr
 # chy
 # ckb
 # cnh
 # co
 # cop
 # cps
 # cpx
 # cpx-hans
 # cpx-hant
 # cpx-latn
 # cr
 # crh
 # crh-cyrl
 # crh-latn
 # crh-ro
 # cs
 # csb
 # cu
 # cv
 # cy
 # da
 # dag
 # de
 # de-at
 # de-ch
 # de-formal
 # dga
 # din
 # diq
 # dlg
 # dsb
 # dtp
 # dty
 # dua
 # dv
 # dz
 # ee
 # efi
 # egl
 # el
 # eml
 # en
 # en-ca
 # en-gb
 # en-us
 # en-x-piglatin
 # eo
 # es
 # es-419
 # es-formal
 # et
 # eto
 # etu
 # eu
 # ewo
 # ext
 # fa
 # fat
 # ff
 # fi
 # fit
 # fiu-vro
 # fj
 # fkv
 # fmp
 # fo
 # fon
 # fr
 # fr-ca
 # frc
 # frp
 # frr
 # fur
 # fvr
 # fy
 # ga
 # gaa
 # gag
 # gan
 # gan-hans
 # gan-hant
 # gcf
 # gcr
 # gd
 # gl
 # gld
 # glk
 # gn
 # gom
 # gom-deva
 # gom-latn
 # gor
 # got
 # gpe
 # grc
 # gsw
 # gu
 # guc
 # gur
 # guw
 # gv
 # gya
 # ha
 # hak
 # hak-hans
 # hak-hant
 # hak-latn
 # haw
 # he
 # hi
 # hif
 # hif-latn
 # hil
 # hke
 # hno
 # ho
 # hoc-latn
 # hr
 # hrx
 # hsb
 # hsn
 # ht
 # hu
 # hu-formal
 # hy
 # hyw
 # hz
 # ia
 # iba
 # ibb
 # id
 # ie
 # ig
 # igl
 # ii
 # ik
 # ike-cans
 # ike-latn
 # ilo
 # inh
 # io
 # is
 # isu
 # isv
 # isv-cyrl
 # isv-latn
 # it
 # iu
 # ja
 # jam
 # jbo
 # jut
 # jv
 # jv-java
 # ka
 # kaa
 # kab
 # kai
 # kaj
 # kbd
 # kbd-cyrl
 # kbp
 # kcg
 # kea
 # ker
 # kg
 # kge
 # khw
 # ki
 # kiu
 # kj
 # kjh
 # kjp
 # kk
 # kk-arab
 # kk-cn
 # kk-cyrl
 # kk-kz
 # kk-latn
 # kk-tr
 # kl
 # km
 # kn
 # knc
 # ko
 # ko-kp
 # koi
 # kr
 # krc
 # kri
 # krj
 # krl
 # ks
 # ks-arab
 # ks-deva
 # ksf
 # ksh
 # ksw
 # ku
 # ku-arab
 # ku-latn
 # kum
 # kus
 # kv
 # kw
 # ky
 # la
 # lad
 # lb
 # lbe
 # lem
 # lez
 # lfn
 # lg
 # li
 # lij
 # liv
 # ljp
 # lki
 # lkt
 # lld
 # lmo
 # ln
 # lns
 # lo
 # loz
 # lrc
 # lt
 # ltg
 # lua
 # lus
 # luz
 # lv
 # lzh
 # lzz
 # mad
 # mag
 # mai
 # map-bms
 # mcn
 # mcp
 # mdf
 # mg
 # mh
 # mhr
 # mi
 # min
 # mis
 # mk
 # ml
 # mn
 # mnc
 # mnc-latn
 # mnc-mong
 # mni
 # mnw
 # mo
 # mos
 # mr
 # mrh
 # mrj
 # ms
 # ms-arab
 # mt
 # mua
 # mui
 # mul
 # mus
 # mwl
 # my
 # myv
 # mzn
 # na
 # nah
 # nan
 # nan-hani
 # nan-hant
 # nan-latn-pehoeji
 # nan-latn-tailo
 # nap
 # nb
 # nds
 # nds-nl
 # ne
 # new
 # ng
 # nge
 # nia
 # nit
 # niu
 # nl
 # nl-informal
 # nla
 # nmg
 # nmz
 # nn
 # nnh
 # nnz
 # no
 # nod
 # nog
 # nov
 # nqo
 # nr
 # nrm
 # nso
 # nup
 # nv
 # ny
 # nyn
 # nyo
 # nys
 # oc
 # ojb
 # olo
 # om
 # or
 # os
 # osa-latn
 # ota
 # pa
 # pag
 # pam
 # pap
 # pap-aw
 # pcd
 # pcm
 # pdc
 # pdt
 # pfl
 # pi
 # pih
 # pl
 # pms
 # pnb
 # pnt
 # ppl
 # prg
 # ps
 # pt
 # pt-br
 # pwn
 # qu
 # quc
 # qug
 # rgn
 # rif
 # rki
 # rm
 # rmc
 # rmf
 # rmy
 # rn
 # ro
 # roa-rup
 # roa-tara
 # rsk
 # ru
 # rue
 # rup
 # ruq
 # ruq-cyrl
 # ruq-latn
 # rut
 # rw
 # rwr
 # ryu
 # sa
 # sah
 # sas
 # sat
 # sc
 # scn
 # sco
 # sd
 # sdc
 # sdh
 # se
 # se-fi
 # se-no
 # se-se
 # sei
 # ses
 # sg
 # sgs
 # sh
 # sh-cyrl
 # sh-latn
 # shi
 # shi-latn
 # shi-tfng
 # shn
 # shy
 # shy-latn
 # si
 # simple
 # sjd
 # sje
 # sju
 # sk
 # skr
 # skr-arab
 # sl
 # sli
 # sm
 # sma
 # smj
 # smn
 # sms
 # sn
 # so
 # sq
 # sr
 # sr-ec
 # sr-el
 # srn
 # sro
 # srq
 # ss
 # st
 # stq
 # sty
 # su
 # sv
 # sw
 # syl
 # szl
 # szy
 # ta
 # tay
 # tcy
 # tdd
 # te
 # tet
 # tg
 # tg-cyrl
 # tg-latn
 # th
 # ti
 # tig
 # tk
 # tl
 # tly
 # tly-cyrl
 # tn
 # to
 # tok
 # tpi
 # tpv
 # tr
 # tru
 # trv
 # ts
 # tt
 # tt-cyrl
 # tt-latn
 # ttj
 # tum
 # tvu
 # tw
 # ty
 # tyv
 # tzm
 # udm
 # ug
 # ug-arab
 # ug-latn
 # uk
 # und
 # ur
 # uz
 # uz-cyrl
 # uz-latn
 # ve
 # vec
 # vep
 # vi
 # vls
 # vmf
 # vmw
 # vo
 # vot
 # vro
 # vut
 # wa
 # wal
 # war
 # wes
 # wls
 # wlx
 # wo
 # wuu
 # wuu-hans
 # wuu-hant
 # wya
 # xal
 # xh
 # xmf
 # xsy
 # yas
 # yat
 # yav
 # ybb
 # yi
 # yo
 # yrl
 # yua
 # yue
 # yue-hans
 # yue-hant
 # za
 # zea
 # zgh
 # zgh-latn
 # zh
 # zh-classical
 # zh-cn
 # zh-hans
 # zh-hant
 # zh-hk
 # zh-min-nan
 # zh-mo
 # zh-my
 # zh-sg
 # zh-tw
 # zh-yue
 # zu
 # zxx

=head1 EXAMPLE2

=for comment filename=all_term_language_codes.pl

 use strict;
 use warnings;

 use Wikibase::Datatype::Languages qw(all_term_language_codes);

 my @term_language_codes = sort { $a cmp $b } all_term_language_codes();

 # Print out.
 print join "\n", @term_language_codes;
 print "\n";

 # Output:
 # aa
 # aae
 # ab
 # abr
 # abs
 # ace
 # acf
 # acm
 # ady
 # ady-cyrl
 # aeb
 # aeb-arab
 # aeb-latn
 # af
 # agq
 # aig
 # ak
 # aln
 # als
 # alt
 # am
 # ami
 # an
 # ang
 # ann
 # anp
 # apc
 # ar
 # arc
 # arn
 # arq
 # ary
 # arz
 # as
 # ase
 # ast
 # atj
 # av
 # avk
 # awa
 # ay
 # az
 # azb
 # ba
 # bag
 # ban
 # ban-bali
 # bar
 # bas
 # bat-smg
 # bax
 # bbc
 # bbc-latn
 # bbj
 # bcc
 # bci
 # bcl
 # bdr
 # be
 # be-tarask
 # be-x-old
 # bew
 # bfd
 # bg
 # bgc
 # bgn
 # bh
 # bho
 # bi
 # bjn
 # bkc
 # bkh
 # bkm
 # blk
 # bm
 # bn
 # bo
 # bol
 # bpy
 # bqi
 # bqz
 # br
 # brh
 # bs
 # btm
 # bto
 # bug
 # bug-bugi
 # bxr
 # byv
 # ca
 # cak
 # cal
 # cbk-zam
 # ccp
 # cdo
 # cdo-hant
 # cdo-latn
 # ce
 # ceb
 # ch
 # chn
 # cho
 # chr
 # chy
 # ckb
 # cnh
 # co
 # cop
 # cps
 # cpx
 # cpx-hans
 # cpx-hant
 # cpx-latn
 # cr
 # crh
 # crh-cyrl
 # crh-latn
 # crh-ro
 # cs
 # csb
 # cu
 # cv
 # cy
 # da
 # dag
 # de
 # de-at
 # de-ch
 # de-formal
 # dga
 # din
 # diq
 # dlg
 # dsb
 # dtp
 # dty
 # dua
 # dv
 # dz
 # ee
 # efi
 # egl
 # el
 # eml
 # en
 # en-ca
 # en-gb
 # en-us
 # en-x-piglatin
 # eo
 # es
 # es-419
 # es-formal
 # et
 # eto
 # etu
 # eu
 # ewo
 # ext
 # fa
 # fat
 # ff
 # fi
 # fit
 # fiu-vro
 # fj
 # fkv
 # fmp
 # fo
 # fon
 # fr
 # fr-ca
 # frc
 # frp
 # frr
 # fur
 # fvr
 # fy
 # ga
 # gaa
 # gag
 # gan
 # gan-hans
 # gan-hant
 # gcf
 # gcr
 # gd
 # gl
 # gld
 # glk
 # gn
 # gom
 # gom-deva
 # gom-latn
 # gor
 # got
 # gpe
 # grc
 # gsw
 # gu
 # guc
 # gur
 # guw
 # gv
 # gya
 # ha
 # hak
 # hak-hans
 # hak-hant
 # hak-latn
 # haw
 # he
 # hi
 # hif
 # hif-latn
 # hil
 # hke
 # hno
 # ho
 # hoc-latn
 # hr
 # hrx
 # hsb
 # hsn
 # ht
 # hu
 # hu-formal
 # hy
 # hyw
 # hz
 # ia
 # iba
 # ibb
 # id
 # ie
 # ig
 # igl
 # ii
 # ik
 # ike-cans
 # ike-latn
 # ilo
 # inh
 # io
 # is
 # isu
 # isv
 # isv-cyrl
 # isv-latn
 # it
 # iu
 # ja
 # jam
 # jbo
 # jut
 # jv
 # jv-java
 # ka
 # kaa
 # kab
 # kai
 # kaj
 # kbd
 # kbd-cyrl
 # kbp
 # kcg
 # kea
 # ker
 # kg
 # kge
 # khw
 # ki
 # kiu
 # kj
 # kjh
 # kjp
 # kk
 # kk-arab
 # kk-cn
 # kk-cyrl
 # kk-kz
 # kk-latn
 # kk-tr
 # kl
 # km
 # kn
 # knc
 # ko
 # ko-kp
 # koi
 # kr
 # krc
 # kri
 # krj
 # krl
 # ks
 # ks-arab
 # ks-deva
 # ksf
 # ksh
 # ksw
 # ku
 # ku-arab
 # ku-latn
 # kum
 # kus
 # kv
 # kw
 # ky
 # la
 # lad
 # lb
 # lbe
 # lem
 # lez
 # lfn
 # lg
 # li
 # lij
 # liv
 # ljp
 # lki
 # lkt
 # lld
 # lmo
 # ln
 # lns
 # lo
 # loz
 # lrc
 # lt
 # ltg
 # lua
 # lus
 # luz
 # lv
 # lzh
 # lzz
 # mad
 # mag
 # mai
 # map-bms
 # mcn
 # mcp
 # mdf
 # mg
 # mh
 # mhr
 # mi
 # min
 # mk
 # ml
 # mn
 # mnc
 # mnc-latn
 # mnc-mong
 # mni
 # mnw
 # mo
 # mos
 # mr
 # mrh
 # mrj
 # ms
 # ms-arab
 # mt
 # mua
 # mui
 # mul
 # mus
 # mwl
 # my
 # myv
 # mzn
 # na
 # nah
 # nan
 # nan-hani
 # nan-hant
 # nan-latn-pehoeji
 # nan-latn-tailo
 # nap
 # nb
 # nds
 # nds-nl
 # ne
 # new
 # ng
 # nge
 # nia
 # nit
 # niu
 # nl
 # nl-informal
 # nla
 # nmg
 # nmz
 # nn
 # nnh
 # nnz
 # no
 # nod
 # nog
 # nov
 # nqo
 # nr
 # nrm
 # nso
 # nup
 # nv
 # ny
 # nyn
 # nyo
 # nys
 # oc
 # ojb
 # olo
 # om
 # or
 # os
 # osa-latn
 # ota
 # pa
 # pag
 # pam
 # pap
 # pap-aw
 # pcd
 # pcm
 # pdc
 # pdt
 # pfl
 # pi
 # pih
 # pl
 # pms
 # pnb
 # pnt
 # ppl
 # prg
 # ps
 # pt
 # pt-br
 # pwn
 # qu
 # quc
 # qug
 # rgn
 # rif
 # rki
 # rm
 # rmc
 # rmf
 # rmy
 # rn
 # ro
 # roa-rup
 # roa-tara
 # rsk
 # ru
 # rue
 # rup
 # ruq
 # ruq-cyrl
 # ruq-latn
 # rut
 # rw
 # rwr
 # ryu
 # sa
 # sah
 # sas
 # sat
 # sc
 # scn
 # sco
 # sd
 # sdc
 # sdh
 # se
 # se-fi
 # se-no
 # se-se
 # sei
 # ses
 # sg
 # sgs
 # sh
 # sh-cyrl
 # sh-latn
 # shi
 # shi-latn
 # shi-tfng
 # shn
 # shy
 # shy-latn
 # si
 # simple
 # sjd
 # sje
 # sju
 # sk
 # skr
 # skr-arab
 # sl
 # sli
 # sm
 # sma
 # smj
 # smn
 # sms
 # sn
 # so
 # sq
 # sr
 # sr-ec
 # sr-el
 # srn
 # sro
 # srq
 # ss
 # st
 # stq
 # sty
 # su
 # sv
 # sw
 # syl
 # szl
 # szy
 # ta
 # tay
 # tcy
 # tdd
 # te
 # tet
 # tg
 # tg-cyrl
 # tg-latn
 # th
 # ti
 # tig
 # tk
 # tl
 # tly
 # tly-cyrl
 # tn
 # to
 # tok
 # tpi
 # tpv
 # tr
 # tru
 # trv
 # ts
 # tt
 # tt-cyrl
 # tt-latn
 # ttj
 # tum
 # tvu
 # tw
 # ty
 # tyv
 # tzm
 # udm
 # ug
 # ug-arab
 # ug-latn
 # uk
 # ur
 # uz
 # uz-cyrl
 # uz-latn
 # ve
 # vec
 # vep
 # vi
 # vls
 # vmf
 # vmw
 # vo
 # vot
 # vro
 # vut
 # wa
 # wal
 # war
 # wes
 # wls
 # wlx
 # wo
 # wuu
 # wuu-hans
 # wuu-hant
 # wya
 # xal
 # xh
 # xmf
 # xsy
 # yas
 # yat
 # yav
 # ybb
 # yi
 # yo
 # yrl
 # yua
 # yue
 # yue-hans
 # yue-hant
 # za
 # zea
 # zgh
 # zgh-latn
 # zh
 # zh-classical
 # zh-cn
 # zh-hans
 # zh-hant
 # zh-hk
 # zh-min-nan
 # zh-mo
 # zh-my
 # zh-sg
 # zh-tw
 # zh-yue
 # zu

=head1 DEPENDENCIES

L<Exporter>,
L<Readonly>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Datatype>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2026 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.40

=cut
