# -*- cperl -*-
use Test::More tests => 11;

use File::Spec;

BEGIN {
  use_ok( 'Tie::Ispell' );
  use_ok( 'Tie::Ispell::ConfigData' );
}

#diag( "Testing Tie::Ispell $Tie::Ispell::VERSION" );

my $dn = File::Spec->devnull();
my $spell = Tie::Ispell::ConfigData->config("ispell");

SKIP: {
    skip "Nao temos english...", 9 if system "$spell -d english -l < $dn";

    my %dic;
    tie %dic, 'Tie::Ispell', "english", 1;

    is(  $dic{dog}, "dog");
    like( $dic{dogs}, qr/^dogs?$/);
    is(  $dic{dfsjfhsjd}, undef);

    my $nearmisses = $dic{doj};

    ok(grep { $_ eq "dog" } @$nearmisses );
    ok(grep { $_ eq "dot" } @$nearmisses );

    ok(  exists($dic{dog}));
    ok(  exists($dic{dogs}));
    ok(! exists($dic{dok}));
    ok(! exists($dic{dfsjfhsjd}));
}
