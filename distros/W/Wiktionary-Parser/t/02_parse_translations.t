#! /usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;

use Test::More tests => 20;
use Wiktionary::Parser::Section::Translations;
use Wiktionary::Parser::Document;

my @first = (
	'{{trans-top|test-word-sense}}',
);

my @lines = (
 	{
 	 input => '* Swedish: {{t+|sv|apelsin|c}}',
 	 output => \&result_sv,
 	},
	{
	 input => '* Persian: {{t+|fa|نارنج|tr=nâranj|xs=Persian}}, {{t+|fa|پرتقال|tr=porteghâl|xs=Persian}}',
	 output => \&result_fa,
	},
	{
	 input => '* Slovene: [[oranževec]] {{m}}',
	 output => \&result_sl,
	},
	{
	 input => "* Arabic: {{t|ar|برتقالة|f|tr=burtuqaala|sc=Arab}}, {{qualifier|collective}} {{t|ar|برتقال|m|tr=burtuqaal|sc=Arab}}",
	 output => \&result_ar,
	},
	{ 
	 input => "*: Egyptian Arabic: {{tø|arz|برتقان|tr=burtuʕaan|sc=Arab|xs=Egyptian Arabic}} ''(collective)''",
	 output => \&result_arz,
	},
	{
	 input  => '* Chinese:',
	 output => \&result_zh,
	},
	{
	 input => '*: Mandarin: {{t-|cmn|橙|tr=chéng|sc=Hani}}, {{t|cmn|橙子|tr=chéngzi|sc=Hani}}, {{qualifier|technically "tangerine", but often used as "orange"}} {{t-|cmn|橘子|tr=júzi|sc=Hani}}, {{qualifier|alternative form:}} {{t|cmn|桔子|tr=júzi|sc=Hani}}',
	 output => \&result_cmn,
	},

	{
	 input => '*: Mandarin: {{t-|cmn|橙|tr=chéng|sc=Hani}}, {{t|cmn|橙子|tr=chéngzi|sc=Hani}}, {{qualifier|technically "tangerine", but often used as "orange"}} {{t-|cmn|橘子|tr=júzi|sc=Hani}}, {{qualifier|alternative form:}} {{t|cmn|桔子|tr=júzi|sc=Hani}}',
	 output => \&result_cmn_no_transliteration,
	 options => {'include_transliterations' => 0},
	},
	{
	 input => '* Kurdish: {{t+|ku|pirteqal}}, {{ku-Arab|[[پرته‌قاڵ]]}',
	 output => \&result_ku,
	},
	{
	 input => '* Scottish Gaelic: [[òr-mheas]] {{m}}, {{t-|gd|oraindsear|m|xs=Scottish Gaelic}}',
	 output => \&result_gd,
	},
	{
	 input => '* Sindhi: {{sd-Arab|[[نارنگِي]]}} (narangi) {{f}} ',
	 output => \&result_sd,	 
	},
	{
	 input => '* Spanish: {{t+|es|naranja|f}}, {{t+|es|china|f}} {{qualifier|Dominican Republic|Puerto Rico}}',
	 output => \&result_es,
	},
	{
	 input => '* Tetum: [[sabraka]]',
	 output => \&result_tet,
	},
	{
	 input => '* Vietnamese: ([[quả]] / [[trái]]) {{t+|vi|cam|xs=Vietnamese}}',
	 output => \&result_vi,
	},
	{
	 input => '* Vietnamese: [[màu]] ([[da]]) [[cam]]',
	 output => \&result_vi2,
	},
	{
	 input => '* Sardinian: [[colore de aranzu]], [[ruggiu]], [[ruiu]], [[arrubiu]]',
	 output => \&result_sc,
	},
	{ 
	 input => '* Irish: [[dath oráiste]] {{m}}, {{t|ga|oráiste}}',
	 output => \&result_ga, 
	},
	{
	 input => '*: [[Egyptian Arabic]]: {{tø|arz|كلب|m|tr=kalb|sc=Arab}}',
	 output => \&result_arz2,
	},
	{
	 input => '* Ojibwe: [[ᐊᓂᒧᔥ]] ([[animosh]]) {{s}}, [[ᐊᓂᒧᔕᒃ]] ([[animoshag]]) {{p}}',	 
	 output => \&result_oj
	},
	{
	 input => '*: Hebrew: [[כלבא]] (kalbā’) {{m}}, [[כלבתא]] (kalbtā’) {{f}}',
	 output => \&result_he,
	},

);

for my $hr (@lines) {
	my $pos_section = Wiktionary::Parser::Section::Translations->new(
		section_number => '1.1',
		header => 'noun',
	);


	my $section = Wiktionary::Parser::Section::Translations->new(
		section_number => '1.1.1',
		header => 'translations',
	);

	for my $_line (@first,$hr->{input}) {
		$section->add_content($_line);
	}

	my $document = Wiktionary::Parser::Document->new(
		sections => [$section,$pos_section],
	);

	my $options = $hr->{options} || {};

	unless(is_deeply(
		$document->get_translations(%$options),
		$hr->{output}->(),
		"parsed $hr->{input}",
	)) {
	#	print Dumper {actual => $document->get_translations()};
	#	print Dumper {fixture => $hr->{output}->()}
	}
}



