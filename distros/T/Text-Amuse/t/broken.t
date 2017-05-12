use strict;
use warnings;
use Test::More;
use Text::Amuse::Document;
use Text::Amuse;
use File::Spec::Functions;
use Data::Dumper;

plan tests => 2;

my $fn = Text::Amuse::Document->new(file => catfile(t => testfiles => 'broken.muse'));

ok(scalar($fn->elements));

my $muse = Text::Amuse->new(file => catfile(t => testfiles => 'crashed-1.muse'));

eval { $muse->as_html };

ok(!$@, "No crash"); # or diag Dumper($muse);
