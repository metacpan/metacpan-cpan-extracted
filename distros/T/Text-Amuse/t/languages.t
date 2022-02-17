use strict;
use warnings;
use utf8;
use Test::More;
use Text::Amuse;
use File::Temp;
use Text::Amuse::Utils;
use Data::Dumper;
binmode STDOUT, ":encoding(utf-8)";
binmode STDERR, ":encoding(utf-8)";

# this really sucks
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";



my %langs = (
             en => 'english',
             it => 'italian',
             sr => 'serbian',
             hr => 'croatian',
             ru => 'russian',
             es => 'spanish',
             pt => 'portuguese',
             de => 'german',
             fr => 'french',
             nl => 'dutch',
             mk => 'macedonian',
             sv => 'swedish',
             pl => 'polish',
             sq => 'albanian',
             id => 'indonesian',
             el => 'greek',
             eo => 'esperanto',
             zh => 'chinese',
             ja => 'japanese',
             ko => 'korean',
             th => 'thai',
             km => 'khmer',
             my => 'burmese',
             ms => 'malay',
             # tl => 'filipino',
            );

plan tests => 369;

foreach my $k (keys %langs) {
    test_lang($k, $k, $langs{$k});
}

foreach my $fake ("asxx", "lòasdf", "alkd", "alksdàa", "aàsdflk",  "aasdfà",  "aòlsdf" , "laò") {
    test_lang($fake, en => "english");
    # print $fake, "\n";
}



sub test_lang {
    my ($lang, $expected_code, $expected_lang) = @_;
    my $fh = File::Temp->new(TEMPLATE => "musetestXXXXXX",
                             SUFFIX => ".muse",
                             TMPDIR => 1);
    binmode $fh, ":encoding(utf-8)";
    print $fh "#title test lang $lang\n#lang $lang\n\nHello\n";
    close $fh;
    # print $fh->filename, "\n";
    my $doc = Text::Amuse->new(file => $fh->filename);
    # print $fh->filename, " => $lang => $expected_lang\n";
    is($doc->language_code, $expected_code, "$lang is $expected_code");
    is($doc->language, $expected_lang, "$lang is $expected_lang");
    is_deeply($doc->header_as_html, {title => "test lang $lang",
                                     lang => $lang}, "header OK");
    is($doc->as_html, "\n<p>\nHello\n</p>\n", "body ok");

    # ok($doc->as_html);
    my $other = File::Temp->new(TEMPLATE => "musetestXXXXXX",
                                SUFFIX => ".muse",
                                TMPDIR => 1);
    binmode $other, ":encoding(utf-8)";
    print $other "#title test language      $lang\n#language    $lang\n\nHello\n";
    close $other;
    $doc = Text::Amuse->new(file => $other->filename);
    # print $fh->filename, " => $lang => $expected_lang\n";
    is($doc->language_code, $expected_code, "$lang is $expected_code");
    is($doc->language, $expected_lang, "$lang is $expected_lang");
    is_deeply($doc->header_as_html, {title => "test language $lang",
                                     language => $lang}, "header OK");
    is($doc->as_latex, "\nHello\n\n", "body ok");
    ok(!$doc->other_language_codes);
    ok(!$doc->other_languages);
    ok !$doc->is_bidi;
    if ($lang eq 'en') {
        $doc->document->_add_to_other_language_codes('en');
        $doc->document->_add_to_other_language_codes('xx');
        $doc->document->_add_to_other_language_codes('hr');
        is_deeply $doc->other_languages, [ 'croatian' ], "Found other languages";
        is_deeply $doc->other_language_codes, [ 'hr' ], "Found other language codes";
    }
}

{
    my $fh = File::Temp->new(TEMPLATE => "musetestXXXXXX",
                             SUFFIX => ".muse",
                             TMPDIR => 1);
    my $muse =<<'MUSE';
#title test lang
#lang en

Hello

<[hr]>

Test

</[hr]>

Test

<[it]>

Hello <[fr]>Ćao</[fr]> inlined.

<[ar]>Ciao</[ar]>

MUSE
    binmode $fh, ":encoding(utf-8)";
    print $fh $muse;
    close $fh;
    # print $fh->filename, "\n";
    my $doc = Text::Amuse->new(file => $fh->filename,
                               debug => 1);
    # diag Dumper($doc->document->elements);
    is $doc->language_code, "en";
    is_deeply $doc->other_language_codes, [qw/hr it fr ar/];
    my $html = $doc->as_html;
    my $latex = $doc->as_latex;
    like $latex, qr/croatian/;
    like $latex, qr/italian/;
    like $latex, qr/french/;
    like $html, qr/<div lang="hr">.*<span lang="fr">/s;
    is_deeply $doc->other_languages, [qw/croatian italian french arabic/];
    ok $doc->is_bidi;
    diag $latex;
    diag $html;
}

ok Text::Amuse::Utils::has_babel_ldf('it');
ok Text::Amuse::Utils::has_babel_ldf('italian');
ok !Text::Amuse::Utils::has_babel_ldf('zh');
ok !Text::Amuse::Utils::has_babel_ldf('chinese');
ok Text::Amuse::Utils::has_babel_ldf('croatian');
ok Text::Amuse::Utils::lang_code_is_rtl('ar');
ok !Text::Amuse::Utils::lang_code_is_rtl('it');
