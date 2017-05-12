use strict;
use utf8;

no warnings 'utf8';

use Test::More;
use Test::NoWarnings;

use Unicode::Stringprep;

our @data = (
    0x0000, 0x0001,
    0x0041, 0x004F,
    0x00DF, 0x123,
    0x20AC, 0xD800,
    0x10F000, 0x10FFFF,
);

plan tests => ($#data+1) + 1;

my $prep = Unicode::Stringprep->new( 3.2, [ ], '', [ @data ], 0 );

foreach(@data) 
{
  my $in = $_;
  is( eval { $prep->(chr($in)) }, undef, sprintf 'U+%04X', $in);
}
