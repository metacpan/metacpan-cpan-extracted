use strict;
use utf8;

no warnings 'utf8';

use Test::More;
use Test::NoWarnings;

use Unicode::Stringprep;

our @map_data = (
    0xE0001, 0xE0001,
    0xE0020, 0xE007F,
    0xEFFFE, 0x10FFFF,
);

our @data = (
    0xE0002,
);

plan tests => ($#data+1) + 1;

my $prep = Unicode::Stringprep->new( 3.2, [ ], '', [ @map_data ], 0 );

foreach(@data) 
{
  my $in = $_;
  is( eval { $prep->(chr($in)) }, chr($in), sprintf 'U+%04X', $in);
}
