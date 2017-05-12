use strict;
use warnings;

use Test::Stream 1.302025 ();    # Core.cmp_ok
use Test::Stream::Plugin::Core qw( note cmp_ok done_testing );
use Test::Stream::Plugin::Explain::Terse qw( explain_terse );
use Test::Stream::Plugin::SRand;
use Data::Dump qw(pp);

use lib 't/lib';
use T::Grapheme qw( grapheme_str );

{
  note "Dumped structure would span multiple lines normally";

  my $newline_structure = {
    a => grapheme_str(30),
    b => grapheme_str(30),
  };

  my $pp  = pp($newline_structure);
  my $got = explain_terse($newline_structure);
  note "Studying: $got";
  note "From: $pp";

  cmp_ok( ( scalar split qq/\n/, $pp ), q[==], 4, "Dumper unpacks structure into 4 lines by default" ) or last;
  cmp_ok( ( scalar split qq/\n/, $got ), q[==], 1, "Terse uses 1 line" ) or last;

}
done_testing;

