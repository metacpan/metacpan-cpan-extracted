#! perl

use strict;
use warnings;

use Test::Lib;
use Test::More;
use Test::Trap;

use pkg -require => 'A';

my @rs = trap { A->tattle };
$trap->return_like( 0, qr/A/, 'explicit -require' );

done_testing;
