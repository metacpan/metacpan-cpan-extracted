package Wikibase::Datatype::Languages;

use base qw(Exporter);
use strict;
use utf8;
use warnings;

use Readonly;

# Constants.
Readonly::Array our @EXPORT => qw(all_language_codes);
Readonly::Hash our %LANGUAGES => (

	# Special codes.
	'mul' => 'multiple languages', # Q20923490
	'mis' => 'language without a specific language code', # Q22283016
	'und' => 'undetermined language', # Q22282914
	'zxx' => 'no linguistic content', # Q22282939

	# Codes in https://doc.wikimedia.org/mediawiki-core/master/php/Names_8php_source.html
	# Updated 2023-04-22 in https://github.com/wikimedia/mediawiki/blob/dc1465a85944dfd7b98333d9061e0ba61e4af2da/includes/languages/data/Names.php
	'aa' => 'Qafár af', # Afar
	'ab' => 'аԥсшәа', # Abkhaz
	'abs' => 'bahasa ambon', # Ambonese Malay, T193566
	'ace' => 'Acèh', # Aceh
	'acm' => 'عراقي', # Iraqi (Mesopotamian) Arabic
	'ady' => 'адыгабзэ', # Adyghe
	'ady-cyrl' => 'адыгабзэ', # Adyghe
	'aeb' => 'تونسي / Tûnsî', # Tunisian Arabic (multiple scripts - defaults to Arabic)
	'aeb-arab' => 'تونسي', # Tunisian Arabic (Arabic Script)
	'aeb-latn' => 'Tûnsî', # Tunisian Arabic (Latin Script)
	'af' => 'Afrikaans', # Afrikaans
	'ak' => 'Akan', # Akan
	'aln' => 'Gegë', # Gheg Albanian
	'als' => 'Alemannisch', # Alemannic -- not a valid code, for compatibility. See gsw.
	'alt' => 'алтай тил', # Altai, T254854
	'am' => 'አማርኛ', # Amharic
	'ami' => 'Pangcah', # Amis
	'an' => 'aragonés', # Aragonese
	'ang' => 'Ænglisc', # Old English, T25283
	'ann' => 'Obolo', # Obolo
	'anp' => 'अंगिका', # Angika
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
	'be' => 'беларуская', # Belarusian normative
	'be-tarask' => 'беларуская (тарашкевіца)', # Belarusian in Taraskievica orthography
	'be-x-old' => 'беларуская (тарашкевіца)', # (be-tarask compat)
	'bg' => 'български', # Bulgarian
	'bgn' => 'روچ کپتین بلوچی', # Western Balochi
	'bh' => 'भोजपुरी', # Bihari macro language. Falls back to Bhojpuri (bho)
	'bho' => 'भोजपुरी', # Bhojpuri
	'bi' => 'Bislama', # Bislama
	'bjn' => 'Banjar', # Banjarese
	'blk' => 'ပအိုဝ်ႏဘာႏသာႏ', # Pa'O
	'bm' => 'bamanankan', # Bambara
	'bn' => 'বাংলা', # Bengali
	'bo' => 'བོད་ཡིག', # Tibetan
	'bpy' => 'বিষ্ণুপ্রিয়া মণিপুরী', # Bishnupriya Manipuri
	'bqi' => 'بختیاری', # Bakthiari
	'br' => 'brezhoneg', # Breton
	'brh' => 'Bráhuí', # Brahui
	'bs' => 'bosanski', # Bosnian
	'btm' => 'Batak Mandailing', # Batak Mandailing
	'bto' => 'Iriga Bicolano', # Rinconada Bikol
	'bug' => 'ᨅᨔ ᨕᨘᨁᨗ', # Buginese
	'bxr' => 'буряад', # Buryat (Russia)
	'ca' => 'català', # Catalan
	'cbk-zam' => 'Chavacano de Zamboanga', # Zamboanga Chavacano, T124657
	'cdo' => '閩東語 / Mìng-dĕ̤ng-ngṳ̄', # Min-dong (multiple scripts - defaults to Latin)
	'ce' => 'нохчийн', # Chechen
	'ceb' => 'Cebuano', # Cebuano
	'ch' => 'Chamoru', # Chamorro
	'cho' => 'Chahta Anumpa', # Choctaw
	'chr' => 'ᏣᎳᎩ', # Cherokee
	'chy' => 'Tsetsêhestâhese', # Cheyenne
	'ckb' => 'کوردی', # Central Kurdish
	'co' => 'corsu', # Corsican
	'cps' => 'Capiceño', # Capiznon
	'cr' => 'Nēhiyawēwin / ᓀᐦᐃᔭᐍᐏᐣ', # Cree
	'crh' => 'qırımtatarca', # Crimean Tatar (multiple scripts - defaults to Latin)
	'crh-cyrl' => 'къырымтатарджа (Кирилл)', # Crimean Tatar (Cyrillic)
	'crh-latn' => 'qırımtatarca (Latin)', # Crimean Tatar (Latin)
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
	'dsb' => 'dolnoserbski', # Lower Sorbian
	'dtp' => 'Dusun Bundu-liwan', # Central Dusun
	'dty' => 'डोटेली', # Doteli
	'dv' => 'ދިވެހިބަސް', # Dhivehi
	'dz' => 'ཇོང་ཁ', # Dzongkha (Bhutan)
	'ee' => 'eʋegbe', # Éwé
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
	'fy' => 'Frysk', # Frisian
	'ga' => 'Gaeilge', # Irish
	'gaa' => 'Ga', # Ga
	'gag' => 'Gagauz', # Gagauz
	'gan' => '贛語', # Gan (multiple scripts - defaults to Traditional Han)
	'gan-hans' => '赣语（简体）', # Gan (Simplified Han)
	'gan-hant' => '贛語（繁體）', # Gan (Traditional Han)
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
	'hak' => '客家語/Hak-kâ-ngî', # Hakka
	'haw' => 'Hawaiʻi', # Hawaiian
	'he' => 'עברית', # Hebrew
	'hi' => 'हिन्दी', # Hindi
	'hif' => 'Fiji Hindi', # Fijian Hindi (multiple scripts - defaults to Latin)
	'hif-latn' => 'Fiji Hindi', # Fiji Hindi (Latin script)
	'hil' => 'Ilonggo', # Hiligaynon
	'hno' => 'ہندکو', # Hindko
	'ho' => 'Hiri Motu', # Hiri Motu
	'hr' => 'hrvatski', # Croatian
	'hrx' => 'Hunsrik', # Riograndenser Hunsrückisch
	'hsb' => 'hornjoserbsce', # Upper Sorbian
	'hsn' => '湘语', # Xiang Chinese
	'ht' => 'Kreyòl ayisyen', # Haitian Creole French
	'hu' => 'magyar', # Hungarian
	'hu-formal' => 'magyar (formal)', # Hungarian formal address
	'hy' => 'հայերեն', # Armenian, T202611
	'hyw' => 'Արեւմտահայերէն', # Western Armenian, T201276, T219975
	'hz' => 'Otsiherero', # Herero
	'ia' => 'interlingua', # Interlingua (IALA)
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
	'it' => 'italiano', # Italian
	'iu' => 'ᐃᓄᒃᑎᑐᑦ / inuktitut', # Inuktitut (macro language, see ike/ikt, falls back to ike-cans)
	'ja' => '日本語', # Japanese
	'jam' => 'Patois', # Jamaican Creole English
	'jbo' => 'la .lojban.', # Lojban
	'jut' => 'jysk', # Jutish / Jutlandic
	'jv' => 'Jawa', # Javanese
	'ka' => 'ქართული', # Georgian
	'kaa' => 'Qaraqalpaqsha', # Karakalpak
	'kab' => 'Taqbaylit', # Kabyle
	'kbd' => 'адыгэбзэ', # Kabardian
	'kbd-cyrl' => 'адыгэбзэ', # Kabardian (Cyrillic)
	'kbp' => 'Kabɩyɛ', # Kabiyè
	'kcg' => 'Tyap', # Tyap
	'kea' => 'kabuverdianu', # Cape Verdean Creole
	'kg' => 'Kongo', # Kongo, (FIXME!) should probably be KiKongo or KiKoongo
	'khw' => 'کھوار', # Khowar
	'ki' => 'Gĩkũyũ', # Gikuyu
	'kiu' => 'Kırmancki', # Kirmanjki
	'kj' => 'Kwanyama', # Kwanyama
	'kjh' => 'хакас', # Khakas
	'kjp' => 'ဖၠုံလိက်', # Eastern Pwo (multiple scripts - defaults to Burmese script)
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
	'ko' => '한국어', # Korean
	'ko-kp' => '조선말', # Korean (DPRK), T190324
	'koi' => 'перем коми', # Komi-Permyak
	'kr' => 'kanuri', # Kanuri
	'krc' => 'къарачай-малкъар', # Karachay-Balkar
	'kri' => 'Krio', # Krio
	'krj' => 'Kinaray-a', # Kinaray-a
	'krl' => 'karjal', # Karelian
	'ks' => 'कॉशुर / کٲشُر', # Kashmiri (multiple scripts - defaults to Perso-Arabic)
	'ks-arab' => 'کٲشُر', # Kashmiri (Perso-Arabic script)
	'ks-deva' => 'कॉशुर', # Kashmiri (Devanagari script)
	'ksh' => 'Ripoarisch', # Ripuarian
	'ksw' => 'စှီၤ', # S'gaw Karen
	'ku' => 'kurdî', # Kurdish (multiple scripts - defaults to Latin)
	'ku-arab' => 'كوردي (عەرەبی)', # Northern Kurdish (Arabic script) (falls back to ckb)
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
	'lki' => 'لەکی', # Laki
	'lld' => 'Ladin', # Ladin
	'lmo' => 'lombard', # Lombard - T283423
	'ln' => 'lingála', # Lingala
	'lo' => 'ລາວ', # Laotian
	'loz' => 'Silozi', # Lozi
	'lrc' => 'لۊری شومالی', # Northern Luri
	'lt' => 'lietuvių', # Lithuanian
	'ltg' => 'latgaļu', # Latgalian
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
	'mni' => 'ꯃꯤꯇꯩ ꯂꯣꯟ', # Manipuri/Meitei
	'mnw' => 'ဘာသာ မန်', # Mon, T201583
	'mo' => 'молдовеняскэ', # Moldovan, deprecated (ISO 639-2: ro-Cyrl-MD)
	'mos' => 'moore', # Mooré
	'mr' => 'मराठी', # Marathi
	'mrh' => 'Mara', # Mara
	'mrj' => 'кырык мары', # Hill Mari
	'ms' => 'Bahasa Melayu', # Malay
	'ms-arab' => 'بهاس ملايو', # Malay (Arabic Jawi script)
	'mt' => 'Malti', # Maltese
	'mus' => 'Mvskoke', # Muskogee/Creek
	'mwl' => 'Mirandés', # Mirandese
	'my' => 'မြန်မာဘာသာ', # Burmese
	'myv' => 'эрзянь', # Erzya
	'mzn' => 'مازِرونی', # Mazanderani
	'na' => 'Dorerin Naoero', # Nauruan
	'nah' => 'Nāhuatl', # Nahuatl (added to ISO 639-3 on 2006-10-31)
	'nan' => 'Bân-lâm-gú', # Min-nan, T10217
	'nap' => 'Napulitano', # Neapolitan, T45793
	'nb' => 'norsk bokmål', # Norwegian (Bokmal)
	'nds' => 'Plattdüütsch', # Low German ''or'' Low Saxon
	'nds-nl' => 'Nedersaksies', # aka Nedersaksisch: Dutch Low Saxon
	'ne' => 'नेपाली', # Nepali
	'new' => 'नेपाल भाषा', # Newar / Nepal Bhasha
	'ng' => 'Oshiwambo', # Ndonga
	'nia' => 'Li Niha', # Nias, T263968
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
	'nrm' => 'Nouormand', # Norman (invalid code; 'nrf' in ISO 639 since 2014)
	'nso' => 'Sesotho sa Leboa', # Northern Sotho
	'nv' => 'Diné bizaad', # Navajo
	'ny' => 'Chi-Chewa', # Chichewa
	'nyn' => 'runyankore', # Nkore
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
	# 'ruq-grek' => 'Βλαεστε', # Megleno-Romanian (Greek script)
	'ruq-latn' => 'Vlăheşte', # Megleno-Romanian (Latin script)
	'rw' => 'Ikinyarwanda', # Kinyarwanda
	'ryu' => 'うちなーぐち', # Okinawan
	'sa' => 'संस्कृतम्', # Sanskrit
	'sah' => 'саха тыла', # Sakha
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
	'shn' => 'ၽႃႇသႃႇတႆး ', # Shan
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
	'sli' => 'Schläsch', # Lower Selisian
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
	'tdd' => 'ᥖᥭᥰᥖᥬᥳᥑᥨᥒᥰ', # Tai Nüa
	'te' => 'తెలుగు', # Telugu
	'tet' => 'tetun', # Tetun
	'tg' => 'тоҷикӣ', # Tajiki (falls back to tg-cyrl)
	'tg-cyrl' => 'тоҷикӣ', # Tajiki (Cyrllic script) (default)
	'tg-latn' => 'tojikī', # Tajiki (Latin script)
	'th' => 'ไทย', # Thai
	'ti' => 'ትግርኛ', # Tigrinya
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
	'wo' => 'Wolof', # Wolof
	'wuu' => '吴语', # Wu Chinese
	'xal' => 'хальмг', # Kalmyk-Oirat
	'xh' => 'isiXhosa', # Xhosan
	'xmf' => 'მარგალური', # Mingrelian
	'xsy' => 'saisiyat', # SaiSiyat - T216479
	'yi' => 'ייִדיש', # Yiddish
	'yo' => 'Yorùbá', # Yoruba
	'yrl' => 'Nhẽẽgatú', # Nheengatu
	'yue' => '粵語', # Cantonese (multiple scripts - defaults to Traditional Han)
	'za' => 'Vahcuengh', # Zhuang
	'zea' => 'Zeêuws', # Zeeuws / Zeaws
	'zgh' => 'ⵜⴰⵎⴰⵣⵉⵖⵜ ⵜⴰⵏⴰⵡⴰⵢⵜ', # Moroccan Amazigh (multiple scripts - defaults to Neo-Tifinagh)
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
	# Updated 2023-04-22 from https://github.com/wikimedia/mediawiki-extensions-Wikibase/blob/master/lib/includes/WikibaseContentLanguages.php
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
	'sje' => 'Sami, Pite', # Sami, Pite - T146707
	'sju' => 'Sami, Ume', # Sami, Ume - T226701
	'smj' => 'Lule Sámi', # Lule Sámi - T146707
	'sms' => 'Skolt Sami', # Skolt Sami - T220118, T223544
	'srq' => 'Sirionó', # Sirionó - T113408
	'tvu' => 'Tunen', # Tunen - T263946
	'vut' => 'Vute', # Vute - T263946
	'wes' => 'Pidgin (Cameroon)', # Pidgin (Cameroon) - T263946
	'wya' => 'Wyandot', # Wyandot - T283364
	'yas' => 'Nugunu', # Nugunu - T263946
	'yat' => 'Yambeta', # Yambeta - T263946
	'yav' => 'Yangben', # Yangben - T263946
	'ybb' => 'Yemba', # Yemba - T263946
);

