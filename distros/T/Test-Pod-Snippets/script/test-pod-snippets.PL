BEGIN {
    unshift @INC, 'lib';    # bootstrap!
}

use Test::Pod::Snippets;

my $tps = Test::Pod::Snippets->new;

$tps->generate_snippets( qw#
    lib/Test/Pod/Snippets.pm    
#);
