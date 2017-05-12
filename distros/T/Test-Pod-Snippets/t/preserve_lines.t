use strict;
use warnings;

use Test::More tests => 3;                      # last test to print

use Test::Pod::Snippets;

my $tps = Test::Pod::Snippets->new;

my $re = qr/^#line/m;

# by default, put the #lines

like $tps->generate_test( file => $0 ), $re, 'default';

$tps->set_preserve_lines(0);
unlike $tps->generate_test( file => $0 ), $re, 'set_perserve_lines(0)';

$tps->set_preserve_lines(1);
like $tps->generate_test( file => $0 ), $re, 'set_perserve_lines(1)';


=pod

    $x = 3;



