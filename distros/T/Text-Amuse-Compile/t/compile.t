#!perl
use strict;
use warnings;
use utf8;
use Test::More tests => 17;

use Text::Amuse::Compile;

my $compile;

$compile = Text::Amuse::Compile->new(pdf  => 1);

ok($compile->pdf);
foreach my $m (qw/a4_pdf lt_pdf epub html bare_html tex zip/) {
    ok(!$compile->$m, "$m is false");
}

ok(!$compile->epub);

$compile = Text::Amuse::Compile->new;

foreach my $m (qw/pdf a4_pdf lt_pdf epub html bare_html tex zip/) {
    ok ($compile->$m, "$m is true");
}

