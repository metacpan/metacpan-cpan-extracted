#!/sw/bin/perl -w

use strict;
use YAML::Syck;
use Test::More tests => 12;

SKIP: {
    eval { require Devel::Leak; require 5.8.9; 1; }
      or skip( "Devel::Leak not installed or perl too old", 12 );

    # check if arrays leak

    my $yaml = q{---
blah
};

    require Symbol;
    my $handle = Symbol::gensym();
    my $diff;

    # For some reason we have to do a full test run of this loop and the
    # Devel::Leak test before it's stable.  The first time diff ends up
    # being -2.  This is probably Devel::Leak wonkiness.
    my $before = Devel::Leak::NoteSV($handle);
    foreach ( 1 .. 100 ) {
        Load($yaml);
    }

    $diff = Devel::Leak::NoteSV($handle) - $before;

    $before = Devel::Leak::NoteSV($handle);
    foreach ( 1 .. 100 ) {
        Load($yaml);
    }

    $diff = Devel::Leak::NoteSV($handle) - $before;
    is( $diff, 0, "No leaks - array" );

    # Check if hashess leak
    $yaml = q{---
result: test
};

    $before = Devel::Leak::NoteSV($handle);
    foreach ( 1 .. 100 ) {
        Load($yaml);
    }

    $diff = Devel::Leak::NoteSV($handle) - $before;
    is( $diff, 0, "No leaks - hash" );

    # Check if subs leak
    $YAML::Syck::UseCode = 1;
    $yaml                = q#---
result: !perl/code: '{ 42 + $_[0] }'
#;

    # Initial load to offset one-time load cost of B::Deparse
    Load($yaml);

    $before = Devel::Leak::NoteSV($handle);
    foreach ( 1 .. 100 ) {
        Load($yaml);
    }

    # Load in list context again
    foreach ( 1 .. 100 ) {
        () = Load($yaml);
    }

    $diff = Devel::Leak::NoteSV($handle) - $before;
    is( $diff, 0, "No leaks - code" );

    $yaml = q{---
a: b
c:
 - d
 - e
!
};

    ok( !eval { Load($yaml) }, "Load failed (expected)" );

    $before = Devel::Leak::NoteSV($handle);
    eval { Load($yaml) } for ( 1 .. 10 );
    $diff = Devel::Leak::NoteSV($handle) - $before;
    is( $diff, 0, "No leaks - Load failure" );

    $yaml = q#---
result: !perl/code: '{ 42 + + 54ih a; $" }'
#;

    {
        local $SIG{__WARN__} = sub { };
        ok(
            !eval { Load($yaml) },
            "Load failed on code syntax error (expected)"
        );

        $before = Devel::Leak::NoteSV($handle);
        eval { Load($yaml) } for ( 1 .. 10 );
        $diff = Devel::Leak::NoteSV($handle) - $before;
        is( $diff, 0, "No leaks - Load failure (code)" );
    }

    my $todump = {
        a => [ { c => { nums => [ '1', '2', '3', '4', '5' ] }, b => 'foo' } ],
        d => 'e'
    };

    ok( eval { Dump($todump) }, "Dump succeeded" );

    $before = Devel::Leak::NoteSV($handle);
    foreach ( 1 .. 100 ) {
        Dump($todump);
    }
    $diff = Devel::Leak::NoteSV($handle) - $before;
    is( $diff, 0, "No leaks - Dump" );

    $todump = sub { 42 };

    ok( eval { Dump($todump) }, "Dump succeeded" );

    # For some reason we have to do a full test run of this loop and the
    # Devel::Leak test before it's stable.  The first time diff ends up
    # being -1.  This is probably Devel::Leak wonkiness.
    foreach ( 1 .. 100 ) {
        Dump($todump);
    }

    $before = Devel::Leak::NoteSV($handle);
    foreach ( 1 .. 100 ) {
        Dump($todump);
    }
    $diff = Devel::Leak::NoteSV($handle) - $before;

    is( $diff, 0, "No leaks - Dump code" );

    # Check if dumping a filehandle leaks (rt.cpan.org #41199)
    # Warm up to stabilize SV count
    foreach ( 1 .. 100 ) {
        open my $fh, "<", "/dev/null" or die;
        Dump($fh);
    }

    $before = Devel::Leak::NoteSV($handle);
    foreach ( 1 .. 100 ) {
        open my $fh, "<", "/dev/null" or die;
        Dump($fh);
    }
    $diff = Devel::Leak::NoteSV($handle) - $before;
    is( $diff, 0, "No leaks - Dump filehandle (rt#41199)" );
}