our $VERSION = 0.31;

sub all_language_codes {
	return keys %LANGUAGES;
}

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Languages - Wikibase datatype languages.

=head1 SYNOPSIS

 use Wikibase::Datatype::Languages qw(all_language_codes);

 my @language_codes = all_language_codes();

=head1 DESCRIPTION

Language codes used for multilingual information in Wikibase::Datatype objects.

It's imported from L<https://doc.wikimedia.org/mediawiki-core/master/php/Names_8php_source.html>
and from L<https://github.com/wikimedia/mediawiki-extensions-Wikibase/blob/master/lib/includes/WikibaseContentLanguages.php> (2023-04-22).

=head1 SUBROUTINES

=head2 C<all_language_codes>

 my @language_codes = all_language_codes();

Get language codes used in MediaWiki.

Returns array with codes.

=head1 EXAMPLE

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
 # ab
 # abs
 # ace
 # acm
 # ady
 # ady-cyrl
 # aeb
 # aeb-arab
 # aeb-latn
 # af
 # agq
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
 # be
 # be-tarask
 # be-x-old
 # bfd
 # bg
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
 # bpy
 # bqi
 # bqz
 # br
 # brh
 # bs
 # btm
 # bto
 # bug
 # bxr
 # byv
 # ca
 # cak
 # cbk-zam
 # cdo
 # ce
 # ceb
 # ch
 # cho
 # chr
 # chy
 # ckb
 # cnh
 # co
 # cps
 # cr
 # crh
 # crh-cyrl
 # crh-latn
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
 # dsb
 # dtp
 # dty
 # dua
 # dv
 # dz
 # ee
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
 # frc
 # frp
 # frr
 # fur
 # fy
 # ga
 # gaa
 # gag
 # gan
 # gan-hans
 # gan-hant
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
 # haw
 # he
 # hi
 # hif
 # hif-latn
 # hil
 # hno
 # ho
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
 # it
 # iu
 # ja
 # jam
 # jbo
 # jut
 # jv
 # ka
 # kaa
 # kab
 # kbd
 # kbd-cyrl
 # kbp
 # kcg
 # kea
 # ker
 # kg
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
 # lki
 # lld
 # lmo
 # ln
 # lns
 # lo
 # loz
 # lrc
 # lt
 # ltg
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
 # nap
 # nb
 # nds
 # nds-nl
 # ne
 # new
 # ng
 # nge
 # nia
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
 # nrm
 # nso
 # nv
 # ny
 # nyn
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
 # rw
 # rwr
 # ryu
 # sa
 # sah
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
 # tk
 # tl
 # tly
 # tly-cyrl
 # tn
 # to
 # tok
 # tpi
 # tr
 # tru
 # trv
 # ts
 # tt
 # tt-cyrl
 # tt-latn
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
 # wo
 # wuu
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
 # yue
 # za
 # zea
 # zgh
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

=head1 DEPENDENCIES

L<Exporter>,
L<Readonly>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Datatype>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.31

=cut
