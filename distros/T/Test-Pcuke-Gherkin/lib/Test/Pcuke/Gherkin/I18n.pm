package Test::Pcuke::Gherkin::I18n;

use warnings;
use strict;

use utf8;

=head1 NAME

Test::Pcuke::Gherkin::I18n - provides internationalized regexps to the lexer

=head1 SYNOPSIS

    use Test::Pcuke::Gherkin::I18n;

    my $regexps = Test::Pcuke::Gherkin::I18n->patterns('ru');
    
    print join "\n", map { utf8::encode($_); $_ } @{ Test::Pcuke::Gherkin::I18n->languages };
    
    my $ru_info = Test::Pcuke::Gherkin::I18n->language_info('ru');
    
    foreach (@$ru_info) {
    	utf8::encode($_->[0]);
    	utf8::encode($_->[1]);
    	print join " -> ", @$_;
    }

=head1 METHODS

=head2 patterns

=cut

my $translations	= {
	'ar'	=> {
		"and"	=> "*|و",
		"background"	=> "الخلفية",
		"but"	=> "*|لكن",
		"examples"	=> "امثلة",
		"feature"	=> "خاصية",
		"given"	=> "*|بفرض",
		"name"	=> "Arabic",
		"native"	=> "العربية",
		"scenario"	=> "سيناريو",
		"outline"	=> "سيناريو مخطط",
		"then"	=> "*|اذاً|ثم",
		"when"	=> "*|متى|عندما",
	},
	'bg'	=> {
		"and"	=> "*|И",
		"background"	=> "Предистория",
		"but"	=> "*|Но",
		"examples"	=> "Примери",
		"feature"	=> "Функционалност",
		"given"	=> "*|Дадено",
		"name"	=> "Bulgarian",
		"native"	=> "български",
		"scenario"	=> "Сценарий",
		"outline"	=> "Рамка на сценарий",
		"then"	=> "*|То",
		"when"	=> "*|Когато",
	},
	'ca'	=> {
		"and"	=> "*|I",
		"background"	=> "Rerefons|Antecedents",
		"but"	=> "*|Però",
		"examples"	=> "Exemples",
		"feature"	=> "Característica|Funcionalitat",
		"given"	=> "*|Donat|Donada|Atès|Atesa",
		"name"	=> "Catalan",
		"native"	=> "català",
		"scenario"	=> "Escenari",
		"outline"	=> "Esquema de l'escenari",
		"then"	=> "*|Aleshores|Cal",
		"when"	=> "*|Quan",
	},
	'cs'	=> {
		"and"	=> "*|A|A také",
		"background"	=> "Pozadí|Kontext",
		"but"	=> "*|Ale",
		"examples"	=> "Příklady",
		"feature"	=> "Požadavek",
		"given"	=> "*|Pokud",
		"name"	=> "Czech",
		"native"	=> "Česky",
		"scenario"	=> "Scénář",
		"outline"	=> "Náčrt Scénáře|Osnova scénáře",
		"then"	=> "*|Pak",
		"when"	=> "*|Když",
	},
	'cy-GB'	=> {
		"and"	=> "*|A",
		"background"	=> "Cefndir",
		"but"	=> "*|Ond",
		"examples"	=> "Enghreifftiau",
		"feature"	=> "Arwedd",
		"given"	=> "*|Anrhegedig a",
		"name"	=> "Welsh",
		"native"	=> "Cymraeg",
		"scenario"	=> "Scenario",
		"outline"	=> "Scenario Amlinellol",
		"then"	=> "*|Yna",
		"when"	=> "*|Pryd",
	},
	'da'	=> {
		"and"	=> "*|Og",
		"background"	=> "Baggrund",
		"but"	=> "*|Men",
		"examples"	=> "Eksempler",
		"feature"	=> "Egenskab",
		"given"	=> "*|Givet",
		"name"	=> "Danish",
		"native"	=> "dansk",
		"scenario"	=> "Scenarie",
		"outline"	=> "Abstrakt Scenario",
		"then"	=> "*|Så",
		"when"	=> "*|Når",
	},
	'de'	=> {
		"and"	=> "*|Und",
		"background"	=> "Grundlage",
		"but"	=> "*|Aber",
		"examples"	=> "Beispiele",
		"feature"	=> "Funktionalität",
		"given"	=> "*|Angenommen|Gegeben sei",
		"name"	=> "German",
		"native"	=> "Deutsch",
		"scenario"	=> "Szenario",
		"outline"	=> "Szenariogrundriss",
		"then"	=> "*|Dann",
		"when"	=> "*|Wenn",
	},
	'en'	=> {
		"and"	=> "*|And",
		"background"	=> "Background",
		"but"	=> "*|But",
		"examples"	=> "Examples|Scenarios",
		"feature"	=> "Feature",
		"given"	=> "*|Given",
		"name"	=> "English",
		"native"	=> "English",
		"scenario"	=> "Scenario",
		"outline"	=> "Scenario Outline|Scenario Template",
		"then"	=> "*|Then",
		"when"	=> "*|When",
	},
	'en-Scouse'	=> {
		"and"	=> "*|An",
		"background"	=> "Dis is what went down",
		"but"	=> "*|Buh",
		"examples"	=> "Examples",
		"feature"	=> "Feature",
		"given"	=> "*|Givun|Youse know when youse got",
		"name"	=> "Scouse",
		"native"	=> "Scouse",
		"scenario"	=> "The thing of it is",
		"outline"	=> "Wharrimean is",
		"then"	=> "*|Dun|Den youse gotta",
		"when"	=> "*|Wun|Youse know like when",
	},
	'en-au'	=> {
		"and"	=> "*|N",
		"background"	=> "Background",
		"but"	=> "*|Cept",
		"examples"	=> "Cobber",
		"feature"	=> "Crikey",
		"given"	=> "*|Ya know how",
		"name"	=> "Australian",
		"native"	=> "Australian",
		"scenario"	=> "Mate",
		"outline"	=> "Blokes",
		"then"	=> "*|Ya gotta",
		"when"	=> "*|When",
	},
	'en-lol'	=> {
		"and"	=> "*|AN",
		"background"	=> "B4",
		"but"	=> "*|BUT",
		"examples"	=> "EXAMPLZ",
		"feature"	=> "OH HAI",
		"given"	=> "*|I CAN HAZ",
		"name"	=> "LOLCAT",
		"native"	=> "LOLCAT",
		"scenario"	=> "MISHUN",
		"outline"	=> "MISHUN SRSLY",
		"then"	=> "*|DEN",
		"when"	=> "*|WEN",
	},
	'en-pirate'	=> {
		"and"	=> "*|Aye",
		"background"	=> "Yo-ho-ho",
		"but"	=> "*|Avast!",
		"examples"	=> "Dead men tell no tales",
		"feature"	=> "Ahoy matey!",
		"given"	=> "*|Gangway!",
		"name"	=> "Pirate",
		"native"	=> "Pirate",
		"scenario"	=> "Heave to",
		"outline"	=> "Shiver me timbers",
		"then"	=> "*|Let go and haul",
		"when"	=> "*|Blimey!",
	},
	'en-tx'	=> {
		"and"	=> "*|And y'all",
		"background"	=> "Background",
		"but"	=> "*|But y'all",
		"examples"	=> "Examples",
		"feature"	=> "Feature",
		"given"	=> "*|Given y'all",
		"name"	=> "Texan",
		"native"	=> "Texan",
		"scenario"	=> "Scenario",
		"outline"	=> "All y'all",
		"then"	=> "*|Then y'all",
		"when"	=> "*|When y'all",
	},
	'eo'	=> {
		"and"	=> "*|Kaj",
		"background"	=> "Fono",
		"but"	=> "*|Sed",
		"examples"	=> "Ekzemploj",
		"feature"	=> "Trajto",
		"given"	=> "*|Donitaĵo",
		"name"	=> "Esperanto",
		"native"	=> "Esperanto",
		"scenario"	=> "Scenaro",
		"outline"	=> "Konturo de la scenaro",
		"then"	=> "*|Do",
		"when"	=> "*|Se",
	},
	'es'	=> {
		"and"	=> "*|Y",
		"background"	=> "Antecedentes",
		"but"	=> "*|Pero",
		"examples"	=> "Ejemplos",
		"feature"	=> "Característica",
		"given"	=> "*|Dado",
		"name"	=> "Spanish",
		"native"	=> "español",
		"scenario"	=> "Escenario",
		"outline"	=> "Esquema del escenario",
		"then"	=> "*|Entonces",
		"when"	=> "*|Cuando",
	},
	'et'	=> {
		"and"	=> "*|Ja",
		"background"	=> "Taust",
		"but"	=> "*|Kuid",
		"examples"	=> "Juhtumid",
		"feature"	=> "Omadus",
		"given"	=> "*|Eeldades",
		"name"	=> "Estonian",
		"native"	=> "eesti keel",
		"scenario"	=> "Stsenaarium",
		"outline"	=> "Raamstsenaarium",
		"then"	=> "*|Siis",
		"when"	=> "*|Kui",
	},
	'fi'	=> {
		"and"	=> "*|Ja",
		"background"	=> "Tausta",
		"but"	=> "*|Mutta",
		"examples"	=> "Tapaukset",
		"feature"	=> "Ominaisuus",
		"given"	=> "*|Oletetaan",
		"name"	=> "Finnish",
		"native"	=> "suomi",
		"scenario"	=> "Tapaus",
		"outline"	=> "Tapausaihio",
		"then"	=> "*|Niin",
		"when"	=> "*|Kun",
	},
	'fr'	=> {
		"and"	=> "*|Et",
		"background"	=> "Contexte",
		"but"	=> "*|Mais",
		"examples"	=> "Exemples",
		"feature"	=> "Fonctionnalité",
		"given"	=> "*|Soit|Etant donné",
		"name"	=> "French",
		"native"	=> "français",
		"scenario"	=> "Scénario",
		"outline"	=> "Plan du scénario|Plan du Scénario",
		"then"	=> "*|Alors",
		"when"	=> "*|Quand|Lorsque|Lorsqu'<",
	},
	'he'	=> {
		"and"	=> "*|וגם",
		"background"	=> "רקע",
		"but"	=> "*|אבל",
		"examples"	=> "דוגמאות",
		"feature"	=> "תכונה",
		"given"	=> "*|בהינתן",
		"name"	=> "Hebrew",
		"native"	=> "עברית",
		"scenario"	=> "תרחיש",
		"outline"	=> "תבנית תרחיש",
		"then"	=> "*|אז|אזי",
		"when"	=> "*|כאשר",
	},
	'hr'	=> {
		"and"	=> "*|I",
		"background"	=> "Pozadina",
		"but"	=> "*|Ali",
		"examples"	=> "Primjeri|Scenariji",
		"feature"	=> "Osobina|Mogućnost|Mogucnost",
		"given"	=> "*|Zadan|Zadani|Zadano",
		"name"	=> "Croatian",
		"native"	=> "hrvatski",
		"scenario"	=> "Scenarij",
		"outline"	=> "Skica|Koncept",
		"then"	=> "*|Onda",
		"when"	=> "*|Kada|Kad",
	},
	'hu'	=> {
		"and"	=> "*|És",
		"background"	=> "Háttér",
		"but"	=> "*|De",
		"examples"	=> "Példák",
		"feature"	=> "Jellemző",
		"given"	=> "*|Amennyiben|Adott",
		"name"	=> "Hungarian",
		"native"	=> "magyar",
		"scenario"	=> "Forgatókönyv",
		"outline"	=> "Forgatókönyv vázlat",
		"then"	=> "*|Akkor",
		"when"	=> "*|Majd|Ha|Amikor",
	},
	'id'	=> {
		"and"	=> "*|Dan",
		"background"	=> "Dasar",
		"but"	=> "*|Tapi",
		"examples"	=> "Contoh",
		"feature"	=> "Fitur",
		"given"	=> "*|Dengan",
		"name"	=> "Indonesian",
		"native"	=> "Bahasa Indonesia",
		"scenario"	=> "Skenario",
		"outline"	=> "Skenario konsep",
		"then"	=> "*|Maka",
		"when"	=> "*|Ketika",
	},
	'it'	=> {
		"and"	=> "*|E",
		"background"	=> "Contesto",
		"but"	=> "*|Ma",
		"examples"	=> "Esempi",
		"feature"	=> "Funzionalità",
		"given"	=> "*|Dato",
		"name"	=> "Italian",
		"native"	=> "italiano",
		"scenario"	=> "Scenario",
		"outline"	=> "Schema dello scenario",
		"then"	=> "*|Allora",
		"when"	=> "*|Quando",
	},
	'ja'	=> {
		"and"	=> "*|かつ<",
		"background"	=> "背景",
		"but"	=> "*|しかし<|但し<|ただし<",
		"examples"	=> "例|サンプル",
		"feature"	=> "フィーチャ|機能",
		"given"	=> "*|前提<",
		"name"	=> "Japanese",
		"native"	=> "日本語",
		"scenario"	=> "シナリオ",
		"outline"	=> "シナリオアウトライン|シナリオテンプレート|テンプレ|シナリオテンプレ",
		"then"	=> "*|ならば<",
		"when"	=> "*|もし<",
	},
	'ko'	=> {
		"and"	=> "*|그리고<",
		"background"	=> "배경",
		"but"	=> "*|하지만<|단<",
		"examples"	=> "예",
		"feature"	=> "기능",
		"given"	=> "*|조건<|먼저<",
		"name"	=> "Korean",
		"native"	=> "한국어",
		"scenario"	=> "시나리오",
		"outline"	=> "시나리오 개요",
		"then"	=> "*|그러면<",
		"when"	=> "*|만일<|만약<",
	},
	'lt'	=> {
		"and"	=> "*|Ir",
		"background"	=> "Kontekstas",
		"but"	=> "*|Bet",
		"examples"	=> "Pavyzdžiai|Scenarijai|Variantai",
		"feature"	=> "Savybė",
		"given"	=> "*|Duota",
		"name"	=> "Lithuanian",
		"native"	=> "lietuvių kalba",
		"scenario"	=> "Scenarijus",
		"outline"	=> "Scenarijaus šablonas",
		"then"	=> "*|Tada",
		"when"	=> "*|Kai",
	},
	'lu'	=> {
		"and"	=> "*|an|a",
		"background"	=> "Hannergrond",
		"but"	=> "*|awer|mä",
		"examples"	=> "Beispiller",
		"feature"	=> "Funktionalitéit",
		"given"	=> "*|ugeholl",
		"name"	=> "Luxemburgish",
		"native"	=> "Lëtzebuergesch",
		"scenario"	=> "Szenario",
		"outline"	=> "Plang vum Szenario",
		"then"	=> "*|dann",
		"when"	=> "*|wann",
	},
	'lv'	=> {
		"and"	=> "*|Un",
		"background"	=> "Konteksts|Situācija",
		"but"	=> "*|Bet",
		"examples"	=> "Piemēri|Paraugs",
		"feature"	=> "Funkcionalitāte|Fīča",
		"given"	=> "*|Kad",
		"name"	=> "Latvian",
		"native"	=> "latviešu",
		"scenario"	=> "Scenārijs",
		"outline"	=> "Scenārijs pēc parauga",
		"then"	=> "*|Tad",
		"when"	=> "*|Ja",
	},
	'nl'	=> {
		"and"	=> "*|En",
		"background"	=> "Achtergrond",
		"but"	=> "*|Maar",
		"examples"	=> "Voorbeelden",
		"feature"	=> "Functionaliteit",
		"given"	=> "*|Gegeven|Stel",
		"name"	=> "Dutch",
		"native"	=> "Nederlands",
		"scenario"	=> "Scenario",
		"outline"	=> "Abstract Scenario",
		"then"	=> "*|Dan",
		"when"	=> "*|Als",
	},
	'no'	=> {
		"and"	=> "*|Og",
		"background"	=> "Bakgrunn",
		"but"	=> "*|Men",
		"examples"	=> "Eksempler",
		"feature"	=> "Egenskap",
		"given"	=> "*|Gitt",
		"name"	=> "Norwegian",
		"native"	=> "norsk",
		"scenario"	=> "Scenario",
		"outline"	=> "Scenariomal|Abstrakt Scenario",
		"then"	=> "*|Så",
		"when"	=> "*|Når",
	},
	'pl'	=> {
		"and"	=> "*|Oraz|I",
		"background"	=> "Założenia",
		"but"	=> "*|Ale",
		"examples"	=> "Przykłady",
		"feature"	=> "Właściwość",
		"given"	=> "*|Zakładając|Mając",
		"name"	=> "Polish",
		"native"	=> "polski",
		"scenario"	=> "Scenariusz",
		"outline"	=> "Szablon scenariusza",
		"then"	=> "*|Wtedy",
		"when"	=> "*|Jeżeli|Jeśli",
	},
	'pt'	=> {
		"and"	=> "*|E",
		"background"	=> "Contexto",
		"but"	=> "*|Mas",
		"examples"	=> "Exemplos",
		"feature"	=> "Funcionalidade",
		"given"	=> "*|Dado",
		"name"	=> "Portuguese",
		"native"	=> "português",
		"scenario"	=> "Cenário|Cenario",
		"outline"	=> "Esquema do Cenário|Esquema do Cenario",
		"then"	=> "*|Então|Entao",
		"when"	=> "*|Quando",
	},
	'ro'	=> {
		"and"	=> "*|Si|Și|Şi",
		"background"	=> "Context",
		"but"	=> "*|Dar",
		"examples"	=> "Exemple",
		"feature"	=> "Functionalitate|Funcționalitate|Funcţionalitate",
		"given"	=> "*|Date fiind|Dat fiind|Dati fiind|Dați fiind|Daţi fiind",
		"name"	=> "Romanian",
		"native"	=> "română",
		"scenario"	=> "Scenariu",
		"outline"	=> "Structura scenariu|Structură scenariu",
		"then"	=> "*|Atunci",
		"when"	=> "*|Cand|Când",
	},
	'ru'	=> {
		"and"	=> "*|И|К тому же",
		"background"	=> "Предыстория|Контекст",
		"but"	=> "*|Но|А",
		"examples"	=> "Примеры",
		"feature"	=> "Функция|Функционал|Свойство",
		"given"	=> "*|Допустим|Дано|Пусть",
		"name"	=> "Russian",
		"native"	=> "русский",
		"scenario"	=> "Сценарий",
		"outline"	=> "Структура сценария",
		"then"	=> "*|То|Тогда",
		"when"	=> "*|Если|Когда",
	},
	'sk'	=> {
		"and"	=> "*|A",
		"background"	=> "Pozadie",
		"but"	=> "*|Ale",
		"examples"	=> "Príklady",
		"feature"	=> "Požiadavka",
		"given"	=> "*|Pokiaľ",
		"name"	=> "Slovak",
		"native"	=> "Slovensky",
		"scenario"	=> "Scenár",
		"outline"	=> "Náčrt Scenáru",
		"then"	=> "*|Tak",
		"when"	=> "*|Keď",
	},
	'sr-Cyrl'	=> {
		"and"	=> "*|И",
		"background"	=> "Контекст|Основа|Позадина",
		"but"	=> "*|Али",
		"examples"	=> "Примери|Сценарији",
		"feature"	=> "Функционалност|Могућност|Особина",
		"given"	=> "*|Задато|Задате|Задати",
		"name"	=> "Serbian",
		"native"	=> "Српски",
		"scenario"	=> "Сценарио|Пример",
		"outline"	=> "Структура сценарија|Скица|Концепт",
		"then"	=> "*|Онда",
		"when"	=> "*|Када|Кад",
	},
	'sr-Latn'	=> {
		"and"	=> "*|I",
		"background"	=> "Kontekst|Osnova|Pozadina",
		"but"	=> "*|Ali",
		"examples"	=> "Primeri|Scenariji",
		"feature"	=> "Funkcionalnost|Mogućnost|Mogucnost|Osobina",
		"given"	=> "*|Zadato|Zadate|Zatati",
		"name"	=> "Serbian (Latin)",
		"native"	=> "Srpski (Latinica)",
		"scenario"	=> "Scenario|Primer",
		"outline"	=> "Struktura scenarija|Skica|Koncept",
		"then"	=> "*|Onda",
		"when"	=> "*|Kada|Kad",
	},
	'sv'	=> {
		"and"	=> "*|Och",
		"background"	=> "Bakgrund",
		"but"	=> "*|Men",
		"examples"	=> "Exempel",
		"feature"	=> "Egenskap",
		"given"	=> "*|Givet",
		"name"	=> "Swedish",
		"native"	=> "Svenska",
		"scenario"	=> "Scenario",
		"outline"	=> "Abstrakt Scenario|Scenariomall",
		"then"	=> "*|Så",
		"when"	=> "*|När",
	},
	'tr'	=> {
		"and"	=> "*|Ve",
		"background"	=> "Geçmiş",
		"but"	=> "*|Fakat|Ama",
		"examples"	=> "Örnekler",
		"feature"	=> "Özellik",
		"given"	=> "*|Diyelim ki",
		"name"	=> "Turkish",
		"native"	=> "Türkçe",
		"scenario"	=> "Senaryo",
		"outline"	=> "Senaryo taslağı",
		"then"	=> "*|O zaman",
		"when"	=> "*|Eğer ki",
	},
	'uk'	=> {
		"and"	=> "*|І|А також|Та",
		"background"	=> "Передумова",
		"but"	=> "*|Але",
		"examples"	=> "Приклади",
		"feature"	=> "Функціонал",
		"given"	=> "*|Припустимо|Припустимо, що|Нехай|Дано",
		"name"	=> "Ukrainian",
		"native"	=> "Українська",
		"scenario"	=> "Сценарій",
		"outline"	=> "Структура сценарію",
		"then"	=> "*|То|Тоді",
		"when"	=> "*|Якщо|Коли",
	},
	'uz'	=> {
		"and"	=> "*|Ва",
		"background"	=> "Тарих",
		"but"	=> "*|Лекин|Бирок|Аммо",
		"examples"	=> "Мисоллар",
		"feature"	=> "Функционал",
		"given"	=> "*|Агар",
		"name"	=> "Uzbek",
		"native"	=> "Узбекча",
		"scenario"	=> "Сценарий",
		"outline"	=> "Сценарий структураси",
		"then"	=> "*|Унда",
		"when"	=> "*|Агар",
	},
	'vi'	=> {
		"and"	=> "*|Và",
		"background"	=> "Bối cảnh",
		"but"	=> "*|Nhưng",
		"examples"	=> "Dữ liệu",
		"feature"	=> "Tính năng",
		"given"	=> "*|Biết|Cho",
		"name"	=> "Vietnamese",
		"native"	=> "Tiếng Việt",
		"scenario"	=> "Tình huống|Kịch bản",
		"outline"	=> "Khung tình huống|Khung kịch bản",
		"then"	=> "*|Thì",
		"when"	=> "*|Khi",
	},
	'zh-CN'	=> {
		"and"	=> "*|而且<",
		"background"	=> "背景",
		"but"	=> "*|但是<",
		"examples"	=> "例子",
		"feature"	=> "功能",
		"given"	=> "*|假如<",
		"name"	=> "Chinese simplified",
		"native"	=> "简体中文",
		"scenario"	=> "场景",
		"outline"	=> "场景大纲",
		"then"	=> "*|那么<",
		"when"	=> "*|当<",
	},
	'zh-TW'	=> {
		"and"	=> "*|而且<|並且<",
		"background"	=> "背景",
		"but"	=> "*|但是<",
		"examples"	=> "例子",
		"feature"	=> "功能",
		"given"	=> "*|假設<",
		"name"	=> "Chinese traditional",
		"native"	=> "繁體中文",
		"scenario"	=> "場景|劇本",
		"outline"	=> "場景大綱|劇本大綱",
		"then"	=> "*|那麼<",
		"when"	=> "*|當<",
	},
};

