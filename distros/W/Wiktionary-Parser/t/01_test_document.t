#! /usr/bin/env perl
# test the parser against a static document
use strict;
use warnings;
use Data::Dumper;

use Wiktionary::Parser;
use Test::More tests => 2;

my $parser = Wiktionary::Parser->new();


local $/ = undef;
my $content = <DATA>;
my $title = 'orange';

my $document = $parser->parse_page_content(
	content => $content,
	title   => $title,
);


is_deeply(
	$document->get_table_of_contents(),
	table_of_contents(),
	'Table of contents processed correctly'
);

is_deeply(
	$document->get_section_languages(),
	section_languages(),
	'Section headings for languages were parsed correctly'
);


sub section_languages {
	return [qw(
		english
		french
		german
		guernésiais
		jèrriais
		luxembourgish
		swedish
	)];
}

sub table_of_contents {
	return  
	[
	 '1,english',
	 '1.1,etymology',
	 '1.2,pronunciation',
	 '1.2.1,usage notes',
	 '1.3,noun',
	 '1.3.1,derived terms',
	 '1.3.2,translations',
	 '1.4,adjective',
	 '1.4.1,translations',
	 '1.5,verb',
	 '1.6,see also',
	 '1.7,references',
	 '1.8,anagrams',
	 '2,french',
	 '2.1,etymology',
	 '2.2,pronunciation',
	 '2.3,noun',
	 '2.4,noun',
	 '2.4.1,derived terms',
	 '2.5,adjective',
	 '2.5.1,usage notes',
	 '2.6,anagrams',
	 '3,german',
	 '3.1,etymology',
	 '3.2,pronunciation',
	 '3.3,adjective',
	 '4,guernésiais',
	 '4.1,etymology',
	 '4.2,adjective',
	 '5,jèrriais',
	 '5.1,etymology',
	 '5.2,adjective',
	 '6,luxembourgish',
	 '6.1,adjective',
	 '6.2,see also',
	 '7,swedish',
	 '7.1,etymology',
	 '7.2,pronunciation',
	 '7.3,adjective',
	 '7.4,noun'
	];
}






__DATA__
{{also|Orange|orangé}}
==English==
{{wikipedia}}
[[File:Color icon orange v2.svg|thumb|200px|upright|Various shades of orange.]]
[[File:Ambersweet oranges.jpg|thumb|200px|upright|Some oranges (the fruits).]]
[[File:Citrus sinensis JPG01.jpg|thumb|200px|upright|An orange tree.]]

===Etymology===
{{etyl|enm}} {{term|orenge|lang=enm}}, {{term|orange|lang=enm}}, from {{etyl|fro}} {{term|pome|lang=fro}} {{term|orenge|lang=fro}} 'Persian orange', literally 'orange apple', influenced by {{etyl|pro}} {{term|auranja|lang=pro}} and calqued from {{etyl|roa-oit}} ''melarancio'', ''melarancia'', compound of {{term|mela|lang=it}} 'apple' and ''(n)''{{term|arancia|lang=it}} 'orange', from {{etyl|ar}} {{term|sc=Arab|نارنج|tr=nāranj|lang=ar}}, from {{etyl|fa}} {{term|sc=fa-Arab|نارنگ|tr=nārang|lang=fa}}, from {{etyl|sa}} {{term|sc=Deva|नारङ्ग|tr=nāraṅga||orange tree|lang=sa}}, from Dravidian (cf. [[Tamil]] ''nartankāy'', compound of {{term|நரந்தம்|tr=narantam|lang=ta||fragrance}} and {{term|காய்|tr=kāy|lang=ta||fruit}}; also Telugu {{term|నారంగము|tr=nāraṅgamu|lang=te}}, Malayalam {{term|നാരങ്ങ|tr=nāraṅga|lang=ml}}, Kannada {{term|ನಾರಂಗಿ|tr=nāraṅgi|lang=kn}}).

For the color sense, replaced Old English {{term|geoluhread||yellow-red|lang=enm}};<ref> Kenner, T.A. (2006). ''Symbols and their hidden meanings.'' New York: Thunders Mouth. p. 11. ISBN 1560259493.</ref> compare Modern English {{term|blue-green|lang=en}}.

