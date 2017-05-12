package QBit::Gettext::PO;
$QBit::Gettext::PO::VERSION = '0.006';
use qbit;

use base qw(QBit::Class);

our $_SEPARATOR = '|__--HS_SEP--__|';

sub add_message {
    my ($self, %opts) = @_;

    throw Exception::BadArguments gettext('Missed required field "%s"', 'message') unless defined($opts{'message'});

    $self->{'__MESSAGES__'} ||= {};

    my $msg = $self->{'__MESSAGES__'}{join($_SEPARATOR, $opts{'context'} || '', $opts{'message'})} ||= {};

    if (keys(%$msg)) {
        push(@{$msg->{'lines'}}, "$opts{'filename'}:$opts{'line'}");
        $msg->{'plural'} = $opts{'plural'} if defined($opts{'plural'}) && !defined($msg->{'plural'});
    } else {
        push_hs($msg, hash_transform(\%opts, [qw(context message plural)]));
        $msg->{'lines'} = ["$opts{'filename'}:$opts{'line'}"];
    }
}

sub header {
    my ($self, %opts) = @_;

    my $plural_forms = $self->get_plural_forms()->{$opts{'lang'} // ''};

    my $nplurals = $plural_forms->{'nplurals'} // $opts{'nplurals'} // 'INTEGER';
    my $plural   = $plural_forms->{'plural'}   // $opts{'plural'}   // 'EXPRESSION';

    return qq{# SOME DESCRIPTIVE TITLE.
# Copyright (C) YEAR THE PACKAGE'S COPYRIGHT HOLDER
# This file is distributed under the same license as the PACKAGE package.
# FIRST AUTHOR <EMAIL\@ADDRESS>, YEAR.
#
#, fuzzy
msgid ""
msgstr ""
"Project-Id-Version: PACKAGE VERSION\\n"
"Report-Msgid-Bugs-To: \\n"
"POT-Creation-Date: YEAR-MO-DA HO:MI+ZONE\\n"
"PO-Revision-Date: YEAR-MO-DA HO:MI+ZONE\\n"
"Last-Translator: FULL NAME <EMAIL\@ADDRESS>\\n"
"Language-Team: LANGUAGE <LL\@li.org>\\n"
"Language: \\n"
"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=UTF-8\\n"
"Content-Transfer-Encoding: 8bit\\n"
"Plural-Forms: nplurals=$nplurals; plural=$plural;\\n"

}
}

sub as_string {
    my ($self, %opts) = @_;

    my $str = $self->header(%opts);

    foreach my $msg (sort {$a->{'message'} cmp $b->{'message'} || ($a->{'context'} || '') cmp($b->{'context'} || '')}
        values(%{$self->{'__MESSAGES__'}}))
    {
        $str .= "#: $_\n" foreach @{$msg->{'lines'}};

        $str .= 'msgctxt ' . __quote($msg->{'context'}) . "\n" if defined($msg->{'context'});

        $str .= 'msgid ' . __quote($msg->{'message'}) . "\n";

        if (defined($msg->{'plural'})) {
            $str .= 'msgid_plural ' . __quote($msg->{'plural'}) . "\n";
            $str .= 'msgstr[0] ""' . "\n";
            $str .= 'msgstr[1] ""' . "\n";
        } else {
            $str .= 'msgstr ""' . "\n";
        }

        $str .= "\n";
    }

    return $str;
}

sub write_to_file {
    my ($self, %opts) = @_;

    writefile($opts{'ofile'}, $self->as_string(%opts));
}

sub __quote {
    my ($str) = @_;

    for ($str) {
        s/\r//g;
        s/"/\\"/g;
    }

    if ($str =~ /\n/) {
        $str =~ s/(.*)\n/"$1\\n"\n/g;
        $str =~ s/\n([^\n]+)\z/\n"$1"/m;
        $str = qq{""\n$str};
    } else {
        $str = qq{"$str"};
    }

    return $str;
}

sub get_plural_forms {
    my ($self) = @_;

    #http://docs.translatehouse.org/projects/localization-guide/en/latest/l10n/pluralforms.html
    #[1] http://wiki.arabeyes.org/Plural_Forms
    #[2] zh means all districts and all variants of Chinese, such as zh_CN, zh_HK, zh_TW and so on.
    #[3] In rare cases where plural form introduces difference in personal pronoun (such as her vs. they, we vs. I), the plural form is different.

    return {
        'ach' => {name => 'Acholi',    nplurals => 2, plural => '(n > 1)'},
        'af'  => {name => 'Afrikaans', nplurals => 2, plural => '(n != 1)'},
        'ak'  => {name => 'Akan',      nplurals => 2, plural => '(n > 1)'},
        'am'  => {name => 'Amharic',   nplurals => 2, plural => '(n > 1)'},
        'an'  => {name => 'Aragonese', nplurals => 2, plural => '(n != 1)'},
        'anp' => {name => 'Angika',    nplurals => 2, plural => '(n != 1)'},
        'ar'  => {
            name     => 'Arabic [1]',
            nplurals => 6,
            plural   => '(n==0 ? 0 : n==1 ? 1 : n==2 ? 2 : n%100>=3 && n%100<=10 ? 3 : n%100>=11 ? 4 : 5)'
        },
        'arn' => {name => 'Mapudungun',  nplurals => 2, plural => '(n > 1)'},
        'as'  => {name => 'Assamese',    nplurals => 2, plural => '(n != 1)'},
        'ast' => {name => 'Asturian',    nplurals => 2, plural => '(n != 1)'},
        'ay'  => {name => 'Aymará',     nplurals => 1, plural => '0'},
        'az'  => {name => 'Azerbaijani', nplurals => 2, plural => '(n != 1)'},
        'be'  => {
            name     => 'Belarusian',
            nplurals => 3,
            plural   => '(n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2)'
        },
        'bg'  => {name => 'Bulgarian', nplurals => 2, plural => '(n != 1)'},
        'bn'  => {name => 'Bengali',   nplurals => 2, plural => '(n != 1)'},
        'bo'  => {name => 'Tibetan',   nplurals => 1, plural => '0'},
        'br'  => {name => 'Breton',    nplurals => 2, plural => '(n > 1)'},
        'brx' => {name => 'Bodo',      nplurals => 2, plural => '(n != 1)'},
        'bs'  => {
            name     => 'Bosnian',
            nplurals => 3,
            plural   => '(n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2)'
        },
        'ca'  => {name => 'Catalan', nplurals => 2, plural => '(n != 1)'},
        'cgg' => {name => 'Chiga',   nplurals => 1, plural => '0'},
        'cs'  => {name => 'Czech',   nplurals => 3, plural => '(n==1) ? 0 : (n>=2 && n<=4) ? 1 : 2'},
        'csb' => {
            name     => 'Kashubian',
            nplurals => 3,
            plural   => '(n==1) ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2'
        },
        'cy'  => {name => 'Welsh',    nplurals => 4, plural => '(n==1) ? 0 : (n==2) ? 1 : (n != 8 && n != 11) ? 2 : 3'},
        'da'  => {name => 'Danish',   nplurals => 2, plural => '(n != 1)'},
        'de'  => {name => 'German',   nplurals => 2, plural => '(n != 1)'},
        'doi' => {name => 'Dogri',    nplurals => 2, plural => '(n != 1)'},
        'dz'  => {name => 'Dzongkha', nplurals => 1, plural => '0'},
        'el'  => {name => 'Greek',    nplurals => 2, plural => '(n != 1)'},
        'en'  => {name => 'English',  nplurals => 2, plural => '(n != 1)'},
        'eo'    => {name => 'Esperanto',           nplurals => 2, plural => '(n != 1)'},
        'es'    => {name => 'Spanish',             nplurals => 2, plural => '(n != 1)'},
        'es_AR' => {name => 'Argentinean Spanish', nplurals => 2, plural => '(n != 1)'},
        'et'    => {name => 'Estonian',            nplurals => 2, plural => '(n != 1)'},
        'eu'    => {name => 'Basque',              nplurals => 2, plural => '(n != 1)'},
        'fa'    => {name => 'Persian',             nplurals => 1, plural => '0'},
        'ff'    => {name => 'Fulah',               nplurals => 2, plural => '(n != 1)'},
        'fi'    => {name => 'Finnish',             nplurals => 2, plural => '(n != 1)'},
        'fil'   => {name => 'Filipino',            nplurals => 2, plural => '(n > 1)'},
        'fo'    => {name => 'Faroese',             nplurals => 2, plural => '(n != 1)'},
        'fr'    => {name => 'French',              nplurals => 2, plural => '(n > 1)'},
        'fur'   => {name => 'Friulian',            nplurals => 2, plural => '(n != 1)'},
        'fy'    => {name => 'Frisian',             nplurals => 2, plural => '(n != 1)'},
        'ga'    => {
            name     => 'Irish',
            nplurals => 5,
            plural   => 'n==1 ? 0 : n==2 ? 1 : (n>2 && n<7) ? 2 :(n>6 && n<11) ? 3 : 4'
        },
        'gd' => {
            name     => 'Scottish Gaelic',
            nplurals => 4,
            plural   => '(n==1 || n==11) ? 0 : (n==2 || n==12) ? 1 : (n > 2 && n < 20) ? 2 : 3'
        },
        'gl'  => {name => 'Galician',      nplurals => 2, plural => '(n != 1)'},
        'gu'  => {name => 'Gujarati',      nplurals => 2, plural => '(n != 1)'},
        'gun' => {name => 'Gun',           nplurals => 2, plural => '(n > 1)'},
        'ha'  => {name => 'Hausa',         nplurals => 2, plural => '(n != 1)'},
        'he'  => {name => 'Hebrew',        nplurals => 2, plural => '(n != 1)'},
        'hi'  => {name => 'Hindi',         nplurals => 2, plural => '(n != 1)'},
        'hne' => {name => 'Chhattisgarhi', nplurals => 2, plural => '(n != 1)'},
        'hr'  => {
            name     => 'Croatian',
            nplurals => 3,
            plural   => '(n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2)'
        },
        'hu'  => {name => 'Hungarian',     nplurals => 2, plural => '(n != 1)'},
        'hy'  => {name => 'Armenian',      nplurals => 2, plural => '(n != 1)'},
        'ia'  => {name => 'Interlingua',   nplurals => 2, plural => '(n != 1)'},
        'id'  => {name => 'Indonesian',    nplurals => 1, plural => '0'},
        'is'  => {name => 'Icelandic',     nplurals => 2, plural => '(n%10!=1 || n%100==11)'},
        'it'  => {name => 'Italian',       nplurals => 2, plural => '(n != 1)'},
        'ja'  => {name => 'Japanese',      nplurals => 1, plural => '0'},
        'jbo' => {name => 'Lojban',        nplurals => 1, plural => '0'},
        'jv'  => {name => 'Javanese',      nplurals => 2, plural => '(n != 0)'},
        'ka'  => {name => 'Georgian',      nplurals => 1, plural => '0'},
        'kk'  => {name => 'Kazakh',        nplurals => 1, plural => '0'},
        'kl'  => {name => 'Greenlandic',   nplurals => 2, plural => '(n != 1)'},
        'km'  => {name => 'Khmer',         nplurals => 1, plural => '0'},
        'kn'  => {name => 'Kannada',       nplurals => 2, plural => '(n != 1)'},
        'ko'  => {name => 'Korean',        nplurals => 1, plural => '0'},
        'ku'  => {name => 'Kurdish',       nplurals => 2, plural => '(n != 1)'},
        'kw'  => {name => 'Cornish',       nplurals => 4, plural => '(n==1) ? 0 : (n==2) ? 1 : (n == 3) ? 2 : 3'},
        'ky'  => {name => 'Kyrgyz',        nplurals => 1, plural => '0'},
        'lb'  => {name => 'Letzeburgesch', nplurals => 2, plural => '(n != 1)'},
        'ln'  => {name => 'Lingala',       nplurals => 2, plural => '(n > 1)'},
        'lo'  => {name => 'Lao',           nplurals => 1, plural => '0'},
        'lt'  => {
            name     => 'Lithuanian',
            nplurals => 3,
            plural   => '(n%10==1 && n%100!=11 ? 0 : n%10>=2 && (n%100<10 || n%100>=20) ? 1 : 2)'
        },
        'lv'  => {name => 'Latvian',  nplurals => 3, plural => '(n%10==1 && n%100!=11 ? 0 : n != 0 ? 1 : 2)'},
        'mai' => {name => 'Maithili', nplurals => 2, plural => '(n != 1)'},
        'me'  => {
            name     => 'Montenegro',
            nplurals => 3,
            plural   => 'n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2'
        },
        'mfe' => {name => 'Mauritian Creole', nplurals => 2, plural => '(n > 1)'},
        'mg'  => {name => 'Malagasy',         nplurals => 2, plural => '(n > 1)'},
        'mi'  => {name => 'Maori',            nplurals => 2, plural => '(n > 1)'},
        'mk'  => {
            name     => 'Macedonian',
            nplurals => 2,
            plural   => ' n==1 || n%10==1 ? 0 : 1; Can’t be correct needs a 2 somewhere'
        },
        'ml'  => {name => 'Malayalam', nplurals => 2, plural => '(n != 1)'},
        'mn'  => {name => 'Mongolian', nplurals => 2, plural => '(n != 1)'},
        'mni' => {name => 'Manipuri',  nplurals => 2, plural => '(n != 1)'},
        'mnk' => {name => 'Mandinka',  nplurals => 3, plural => '(n==0 ? 0 : n==1 ? 1 : 2)'},
        'mr'  => {name => 'Marathi',   nplurals => 2, plural => '(n != 1)'},
        'ms'  => {name => 'Malay',     nplurals => 1, plural => '0'},
        'mt'  => {
            name     => 'Maltese',
            nplurals => 4,
            plural   => '(n==1 ? 0 : n==0 || ( n%100>1 && n%100<11) ? 1 : (n%100>10 && n%100<20 ) ? 2 : 3)'
        },
        'my'  => {name => 'Burmese',              nplurals => 1, plural => '0'},
        'nah' => {name => 'Nahuatl',              nplurals => 2, plural => '(n != 1)'},
        'nap' => {name => 'Neapolitan',           nplurals => 2, plural => '(n != 1)'},
        'nb'  => {name => 'Norwegian Bokmal',     nplurals => 2, plural => '(n != 1)'},
        'ne'  => {name => 'Nepali',               nplurals => 2, plural => '(n != 1)'},
        'nl'  => {name => 'Dutch',                nplurals => 2, plural => '(n != 1)'},
        'nn'  => {name => 'Norwegian Nynorsk',    nplurals => 2, plural => '(n != 1)'},
        'no'  => {name => 'Norwegian (old code)', nplurals => 2, plural => '(n != 1)'},
        'nso' => {name => 'Northern Sotho',       nplurals => 2, plural => '(n != 1)'},
        'oc'  => {name => 'Occitan',              nplurals => 2, plural => '(n > 1)'},
        'or'  => {name => 'Oriya',                nplurals => 2, plural => '(n != 1)'},
        'pa'  => {name => 'Punjabi',              nplurals => 2, plural => '(n != 1)'},
        'pap' => {name => 'Papiamento',           nplurals => 2, plural => '(n != 1)'},
        'pl'  => {
            name     => 'Polish',
            nplurals => 3,
            plural   => '(n==1 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2)'
        },
        'pms'   => {name => 'Piemontese',           nplurals => 2, plural => '(n != 1)'},
        'ps'    => {name => 'Pashto',               nplurals => 2, plural => '(n != 1)'},
        'pt'    => {name => 'Portuguese',           nplurals => 2, plural => '(n != 1)'},
        'pt_BR' => {name => 'Brazilian Portuguese', nplurals => 2, plural => '(n > 1)'},
        'rm'    => {name => 'Romansh',              nplurals => 2, plural => '(n != 1)'},
        'ro' =>
          {name => 'Romanian', nplurals => 3, plural => '(n==1 ? 0 : (n==0 || (n%100 > 0 && n%100 < 20)) ? 1 : 2)'},
        'ru' => {
            name     => 'Russian',
            nplurals => 3,
            plural   => '(n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2)'
        },
        'rw'  => {name => 'Kinyarwanda',   nplurals => 2, plural => '(n != 1)'},
        'sah' => {name => 'Yakut',         nplurals => 1, plural => '0'},
        'sat' => {name => 'Santali',       nplurals => 2, plural => '(n != 1)'},
        'sco' => {name => 'Scots',         nplurals => 2, plural => '(n != 1)'},
        'sd'  => {name => 'Sindhi',        nplurals => 2, plural => '(n != 1)'},
        'se'  => {name => 'Northern Sami', nplurals => 2, plural => '(n != 1)'},
        'si'  => {name => 'Sinhala',       nplurals => 2, plural => '(n != 1)'},
        'sk'  => {name => 'Slovak',        nplurals => 3, plural => '(n==1) ? 0 : (n>=2 && n<=4) ? 1 : 2'},
        'sl'  => {
            name     => 'Slovenian',
            nplurals => 4,
            plural   => '(n%100==1 ? 1 : n%100==2 ? 2 : n%100==3 || n%100==4 ? 3 : 0)'
        },
        'so'  => {name => 'Somali',   nplurals => 2, plural => '(n != 1)'},
        'son' => {name => 'Songhay',  nplurals => 2, plural => '(n != 1)'},
        'sq'  => {name => 'Albanian', nplurals => 2, plural => '(n != 1)'},
        'sr'  => {
            name     => 'Serbian',
            nplurals => 3,
            plural   => '(n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2)'
        },
        'su' => {name => 'Sundanese', nplurals => 1, plural => '0'},
        'sv' => {name => 'Swedish',   nplurals => 2, plural => '(n != 1)'},
        'sw' => {name => 'Swahili',   nplurals => 2, plural => '(n != 1)'},
        'ta' => {name => 'Tamil',     nplurals => 2, plural => '(n != 1)'},
        'te' => {name => 'Telugu',    nplurals => 2, plural => '(n != 1)'},
        'tg' => {name => 'Tajik',     nplurals => 2, plural => '(n > 1)'},
        'th' => {name => 'Thai',      nplurals => 1, plural => '0'},
        'ti' => {name => 'Tigrinya',  nplurals => 2, plural => '(n > 1)'},
        'tk' => {name => 'Turkmen',   nplurals => 2, plural => '(n != 1)'},
        'tr' => {name => 'Turkish',   nplurals => 2, plural => '(n > 1)'},
        'tt' => {name => 'Tatar',     nplurals => 1, plural => '0'},
        'ug' => {name => 'Uyghur',    nplurals => 1, plural => '0'},
        'uk' => {
            name     => 'Ukrainian',
            nplurals => 3,
            plural   => '(n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2)'
        },
        'ur'    => {name => 'Urdu',        nplurals => 2, plural => '(n != 1)'},
        'uz'    => {name => 'Uzbek',       nplurals => 2, plural => '(n > 1)'},
        'vi'    => {name => 'Vietnamese',  nplurals => 1, plural => '0'},
        'wa'    => {name => 'Walloon',     nplurals => 2, plural => '(n > 1)'},
        'wo'    => {name => 'Wolof',       nplurals => 1, plural => '0'},
        'yo'    => {name => 'Yoruba',      nplurals => 2, plural => '(n != 1)'},
        'zh'    => {name => 'Chinese [2]', nplurals => 1, plural => '0'},
        'zh_pp' => {name => 'Chinese [3]', nplurals => 2, plural => '(n > 1)'},
    };
}

TRUE;