my $keywdot = q{^ \s* ( <KEYWORD> : .*?) \s* $};
my $step = q{^ \s* ( <KEYWORD> ) \s* (.*?) \s* $};

my %PATTERNS = (
	empty		=> q{^\s*$},
	pragma		=> q{^\s*#(?:\s*(\w+\s*:\s*\w+))+},
	comment		=> q{^\s*#},
	tag			=> q{@\w+},
	any			=> q{^\s*(.*?)\s*$},
	feature		=> $keywdot,
	background	=> $keywdot,
	scenario	=> $keywdot,
	outline		=> $keywdot,
	examples	=> $keywdot,
	given		=> $step,
	when		=> $step,
	then		=> $step,
	and			=> $step,
	but			=> $step,
	trow		=> q{^\s*\|(.*?)\|\s*$},
	text_quote	=> q{^\s*(""")\s*$},
);

sub patterns {
	my ($self, $lang) = @_;
	my $regexps;
	
	my %translations = %{ $translations->{$lang} };
	
	foreach my $key ( keys %PATTERNS ) {
		
		my $pattern = $PATTERNS{$key};
		
		if ( exists $translations{$key} ) {
			# translate
			my @keywords = split /\|/, $translations{$key};
			foreach (@keywords) {
				my $regexp = $pattern;
				my $replace = quotemeta;
				$regexp =~ s/<KEYWORD>/$replace/;
				push @{ $regexps->{$key} }, qr{$regexp}ix;
			}
		}
		else {
			push @{ $regexps->{$key} }, qr{$pattern}i;
		}
		
	}
	
	return $regexps;
}

sub languages {
	return [
		sort map { "$_ => $translations->{$_}->{name} ($translations->{$_}->{native})" } ( keys %$translations )
	]; 
}

sub language_info {
	my ($self, $lang) = @_;
	$lang ||= 'en';
	
	my $translation = $translations->{$lang};
	my @result;
	
	for ( qw{feature background scenario outline examples given when then and but} ) {
		my $translated =  '"' . join( '", "', ( split /\|/, $translation->{$_} ) ) . '"';
		push @result, [$_, $translated ];
	}
	return [@result];
}

=head1 AUTHOR

Andrei V. Toutoukine, C<< <tut at isuct.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-/home/tut/bin/src/test-pcuke-gherkin at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=/home/tut/bin/src/Test-Pcuke-Gherkin>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Pcuke::Gherkin::I18n


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=/home/tut/bin/src/Test-Pcuke-Gherkin>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist//home/tut/bin/src/Test-Pcuke-Gherkin>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d//home/tut/bin/src/Test-Pcuke-Gherkin>

=item * Search CPAN

L<http://search.cpan.org/dist//home/tut/bin/src/Test-Pcuke-Gherkin/>

=back


=head1 ACKNOWLEDGEMENTS

The essential part of this file is borrowed from the original
cucumber-gherkin project L<https://github.com/cucumber/gherkin>,
lib/gherkin/i18n.yml

The origiginal license of the cucumber-gherkin project follows:

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009-2011 Mike Sassak, Gregory Hnatiuk, Aslak Hellesøy

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


=cut

1; # End of Test::Pcuke::Gherkin::I18n
