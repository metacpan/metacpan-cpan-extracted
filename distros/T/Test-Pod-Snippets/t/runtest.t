use strict;
use warnings;

use Test::More tests => 3;                      # last test to print

use Test::Pod::Snippets;

my $tps = Test::Pod::Snippets->new;

$tps->runtest( file => $0 );

=pod

    pass 'pod extracted and parsed';
