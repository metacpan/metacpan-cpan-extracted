#!perl

use Test::More tests => 6;

SIMPLE: { # Test using the simple example
    my $started = `$^X -Mblib bin/hwd --started < t/simple.hwd`;
    like( $started, qr#Ape is working on.+ 104 - Add .+\(2/2\)#s, "Found Ape's work" );
    like( $started, qr#Chimp is working on.+ 107 - Refactor \(1/1\)#s, "Found Chimp's work" );

    my @lines = split "\n", $started;
    is(scalar @lines, 9, "Correct number of lines");
}

ONE_USER: { # Test for only one user
    my $started = `$^X -Mblib bin/hwd --started Ape < t/simple.hwd`;
    like( $started, qr#Ape is working on.+ 104 - Add .+\(2/2\)#s, "Found Ape's work" );
    unlike( $started, qr#Chimp is working on.+ 107 - Refactor \(1/1\)#s, "No work for Chimp" );

    my @lines = split "\n", $started;
    is( scalar @lines, 3, "Correct number of lines");
}
