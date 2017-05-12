use strict;
use warnings;

use Test::Stream 1.302025 ();    # Core.cmp_ok
use Test::Stream::Plugin::Core qw( ok note cmp_ok done_testing );
use Test::Stream::Plugin::Compare qw( is );
use Test::Stream::Plugin::Explain::Terse qw( explain_terse );
use Test::Stream::Plugin::SRand;
use Data::Dump qw(pp);

use lib 't/lib';
use T::Grapheme qw/grapheme_str/;
{
  note "dumped string would be 80 or less normally";

  my $sub_long = grapheme_str( 80 - 2 );     # minus 2 because pp adds quotes.
  my $pp       = pp($sub_long);
  my $got      = explain_terse($sub_long);

  note "Studying: $got";
  note "From: $pp (=" . ( length $pp ) . ")";

  ok( defined $got, 'is defined' ) or last;
  cmp_ok( length $got, '<=', 80, "Length <= 80" ) or last;
  is( $got, qq["$sub_long"], 'dumps under MAX_LENGTH pass through OK' ) or last;

}
done_testing;

