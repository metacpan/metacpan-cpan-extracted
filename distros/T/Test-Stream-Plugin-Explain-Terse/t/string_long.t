use strict;
use warnings;

use Test::Stream 1.302025 ();    # Core.cmp_ok
use Test::Stream::Plugin::Core qw( note cmp_ok done_testing ok );
use Test::Stream::Plugin::Compare qw( is );
use Test::Stream::Plugin::Explain::Terse qw( explain_terse );
use Test::Stream::Plugin::SRand;
use Data::Dump qw(pp);

use lib 't/lib';
use T::Grapheme qw/grapheme_str/;

{
  note "dumped string would be >80 normally";

  my $super_long = grapheme_str( 81 - 2 );                       # minus 2 for quotes
  my $super_long_wrap = substr( $super_long, 0, 80 - 2 - 3 );    # minus 3 for elipsis

  my $pp  = pp($super_long);
  my $got = explain_terse($super_long);

  note "Studying: $got";
  note "From: $pp (=" . ( length $pp ) . ")";

  ok( defined $got, 'is defined' ) or last;
  cmp_ok( length $got, '<=', 80, "Length <= 80" ) or last;
  cmp_ok( $got, 'ne', qq["$super_long"], 'dumps over MAX_LENGTH do not go unmolested' ) or last;
  is( $got, qq["$super_long_wrap..."], 'dumps over MAX_LENGTH warp as expected' ) or last;
}
done_testing;