sub result_sv {
    return {
        'test-word-sense' => {
            'sv' => {
                'part_of_speech' => 'noun',
                'language'     => 'Swedish',
                'translations' => [ 'apelsin' ]
            }
        }
    };
}

sub result_fa {
    return {
        'test-word-sense' => {
            'fa' => {
                'part_of_speech' => 'noun',
                'language'     => 'Persian',
                'translations' => [ 'porteghâl', 'نارنج', 'پرتقال' ]
            }
        }
    };
}

sub result_sl {
    return {
        'test-word-sense' => {
            'sl' => {
                'part_of_speech' => 'noun',
                'language'     => 'Slovenian',
                'translations' => ['oranževec'],
            }
        }
    };
}

sub result_ar {
    return {
        'test-word-sense' => {
            'ar' => {
                'part_of_speech' => 'noun',
                'language' => 'Arabic',
                'translations' => ['burtuqaal', 'برتقال' , 'برتقالة' ]
            }
        }
    };
}

sub result_arz {
    return {
        'test-word-sense' => {
            'arz' => {
                'part_of_speech' => 'noun',
                'language'     => 'Egyptian Arabic',
                'translations' => ['burtuʕaan', 'برتقان' ]
            }
        }
    };
}

sub result_zh {
    return {};
}

sub result_cmn {
    return {
        'test-word-sense' => {
            'cmn' => {
                'part_of_speech' => 'noun',
                'language'     => 'Mandarin Chinese',
                'translations' => ['júzi',
                     '桔子','橘子', '橙', '橙子',
                ]
            }
        }
    };
}

sub result_cmn_no_transliteration {
    return {
        'test-word-sense' => {
            'cmn' => {
                'part_of_speech' => 'noun',
                'language'     => 'Mandarin Chinese',
                'translations' => [
                     '桔子','橘子', '橙', '橙子',
                ]
            }
        }
    };
}


sub result_ku {
    return {
        'test-word-sense' => {
            'ku' => {
                'part_of_speech' => 'noun',
                'language'     => 'Kurdish',
                'translations' => [ 'pirteqal', 'پرته‌قاڵ' ]
            }
        }
    };
}

sub result_gd {
    return {
        'test-word-sense' => {
            'gd' => {
                'part_of_speech' => 'noun',
                'language'     => 'Gaelic',
                'translations' => [ 'oraindsear', 'òr-mheas' ]
            }
        }
    };
}

sub result_sd {
    return {
        'test-word-sense' => {
            'sd' => {
                'part_of_speech' => 'noun',
                'language'     => 'Sindhi',
                'translations' => [  'narangi', 'نارنگِي'  ]
            }
        }
    };
}

sub result_es {
    return {
        'test-word-sense' => {
            'es' => {
                'part_of_speech' => 'noun',
                'language'     => 'Spanish',
                'translations' => [ 'china', 'naranja']
            }
        }
    };
}

sub result_tet {
    return {
        'test-word-sense' => {
            'tet' => {
                'part_of_speech' => 'noun',
                'language'     => 'Tetum',
                'translations' => [ 'sabraka' ]
            }
        }
    };
}

sub result_vi {
    return {
        'test-word-sense' => {
            'vi' => {
                'part_of_speech' => 'noun',
                'language'     => 'Vietnamese',
                'translations' => [ 'cam', 'quả', 'trái' ]
            }
        }
    };
}

sub result_vi2 {
    return {
        'test-word-sense' => {
            'vi' => {
                'part_of_speech' => 'noun',
                'language'     => 'Vietnamese',
                'translations' => [  'cam', 'da', 'màu' ]
            }
        }
    };
}

sub result_sc {
    return {
        'test-word-sense' => {
            'sc' => {
                'part_of_speech' => 'noun',
                'language' => 'Sardinian',
                'translations' =>
                  [ 'arrubiu', 'colore de aranzu', 'ruggiu', 'ruiu' ]
            }
        }
    };

}

sub result_ga {
    return {
        'test-word-sense' => {
            'ga' => {
                'part_of_speech' => 'noun',
                'language'     => 'Irish',
                'translations' => [ 'dath oráiste', 'oráiste' ]
            }
        }
    };
}

sub result_arz2 {
    return {
        'test-word-sense' => {
            'arz' => {
                'part_of_speech' => 'noun',
                'language'     => 'Egyptian Arabic',
                'translations' => [ 'kalb', 'كلب' ]
            }
        }
    };
}

sub result_oj {
    return {
        'test-word-sense' => {
            'oj' => {
                'part_of_speech' => 'noun',
                'language' => 'Ojibwa',
                'translations' =>
                  [ 'animoshag', 'ᐊᓂᒧᔕᒃ', 'ᐊᓂᒧᔥ' ]
            }
        }
    };
}


sub result_he {
    return {
        'test-word-sense' => {
            'he' => {
                'part_of_speech' => 'noun',
                'language'     => 'Hebrew',
                'translations' => [ 'kalbtā’', 'כלבא', 'כלבתא' ]
            }
        }
    };
}
