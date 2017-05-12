#!perl

use strict;
use warnings;
use utf8;
binmode STDOUT, ":encoding(utf-8)";
binmode STDIN, ":encoding(utf-8)";

use Test::More tests => 2;
use Data::Dumper;
$Data::Dumper::Deparse = 1;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

use Text::Amuse::Preprocessor::Typography qw/get_typography_filter/;

my @commons = ('ﬁ;ﬂ;ﬃ;ﬄ;ﬀ;',
               '"ﬁ;ﬂ;ﬃ;ﬄ;ﬀ;"');

my $sub = get_typography_filter(blasdfljk => 1);

my @fixed;
foreach my $l (@commons) {
    push @fixed, $sub->($l);
}
is_deeply \@fixed, [
                    'fi;fl;ffi;ffl;ff;',
                    '"fi;fl;ffi;ffl;ff;"',
                   ], "Common things fixed";

my @lines = (
             '"hello" "there"',
             'http://amusewiki.org',
             '"hello" \'there\'',
             'http://amusewiki.org',
            );

$sub = get_typography_filter(en => 1);

print Dumper($sub);

my @out;
foreach my $l (@lines) {
    push @out, $sub->($l);
}

is_deeply \@out, [
                  '“hello” “there”',
                  '[[http://amusewiki.org][amusewiki.org]]',
                  '“hello” ‘there’',
                  '[[http://amusewiki.org][amusewiki.org]]',
                 ], "Result seems ok";
