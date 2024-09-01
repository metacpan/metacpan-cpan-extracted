use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

use Test::Expander;

plan( 2 );

const my $VALUE => 'value';
my $colorizing;

$colorizing = 'unknown';
is( $METHOD_REF->( $VALUE, $colorizing ),   $VALUE,           'unknown colorizing' );

$colorizing = 'exported';
like( $METHOD_REF->( $VALUE, $colorizing ), qr/^.+$VALUE.+$/, 'known colorizing' );