===Pronunciation===
* {{a|UK}} {{IPA|/ˈɒ.ɹɪndʒ/}}, {{X-SAMPA|/"Q.r\IndZ/}}
* {{a|US}} {{enPR|är'ənj}}, {{IPA|/ˈɔɹ.əndʒ/|/ˈɑɹ.əndʒ/|/ˈɔɹndʒ/}}, {{X-SAMPA|/"Or\.@ndZ/|/"Ar\.@ndz/|/OrndZ/}}
* {{a|CA}} {{IPA|/ˈɔɹndʒ/}}, {{X-SAMPA|/OrndZ/}}
* {{audio|En-ca-orange.ogg|Audio (CA)}}
* {{audio|En-uk-orange.ogg|Audio (UK)}}
* {{homophones|Orange}}
* {{rhymes|ɒrɪndʒ}}

====Usage notes====
* It is commonly believed that “orange” has no rhymes. While there are no commonly used English dictionary words that rhyme exactly with “orange” (“door-hinge” comes close in US pronunciation), the English surname {{term|Gorringe}} is a rhyme, at least in UK pronunciation. See [[w:Orange_(word)#Rhyme|the Wikipedia article about rhymes for the word “orange”]]

===Noun===
{{en-noun}}

# An [[evergreen]] [[tree]] of the genus ''[[Citrus]]'' such as ''[[Citrus aurantium]]''.
# The [[fruit]] of an orange tree; a [[citrus fruit]] with a slightly [[sour]] flavour.
# The [[colour]] of a ripe orange (the fruit); a color midway between red and yellow.

====Derived terms====
{{rfc|split into senses}}
{{der-top}}
* [[bergamot orange]]
* [[bitter orange]]
* [[blood orange]]
* [[burnt orange]]
* [[Cox’s Orange Pippin]]
* [[East Orange]]
* [[Jaffa orange]]
* [[methyl orange]]
* [[mock orange]]
* [[monkey orange]]
* [[navel orange]]
<!--derived from "orange juice": * [[OJ]]-->
* [[orangeade]]
* [[orange badge]]
* [[orange blossom]]
* [[Orange Bowl]]
* [[orange chromide]]
* [[orange flower water]]
* [[orange flowering jessamine]]
* [[Orange Free State]]
* [[orange hawkwood]]
* [[orange jessamine]]
* [[orange juice]]
{{der-mid}}
* [[Orange lodge]]
* [[orange milkweed]]
* [[Orange Order]]
* [[orange pekoe]]
* [[orange peel]], [[orange-peel]] <!--derived from "orange peel": * [[orange-peel fungus]]-->
* [[orangequat]]
* [[Orange Revolution]]
* [[Orange River]]
* [[orangeroot]]
* [[orangery]]
* [[orange squash]]
* [[orange stick]]
* [[orange-tip]]
* [[orangewood]]
* [[Orangey]]
* [[Orangies]]
* [[orangish]]
* [[Osage orange]]
* [[Otaheite orange]]
* [[satsuma orange]]
* [[Seville orange]]
* [[sour orange]]
* [[sweet orange]]
{{der-bottom}}

====Translations====
{{trans-top|tree}}
* Afrikaans: {{t|af|lemoenboom|xs=Afrikaans}}
* Arabic: {{Arab|[[شجرة البرتقال]]}} (šájarat al-burtuqál) {{f}}
* Armenian: {{t-|hy|նարինջ|tr=narinǰ}}
* Basque: {{t|eu|laranjondo|xs=Basque}}
* Belarusian: [[апэльсінавае дрэва]] (apelsínavaie dréva)
* Breton: [[orañjezenn]] {{f}}, orañjezenned {{p}}, [[orañjez]] ''collective noun''
* Catalan: [[taronger]] {{m}}
* Chechen: [[апельсин]]
* Chinese:
*: Mandarin: {{t|cmn|橙树|tr=chéngshù|sc=Hani}}
* Czech: {{t|cs|pomerančovník|m}}
* Danish: {{t|da|appelsintræ}}
* Dutch: {{t-|nl|sinaasappelboom|m}}, {{t-|nl|appelsienenboom|m}}
* Esperanto: {{t-|eo|oranĝarbo|xs=Esperanto}}, {{t-|eo|oranĝujo|xs=Esperanto}}
* Estonian: {{t-|et|apelsinipuu}}
* Finnish: {{t-|fi|appelsiinipuu}}
* French: {{t+|fr|oranger|m}}
* Galician: [[laranxeira]] {{f}}
* German: {{t-|de|Apfelsinenbaum|m}}, {{t+|de|Orangenbaum|m}}
* Greek: {{t+|el|πορτοκαλιά|f|tr=portokaliá}}
* Hebrew: {{t|he|תפוז|m|tr=tapúz|sc=Hebr}}
* Hungarian: {{t+|hu|narancsfa}}
* Ido: [[oranja]]
* Indonesian: {{t+|id|jeruk manis|xs=Indonesian}}
* Irish: [[crann oráistí]] {{m}}
* Italian: {{t+|it|arancio|m}}
* Japanese: {{t-|ja|オレンジ|tr=orenji}}
* Korean: [[오렌지나무]] (orenji-namu)
* Kurdish: {{t+|ku|pirteqal}}, {{ku-Arab|[[دار پرته‌قاڵ]]}}
* Lithuanian: [[apelsinmedis]] {{m}}
{{trans-mid}}
* Lojban: [[najnimre]]
* Low German: {{t|nds|Orange|f}}
* Luxembourgish: {{t|lb|Orangëbam|m}}
* Macedonian: {{t-|mk|портокал|m|tr=pórtokal}}
* Malay: {{t|ms|pokok limau}}
* Malayalam: [[നാരങ്ങ]] (naːraŋːa)
* Maltese: {{t-|mt|larinġa|f|xs=Maltese}}
* Navajo: {{tø|nv|chʼil łitsxooí}}
* Norwegian: {{t-|no|appelsintre|n}}
* Novial: [[oranjiere]]
* Persian: {{t+|fa|نارنج|tr=nâranj|xs=Persian}}, {{t+|fa|پرتقال|tr=porteghâl|xs=Persian}}
* Polish: {{t+|pl|pomarańcza|f}}, {{t-|pl|drzewo pomarańczowe|n}}
* Portuguese: {{t+|pt|laranjeira|f}}
* Romanian: {{t+|ro|portocal|m}}
* Russian: {{t-|ru|апельсиновое дерево|n|tr=apelsínovoje dérevo}}
* Sardinian: [[arbule de aranzu]] {{m}}
* Serbo-Croatian:
*: Cyrillic: {{t|sh|наранџа|f|alt=на̀ра̄нџа|sc=Cyrl}}, {{t|sh|поморанџа|f|alt=помо̀ра̄нџа|sc=Cyrl}}
*: Roman: {{t|sh|narandža|f|alt=nàrāndža}}, {{t|sh|pomorandža|f|alt=pomòrāndža}}, {{t|sh|naranča|f|alt=nàrānča}}, {{t|sh|pomoranča|f|alt=pomòrānča}}
* Sindhi: {{sd-Arab|[[نارنگيءَ جو وَڻُ]]}} (narangi’a ju vanu) {{m}}
* Slovene: [[oranževec]] {{m}}
* Sotho: {{t|st|sefate sa lamunu|xs=Sotho}}
* Spanish: {{t+|es|naranjo|m}}
* Swahili: {{t+|sw|mchungwa|xs=Swahili}}
* Swedish: {{t+|sv|apelsinträd|n}}
* Turkish: {{t+|tr|portakal}}
* Vietnamese: [[cây]] [[cam]]
* Welsh: {{t+|cy|oren|xs=Welsh}}
{{trans-bottom}}

{{trans-top|fruit}}
* Afrikaans: [[lemoen]]
* Albanian: {{t|sq|portokall|f|xs=Albanian}}
* American Sign Language: {{tø|ase|C@NearChin Squeeze|xs=American Sign Language}}
* Arabic: {{t|ar|برتقالة|f|tr=burtuqaala|sc=Arab}}, {{qualifier|collective}} {{t|ar|برتقال|m|tr=burtuqaal|sc=Arab}}
*: Egyptian Arabic: {{tø|arz|برتقان|tr=burtuʕaan|sc=Arab|xs=Egyptian Arabic}} ''(collective)''
* Armenian: {{t-|hy|նարինջ|tr=narinǰ}}
* Azeri: {{t+|az|portağal|xs=Azeri}}
* Bashkir: {{tø|ba|әфлисун|tr=əflisun|sc=Cyrl|xs=Bashkir}}
* Basque: {{t+|eu|laranja|xs=Basque}}
* Belarusian: {{t|be|апэльсін|m|tr=apel’sín|sc=Cyrl}}
* Bengali: {{t|bn|কমলা|tr=kamlā|sc=Beng}}
* Breton: [[orañjezenn]] {{f}}
* Bulgarian: {{t|bg|портокал|m|tr=portokál|sc=Cyrl}}
* Catalan: [[taronja]] {{f}}
* Chamicuro: {{tø|ccc|alansha}}
* Chechen: [[апельсин]]
* Chinese:
*: Mandarin: {{t-|cmn|橙|tr=chéng|sc=Hani}}, {{t|cmn|橙子|tr=chéngzi|sc=Hani}}, {{qualifier|technically "tangerine", but often used as "orange"}} {{t-|cmn|橘子|tr=júzi|sc=Hani}}, {{qualifier|alternative form:}} {{t|cmn|桔子|tr=júzi|sc=Hani}}
* Czech: {{t+|cs|pomeranč|m}}
* Danish: {{t+|da|appelsin}}
* Dutch: {{t+|nl|sinaasappel|m}}, {{t+|nl|appelsien|f}}
* Esperanto: {{t-|eo|oranĝo|xs=Esperanto}}
* Estonian: {{t+|et|apelsin}}
* Finnish: {{t+|fi|appelsiini}}
* French: {{t+|fr|orange|f}}
* Galician: [[laranxa]] {{f}}
* Georgian: {{t+|ka|ფორთოხალი|tr=p'ort'oxali|sc=Geor|xs=Georgian}}
* German: {{t+|de|Apfelsine|f}}, {{t+|de|Orange|f}}
* Greek: {{t+|el|πορτοκάλι|n|tr=portokáli}}
* Hebrew: {{t|he|תפוז|m|tr=tapúz|sc=Hebr}}
* Hindi: {{t-|hi|नारंगी|f|tr=nāraṅgī|xs=Hindi}}, {{t|hi|संतरा|m|tr=santarā|xs=Hindi}}
* Hungarian: {{t+|hu|narancs}}
* Icelandic: {{t+|is|appelsína|f}}
* Indonesian: {{t+|id|jeruk manis|xs=Indonesian}}, {{t+|id|limau|xs=Indonesian}}
* Irish: {{t+|ga|oráiste|m|xs=Irish}}
* Italian: {{t+|it|arancia|f}}
* Japanese: {{t-|ja|みかん|tr=mikan}}{{t-|ja|オレンジ|tr=orenji}}
* Kalmyk: {{tø|xal|зүрҗ|tr=zürj|sc=Cyrl}}
* Khmer: {{t|km|ក្រូចពោធិសាត់|tr=krooch pootʰi’sat|sc=Khmr}}
* Korean: {{t|ko|오렌지|tr=orenji|sc=Kore}}
* Kurdish: {{t+|ku|pirteqal}}, {{ku-Arab|[[پرته‌قاڵ]]}}
* Latin: {{t|la|arantium|n}}
* Latvian: {{t+|lv|apelsīns|m|xs=Latvian}}
{{trans-mid}}
* Lithuanian: {{t+|lt|apelsinas|m|xs=Lithuanian}}
* Lojban: [[najnimre]]
* Low German: {{t|nds|Orange|f}}
* Luxembourgish: {{t|lb|Orange|f}}
* Macedonian: {{t-|mk|портокал|m|tr=pórtokal}}
* Malay: {{t+|ms|oren|xs=Malay}}, {{t|ms|limau}}
* Maltese: {{t-|mt|larinġa|f|xs=Maltese}}
* Manx: {{t|gv|oranje|f}}
* Marathi: {{t|mr|संत्रे|n|tr=santré|sc=Deva|xs=Marathi}}, {{t|mr|नारिंग|n|tr=nāring|sc=Deva|xs=Marathi}}
* Mongolian: {{t-|mn|жүрж|tr=žürž|sc=Cyrl|xs=Mongolian}}
* Navajo: {{tø|nv|chʼil łitsxooí}}
* Northern Sami: [[appelsiidna]]
* Norwegian: {{t+|no|appelsin|m}}
* Novial: [[oranje]]
* Ossetian: {{tø|os|апельсин|tr=apel'sin|sc=Cyrl|xs=Ossetian}}
* Persian: {{t+|fa|نارنج|tr=nâranj|xs=Persian}}, {{t+|fa|پرتقال|tr=porteqâl|xs=Persian}}
* Polish: {{t+|pl|pomarańcza|f}}
* Portuguese: {{t+|pt|laranja|f}}
* Romanian: {{t+|ro|portocală|f}}
* Russian: {{t+|ru|апельсин|m|tr=apel’sín}}
* Sardinian: [[aranzu]] {{m}}
* Scottish Gaelic: [[òr-mheas]] {{m}}, {{t-|gd|oraindsear|m|xs=Scottish Gaelic}}
* Serbo-Croatian:
*: Cyrillic: {{t|sh|наранџа|f|alt=на̀ра̄нџа|sc=Cyrl}}, {{t|sh|поморанџа|f|alt=помо̀ра̄нџа|sc=Cyrl}}
*: Roman: {{t|sh|narandža|f|alt=nàrāndža}}, {{t|sh|pomorandža|f|alt=pomòrāndža}}, {{t|sh|naranča|f|alt=nàrānča}}, {{t|sh|pomoranča|f|alt=pomòrānča}}
* Sindhi: {{sd-Arab|[[نارنگِي]]}} (narangi) {{f}}
* Slovene: {{t+|sl|pomaranča|f}}
* Sotho: {{t|st|lamunu|xs=Sotho}}
* Spanish: {{t+|es|naranja|f}}, {{t+|es|china|f}} {{qualifier|Dominican Republic|Puerto Rico}}
* Swahili: {{t+|sw|chungwa|xs=Swahili}}
* Swedish: {{t+|sv|apelsin|c}}
* Tagalog: {{t|tl|kahel}}, {{t|tl|dalandan}}, {{t|tl|narangha}}
* Tajik: {{t|tg|афлесун|tr=aflesun|sc=Cyrl|xs=Tajik}}, {{t|tg|норанҷ|tr=noranç|sc=Cyrl|xs=Tajik}}
* Tatar: {{t|tt|äflisun|xs=Tatar}}
* Telugu: {{t+|te|నారింజ}}, {{t|te|కమలాఫలము}}
* Tetum: [[sabraka]]
* Turkish: {{t+|tr|portakal}}
* Turkmen: {{t-|tk|narynç|xs=Turkmen}}
* Ukrainian: {{t+|uk|апельсин|m|tr=apel′sýn|xs=Ukrainian}}
* Urdu: {{t-|ur|نارنگی|f|tr=nāraṅgī|xs=Urdu}}, {{t|ur|سنترا|m|tr=santarā|sc=ur-Arab}}
* Uzbek: {{t-|uz|poʻrtahol|xs=Uzbek}}
* Vietnamese: ([[quả]] / [[trái]]) {{t+|vi|cam|xs=Vietnamese}}
* Volapük: {{t|vo|rojat|xs=Volapük}}
* Welsh: {{t+|cy|oren|xs=Welsh}}
{{trans-bottom}}

{{trans-top|colour}}
* Afrikaans: [[oranje]]
* American Sign Language: {{tø|ase|C@NearChin Squeeze|xs=American Sign Language}}
* Arabic:
*: Egyptian Arabic: {{tø|arz|برتقاني|tr=burtuʕaani|sc=Arab|xs=Egyptian Arabic}}, {{tø|arz|برتقالي|tr=burtuqālii|sc=Arab|xs=Egyptian Arabic}}
* Armenian: {{t+|hy|նարնջագույն|tr=narnǰaguyn}}, {{t-|hy|գազարագույն|tr=gazaraguyn}}
* Azeri: {{t|az|narincı}}
* Basque: {{t+|eu|laranja|xs=Basque}}
* Bengali: {{t|bn|কমলা|sc=Beng}}
* Breton: [[liv]] [[orañjez]]
* Bulgarian: {{t|bg|оранжев|tr=oranžev|sc=Cyrl}}
* Buryat: {{tø|bua|шара улаан}}
* Catalan: [[taronja]] {{f}}
* Chechen: {{tø|ce|цlеран бос}}
* Chinese:
*: Mandarin: {{t-|cmn|橙色|tr=chéngsè|sc=Hani}}, {{t|cmn|橙黃色|sc=Hani}}, {{t|cmn|橙黄色|tr=chénghuángsè|sc=Hani}}
* Czech: {{t|cs|oranžový}}
* Danish: {{t-|da|orange}}
* Dutch: {{t+|nl|oranje|n}}
* Esperanto: {{t|eo|oranĝokolora}}
* Estonian: {{t-|et|oranž}}
* Finnish: {{t+|fi|oranssi}}
* French: {{t+|fr|orange|m}}
* Galician: [[laranxa]] {{f}}
* Georgian: {{t|ka|სტაფილოსფერი|tr=stap'ilosp'eri|sc=Geor}}
* German: {{t+|de|Orange|f}}
* Greek: {{t+|el|πορτοκαλί|n|tr=portokalí}}
* Hausa: {{t|ha|mai ruwan lemo}}, {{t|ha|lemo}}
* Hawaiian: {{tø|haw|ʻalani}}
* Hebrew: [[כתום]] (katóm)
* Hindi: {{t-|hi|नारंगी|tr=nāraṅgī|xs=Hindi}}
* Hungarian: {{t+|hu|narancssárga}}, {{t+|hu|narancs szín}}, {{t+|hu|narancs}}
* Icelandic: {{t+|is|appelsínugulur}}
* Indonesian: {{t-|id|jingga|xs=Indonesian}}, {{t+|id|oranye|xs=Indonesian}}
* Irish: [[dath oráiste]] {{m}}, {{t|ga|oráiste}}
* Italian: {{t+|it|arancione|m}}
* Japanese: [[オレンジ色]] (orenjiiro), [[橙色]] (daidaiiro)
* Kazakh: {{t|kk|қызғылт сары|tr=qızğılt sarı|sc=Cyrl}}
* Khmer: {{t|km|ទឹកក្រូច|sc=Khmr|tr=tɨk krooch}}
* Korean: {{t|ko|주황색|tr=juhwangsaek|sc=Kore}}
* Kurdish: {{t|ku|pirteqalî}}
* Kyrgyz: {{t|ky|токсары|tr=toksarı|sc=Cyrl}}
* Latin: {{t|la|aurantius|m}}, {{t|la|aurantia|f}}, {{t|la|aurantium|n}}
* Latvian: [[oranžs]]
{{trans-mid}}
* Lithuanian: [[oranžinė spalva]] {{f}}, [[apelsininė spalva]] {{f}}, {{t|lt|oranžinė}}
* Lojban: {{t|jbo|narju}}
* Low German: {{t|nds|Orange|n}}
* Luxembourgish: {{t|lb|Orange|f}}
* Macedonian: {{t|mk|портокалова|m|tr=portokálova}}
* Malay: {{t|ms|jingga}}
* Maltese: {{t-|mt|oranġjo|xs=Maltese}}
* Marathi: {{t|mr|नारिंगी|n|tr=nāringi|sc=Deva|xs=Marathi}}
* Mongolian: {{t|mn|улбар шар|tr=ulbar shar|sc=Cyrl}}
* Montagnais: {{tø|moe|kaishkuteushit}}
* Nama: {{tø|naq|oranje}}
* Navajo: {{tø|nv|łichxíʼí}}
* Northern Sami: [[oránša]]
* Norwegian: {{t+|no|oransje|m}}
* Occitan: {{t|oc|irange}}
* Persian: {{t-|fa|نارنجی|tr=nâranji|xs=Persian}}
* Polish: {{t+|pl|pomarańczowy|m}}, {{t+|pl|pomarańcz|m}}
* Portuguese: {{t+|pt|alaranjado|m}}, {{t+|pt|cor-de-laranja|f}}, {{t+|pt|laranja|m}}
* Romanian: {{t+|ro|portocaliu|m}}
* Russian: {{t+|ru|оранжевый|tr=oránževyj}}
* Sardinian: [[colore de aranzu]], [[ruggiu]], [[ruiu]], [[arrubiu]]
* Serbo-Croatian:
*: Cyrillic: {{t|sh|наранџаста|f|sc=Cyrl}}
*: Roman: {{t|sh|narandžasta|f}}, {{t|sh|narančasta|f}}
* Sindhi: {{sd-Arab|[[نارنگِي]]}} (narangi)
* Slovak: {{t|sk|oranžový}}
* Slovene: [[oranžna]] {{f}}, {{t|sl|oranžna}}
* Spanish: {{t+|es|naranja|m}}
* Swahili: {{t|sw|rangi ya machungwa}}
* Swedish: {{t+|sv|orange}}, {{t+|sv|brandgul}}
* Tagalog: {{t+|tl|kahel|xs=Tagalog}}, {{t|tl|dalandan|xs=Tagalog}}
* Tamil: {{t|ta|செம்மஞ்சள்|tr=semmanjaḷ|sc=Taml}}
* Telugu: {{t|te|నారింజ|tr=naarinza|sc=Telu}}
* Turkish: {{t+|tr|turuncu}}
* Turkmen: {{t|tk|narýnç}}, {{t|tk|mämişi}}
* Tuvan: {{tø|tyv|кызыл-сарыг}}
* Ukrainian: {{t+|uk|оранжевий|tr=oranževij|xs=Ukrainian}}
* Urdu: {{t|ur|نارَنْگی|tr=naranghi|sc=ur-Arab}}
* Vietnamese: [[màu]] ([[da]]) [[cam]]
* Welsh: {{t+|cy|oren|xs=Welsh}}, {{t-|cy|melyngoch|xs=Welsh}}
* Yiddish: {{t|yi|מאַראַנץ|tr=marants|sc=Hebr}}
* Zulu: {{t|zu|orenji}}
{{trans-bottom}}

{{checktrans-top}}
<!--Remove this section once all of the translations below have been moved into the tables above.-->
* {{ttbc|ko}}: [[오렌지]] (orenji)
* {{ttbc|oc}}: [[irange]]
{{trans-bottom}}

===Adjective===
{{en-adj}}

# Having the [[colour]] of the fruit of an orange tree; [[yellowred]]; reddish-yellow.

====Translations====
{{trans-top|colour}}
* American Sign Language: {{tø|ase|C@NearChin Squeeze|xs=American Sign Language}}
* Arabic: {{t|ar|برتقالي|tr=burtuqāliyy}}
* Armenian: {{t+|hy|նարնջագույն|tr=narnǰaguyn}}, {{t-|hy|գազարագույն|tr=gazaraguyn}}
* Basque: {{t+|eu|laranja|xs=Basque}}
* Belarusian: {{t|be|аранжавы|tr=aránžavy|sc=Cyrl}}
* Breton: [[orañjez]]
* Bulgarian: {{t|bg|портокалов|tr=portokálov|sc=Cyrl}}, {{t|bg|оранжев|tr=oránžev|sc=Cyrl}}
* Catalan: [[taronja]], [[carabassa]]
* Chinese:
*: Mandarin: {{t-|cmn|橙色|tr=chéngsè|sc=Hani}}, {{t|cmn|橙黃色|sc=Hani}}, {{t|cmn|橙黄色|tr=chénghuángsè|sc=Hani}}
* Czech: {{t+|cs|oranžový}}
* Danish: {{t-|da|orange}}
* Dutch: {{t+|nl|oranje}}, {{t+|nl|brandgeel}}, {{t+|nl|geelrood}}
* Esperanto: {{t-|eo|oranĝokolora|xs=Esperanto}}
* Estonian: {{t-|et|oranž}}
* Finnish: {{t+|fi|oranssi}}
* French: {{t+|fr|orange}}
* Galician: {{t+|gl|laranxa|xs=Galician}}
* German: {{t+|de|orange}}
* Greek: {{t+|el|πορτοκαλής|n|tr=portokalís}}
* Hebrew: {{t+|he|כתום|tr=katóm|sc=Hebr}}
* Hindi: {{t|hi|नारंगी|tr=nāraṅgī|sc=Deva}}
* Hungarian: {{t+|hu|narancssárga}}, {{t+|hu|narancsszínű}}
* Icelandic: {{t|is|appelsínugulur|m}}
* Ido: [[oranjea]]
* Indonesian: {{t-|id|jingga|xs=Indonesian}}, {{t+|id|oranye|xs=Indonesian}}
* Italian: {{t+|it|arancione}}, {{t+|it|arancio}}
* Japanese: {{t-|ja|オレンジ色|alt=オレンジ色の|tr=orenji-iro-no}}, {{t+|ja|橙色|alt=橙色の|tr=だいだいいろの, daidai-iro-no}}
{{trans-mid}}
* Khmer: {{t|km|ពណ៌លឿង|tr=poa lɨəng|sc=Khmr}}
* Korean: {{t|ko|주황색|tr=juhwangsaeg-ui|alt=주황색의|sc=Kore}} ([[朱黃色]] + 의)
* Latin: {{t|la|arantius}}
* Latvian: [[oranžs]]
* Lithuanian: [[oranžinis]]
* Lojban: [[narju]]
* Low German: {{t|nds|orange}}
* Macedonian: {{t|mk|портокалов|tr=portokalov|sc=Cyrl}}
* Malay: {{t|ms|jingga}}
* Manx: {{t|gv|oranje-vuigh}}
* Norwegian: {{t+|no|oransje}}
* Persian: {{t|fa|نارنجی|tr=nârenji|sc=fa-Arab}}
* Polish: {{t+|pl|pomarańczowy}}
* Portuguese: {{t+|pt|alaranjado}}, {{t+|pt|cor-de-laranja}}, {{t+|pt|laranja}}
* Romanian: {{t+|ro|portocaliu}}, {{t+|ro|oranj}}
* Russian: {{t+|ru|оранжевый|tr=oránževyj}}
* Scottish Gaelic: {{t-|gd|orainds|xs=Scottish Gaelic}}
* Serbo-Croatian:
*: Cyrillic: {{t|sh|наранџаст}}
*: Roman: {{t|sh|narandžast}}
* Slovak: {{t|sk|oranžový}}
* Slovene: {{t+|sl|oranžen}}
* Spanish: {{t+|es|anaranjado}}, {{t+|es|naranja}}
* Swedish: {{t+|sv|orange}}, {{t+|sv|brandgul}}, {{t+|sv|apelsinfärgad}}
* Thai: {{t|th|ส้ม|tr=sôm|sc=Thai}}
* Turkish: {{t+|tr|turuncu}}
* Ukrainian: {{t+|uk|оранжевий|tr=oránževyj|xs=Ukrainian}}, {{t|uk|помаранчевий|tr=pomaránčevyj|sc=Cyrl}}
* Urdu: {{t|ur|نارنگی|tr=nāraṅgī|sc=ur-Arab}}
* Vietnamese: [[màu]] [[cam]]
* Volapük: {{t|vo|rojanik|xs=Volapük}}
{{trans-bottom}}

===Verb===
{{en-verb|orang|es}}

# {{transitive}} To color orange.
#* {{quote-book|title=Cinema: The movement-image|page=118|author=Gilles Deleuze|year=1986|passage=It is this composition which reaches a colourist perfection in Le Bonheur with the complementarity of violet, purple and '''oranged''' gold}}
#* {{quote-book|title=Rifles for Watie|page=256|author=Harold Keith|year=1987|passage=Jeff winked his eyes sleepily open and looked out into the cool flush of early morning. The east was '''oranged''' over with daybreak.}}
#* {{quote-book|title=The Very Ordered Existence of Merilee Marvelous|page=117|author=Suzanne Crowley|year=2009|passage=I looked at him through my binoculars, his little lips '''oranged''' with Cheeto dust.}}
# {{intransitive}} To become orange.
#* {{quote-book|title=Day in day out|page=296|author=Terézia Mora|year=2007|passage=Cranes in the distance against the background of the slowly '''oranging''' sky}}
#* {{quote-book|Jazz & twelve o'clock tales: new stories|page=14|author=Wanda Coleman|year=2008|passage=It will be followed by a disappearance of the cash I had hidden in a sealed envelope behind the '''oranging''' Modigliani print over the living room couch.}}
#* {{quote-book|title=The Passage|page=330|author=Justin Cronin|year=2010|passage="What about his eyes?" / "Nothing. No '''oranging''' at all, from what I could see.}}

===See also===
* [[citrus]]
* [[clementine]]
* [[Cointreau]]
* [[curaçao]]
* [[mandarin]]
* [[marmalade]]
* [[murcott]]
* [[naartjie]]
* [[ortanique]]
* [[pomander]]
* [[satsuma]]
* [[satsuma mandarin]]
* [[satsuma tangerine]]
* [[secondary colour]]
* [[tangerine]]
* [[triple sec]]
* [[zest]]
* [[Appendix:Colors]]

===References===
<references/>

===Anagrams===
* [[groane#English|groane]], [[onager#English|onager]]

[[Category:1000 English basic words]]
[[Category:English nouns which have interacted with their indefinite article]]
[[Category:en:Colors]]
[[Category:en:Colors of the rainbow]]
[[Category:en:Fruits]]
[[Category:en:Oranges|*]]
[[Category:en:Trees]]

----

==French==

===Etymology===
Short form of late {{etyl|fro|fr}} ''pume orenge'' or ''pomme d'orenge'', which was calqued after {{etyl|roa-oit|fr}} ''melarancia'' ({{term|mela|lang=it}} + {{term|arancia|lang=it}}). The ''o'' came into the word under influence of the place name {{term|Orange|lang=fr}}, from where these fruits came to the north.
See {{term|orange|lang=en}} (English).

===Pronunciation===
* {{IPA|/ɔ.ʁɑ̃ʒ/|lang=fr}} {{X-SAMPA|/O.RA~Z/}}
* {{audio|Fr-orange.ogg|Audio}}
* {{rhymes|ɑ̃ʒ|lang=fr}}
* {{homophones|oranges|lang=fr}}

===Noun===
{{fr-noun|f}}

# {{l|en|orange}} {{gloss|fruit}}
#: ''Il pressa l’'''orange''' afin d’en extraire du jus.''
#:: ''He squeezed the '''orange''' to extract juice from it.''

===Noun===
{{fr-noun|m}}

# {{l|en|orange}} {{gloss|color}}

====Derived terms====
* [[oranger]]
* [[w:Orangina|Orangina]]

===Adjective===
{{head|fr|adjective|g=m|g2=f|g3=inv}}

# {{l|en|orange}}
#: ''Les premiers TGV atlantiques étaient '''orange'''.''
#:: ''The first Atlantic TGV trains were '''orange'''.''

====Usage notes====
: While theoretically the adjective ''orange'' is invariable, being (originally) a colour name derived from a noun, the nonstandard plural {{term|oranges|lang=fr}} is in use.

===Anagrams===
* [[onagre#French|onagre]], [[organe#French|organe]], [[rongea#French|rongea]]

[[Category:fr:Colors]]
[[Category:fr:Fruits]]

----

==German==

===Etymology===
From the noun {{term|Orange|lang=de}}

===Pronunciation===
* {{audio|De-orange.ogg|Audio}}

===Adjective===
{{de-adj|-}}

# [[#English|orange-coloured]]

[[Category:de:Colors]]
[[Category:de:Colors of the rainbow]]

----

==Guernésiais==

===Etymology===
{{rfe|lang=roa-grn}}

===Adjective===
{{roa-grn-adj-mf}}

# [[#English|orange]]

[[Category:roa-grn:Colors]]

----

==Jèrriais==

===Etymology===
{{rfe|lang=roa-jer}}

===Adjective===
{{roa-jer-adj-mf}}

# [[#English|orange]]

[[Category:roa-jer:Colors]]

----

==Luxembourgish==

===Adjective===
{{head|lb|adjective}}

# {{l|en|orange}}

===See also===
{{list|lb|basic colors}}

[[Category:lb:Colors]]

----

==Swedish==

===Etymology===
From {{etyl|fr|sv}} {{term|orange|lang=fr}}. See ''[[#English|orange]]'' (English).

===Pronunciation===
* {{IPA|/ʊˈranɧ/|/ʊˈranɕ/|lang=sv}}
* {{audio|Sv-orange.ogg|audio}}

===Adjective===
{{rfc|use template?}}
{|style="float:right; clear:right; margin-left:10px; margin-bottom:10px; background-color:#FFFAFA; color: #8B795E; text-align:center; border: 1px solid #EEE9BF; font-size:11px; line-height:14px; font-stretch:extra-expanded;" cellpadding="3" cellspacing="1"
|- style="background-color:#EEE9BF; "
| colspan=3|'''Inflections of orange''' <br />''Comparation by {{l|sv|mer}} and {{l|sv|mest}}''
|- style="background-color:#EEE9BF; "
|-
|rowspan=2 style="background-color:#EEE9BF; "|''Indefinite<br />singular'' ||style="background-color:#EEE9BF; "|''Common''||width=65|'''orange'''
|-
|style="background-color:#EEE9BF; "|''Neuter''|| '''orange''', [[oranget]]
|-
|rowspan=2 style="background-color:#EEE9BF; "|''Definite<br />singular'' ||style="background-color:#EEE9BF; "|''Masc.''||'''orange'''
|-
|style="background-color:#EEE9BF; "|''All''||'''orange'''
|-
|colspan=2 style="background-color:#EEE9BF; " |''Plural''
| '''orange''', [[orangea]]
|}
'''orange'''

# [[orange#Adjective|orange]]

===Noun===
'''orange'''

# [[orange#Noun|orange]] {{qualifier|colour}}

[[Category:Swedish adjectives]]
[[Category:Swedish nouns]]
[[Category:sv:Colors]]

[[ar:orange]]
[[zh-min-nan:orange]]
[[ca:orange]]
[[cs:orange]]
[[cy:orange]]
[[da:orange]]
[[de:orange]]
[[et:orange]]
[[el:orange]]
[[es:orange]]
[[eo:orange]]
[[eu:orange]]
[[fa:orange]]
[[fr:orange]]
[[gl:orange]]
[[ko:orange]]
[[hy:orange]]
[[hr:orange]]
[[io:orange]]
[[id:orange]]
[[zu:orange]]
[[it:orange]]
[[kn:orange]]
[[ka:orange]]
[[sw:orange]]
[[ku:orange]]
[[lv:orange]]
[[lt:orange]]
[[li:orange]]
[[hu:orange]]
[[mg:orange]]
[[ml:orange]]
[[my:orange]]
[[fj:orange]]
[[nl:orange]]
[[ja:orange]]
[[no:orange]]
[[oc:orange]]
[[pl:orange]]
[[pt:orange]]
[[ro:orange]]
[[ru:orange]]
[[simple:orange]]
[[fi:orange]]
[[sv:orange]]
[[ta:orange]]
[[te:orange]]
[[th:orange]]
[[tr:orange]]
[[uk:orange]]
[[vi:orange]]
[[zh:orange]]

