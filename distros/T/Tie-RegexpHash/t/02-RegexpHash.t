#!/usr/bin/perl

use Test::More tests => 13;
use Data::Dumper;

use_ok("Tie::RegexpHash", 0.14); 
# Rudimentary test suite of the examples given in the
# synopsis. Someday it will be oncorporated with POD::Tests.  Someday
# I'll write a real test suite. Someday....

SKIP: {
    eval { require Storable };

    skip "Storable not installed", 13 if $@;

    my (%hash);

    tie %hash, 'Tie::RegexpHash';
    ok(1);

    $hash{ qr/^5(\s+|-)?gal(\.|lons?)?/i } = '5-GAL';
    ok(1);

    my $serialized = Storable::freeze(\%hash);
    ok(1, 'freeze');

    %hash = %{ Storable::thaw($serialized) };
    ok(1, 'thaw');

    ok($hash{'5 gal'} eq "5-GAL");
    ok($hash{'5GAL'}  eq "5-GAL");
    ok($hash{'5  gallon'} eq "5-GAL");

    # In case clone semantics change in a future revision... 
    $href = Storable::dclone( \%hash );
    ok(1, 'dclone');

    ok($href->{'5 gal'} eq "5-GAL");
    ok($href->{'5GAL'} eq "5-GAL");
    ok($href->{'5 gallon'} eq "5-GAL");

    $hash{ qr/^pattern$/i } = 'val1';
    $hash{ qr/(?i:^pattern$)/ } = 'val2';
    ok($hash{pAttErn} eq 'val2');
}
