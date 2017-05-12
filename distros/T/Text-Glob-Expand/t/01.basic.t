#!/usr/bin/perl
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use Text::Glob::Expand qw(explode);
use Test::More tests => 35;

my @cases = (
    ["aaa" => ["aaa"],
     ".%0." => [".aaa."]],
    ["a{a}a" => ["aaa"],
     ".%0.%1." => [".aaa.a."]],
    ["a{a}a{b}" => ["aaab"],
     ".%0.%1.%2" => [qw(.aaab.a.b)]],
    ["a{a,b}a{b,a}" => [qw(aaab aaaa abab abaa)],
     ".%0.%1.%2." => [qw(.aaab.a.b. .aaaa.a.a. .abab.b.b. .abaa.b.a.)]],
    ["a{a,a{b,a}}" => [qw(aa aab aaa)],
     ".%0.%1." => [qw(.aa.a. .aab.ab. .aaa.aa.)]],
    ["a{a{},a{b,a}}" => [qw(aa aab aaa)],
     ".%0.%1.%1.1." => [qw(.aa.a.. .aab.ab.b. .aaa.aa.a.)]],
    ["a{a{b,c},d{e,f}}" => [qw(aab aac ade adf)],
     ".%0.%1.%1.1." => [qw(.aab.ab.b. .aac.ac.c. .ade.de.e. .adf.df.f.)]],
#    ["a{a,b{a{b,a}}" => qw(aaab aaaa abab abaa)], # FIXME add this error case
);


for my $case (@cases) {
    my ($expr, $expected) = splice @$case, 0, 2;

    # check a simple glob expansion
#    my $glob = Text::Glob::Expand->parse($expr);
#    isa_ok $glob, "Text::Glob::Expand";
#    my $result = $glob->explode;
#    is_deeply $result, $expected, "simple case: $expr ok";

#    is_deeply [explode $expr], $expected, "simple functional case: $expr ok";


    # check the structured glob expansion is equivalent
    my $glob = Text::Glob::Expand->parse($expr);
    isa_ok $glob, "Text::Glob::Expand";
    my $result = $glob->explode;
    my $text_result = [map { $_->text } @$result];
    is_deeply $text_result, $expected, "structured case: $expr ok";

    # check the structured glob formatting
    while(my ($format, $fmt_expected) = splice @$case, 0, 2) {
        my $fmt_result = [map { $_->expand($format) } @$result];
        is_deeply $fmt_result, $fmt_expected, "formatting case: $format => $expr ok";

        my $hash_result = $glob->explode_format($format);

        is_deeply [sort keys %$hash_result], [sort @$expected], 
            "hashed keys match: $format => $expr ok"; 
        is_deeply [sort values %$hash_result], [sort @$fmt_expected], 
            "hashed values match: $format => $expr ok"; 

 #       is_deeply [explode $expr, $format], $expected, "formatting functional case: $format => $expr ok";
    }

}

