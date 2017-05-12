use strict;
use warnings;
use utf8;
use Test::More;
use Text::Amuse;
use File::Temp;
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
             pt => 'portuges',
             de => 'german',
             fr => 'french',
             nl => 'dutch',
             mk => 'macedonian',
             sv => 'swedish',
             pl => 'polish',
             sq => 'albanian',
            );

plan tests => (scalar(keys %langs) + 8) * 10;

foreach my $k (keys %langs) {
    test_lang($k, $k, $langs{$k});
}

foreach my $fake ("as", "lòasdf", "alkd", "alksdàa", "aàsdflk",  "aasdfà",  "aòlsdf" , "laò") {
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
    print $other "#title test language  $lang\n#language    $lang\n\nHello\n";
    close $other;
    $doc = Text::Amuse->new(file => $other->filename);
    # print $fh->filename, " => $lang => $expected_lang\n";
    is($doc->language_code, $expected_code, "$lang is $expected_code");
    is($doc->language, $expected_lang, "$lang is $expected_lang");
    is_deeply($doc->header_as_html, {title => "test language  $lang",
                                     language => $lang}, "header OK");
    is($doc->as_latex, "\nHello\n\n", "body ok");
    ok(!$doc->other_language_codes);
    ok(!$doc->other_languages);
}

