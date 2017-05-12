# -*- cperl -*-
use Test::More tests => 13;
use File::Spec;

BEGIN {
  use_ok( 'Tie::Ispell' );
  use_ok( 'Tie::Ispell::ConfigData' );
}

#diag( "Testing Tie::Ispell $Tie::Ispell::VERSION" );


my $dn = File::Spec->devnull();
my $spell = Tie::Ispell::ConfigData->config("ispell");

SKIP: {
    skip "Nao temos english...", 11 if system "$spell -d english -l < $dn";

    my %dic;
    tie %dic, 'Tie::Ispell', "english";

    is(  $dic{dog}, "dog");
    like( $dic{dogs}, qr/^dogs?$/);
    is(  $dic{dfsjfhsjd}, undef);
    is(  $dic{doj}, undef);

    #my $nearmisses = $dic{doj};

    #ok(grep { $_ eq "dog" } @$nearmisses );
    #ok(grep { $_ eq "dot" } @$nearmisses );

    ok(  exists($dic{dog}));
    ok( exists($dic{dogs}));
    ok(!exists($dic{dok}));
    ok(! exists($dic{dfsjfhsjd}));

    $dic{dfsjfhsjd} = 1;
    is(  $dic{dfsjfhsjd}, "dfsjfhsjd");
    ok( exists($dic{dfsjfhsjd}));

    my %dic2 = ();
    my $d = tie %dic2, 'Tie::Ispell', 'stupidlang';
    ok(!$d);
}
