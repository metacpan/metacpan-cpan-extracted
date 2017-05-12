use strict;
use warnings;

use Test::Stream::Plugin::Core qw( note done_testing );
use Test::Stream::Plugin::Compare qw( is );
use Test::Stream::Plugin::Explain::Terse qw( explain_terse );
use Data::Dump qw(pp);

{
  note "Some dumpers might not fold literal newlines, but we must";

  my $newline_text = "Hello\nWorld";
  my $pp           = pp($newline_text);
  my $got          = explain_terse($newline_text);

  note "Studying: $got";
  note "From: $pp";

  is( $pp,  q["Hello\nWorld"], "Dumper uses qq expression for \\n" ) or last;
  is( $got, q["Hello\nWorld"], "Newlines come through intact" )      or last;

}
done_testing;

