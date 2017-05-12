#!perl -T

use Test::More;
use Text::WordGrams;

eval "use Text::Lorem";
plan skip_all => "Text::Lorem is required to test big file support" if $@;

plan tests => 4;

open OUT, ">03-input" or die "Can't create file '03-input'";
my $Lorem = Text::Lorem->new();
for (0..5000) {
  print OUT $Lorem->sentences(5);
  print OUT " Foo bar zbr ugh.\n\n";
}
close OUT;

ok (-f "03-input");

my $data = word_grams_from_files( {size => 3}, "03-input" );
is (ref($data), "HASH");

is ($data->{"FOO BAR UGH"}, undef);
is ($data->{"zbr ugh ."}, 5001);

unlink "03-input";
