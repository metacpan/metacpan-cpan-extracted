#!/usr/bin/perl -w

use strict;
use Test::More;
use YAML::Syck qw(Dump Load);
use JSON::Syck;

# Test that croak paths in Dump/DumpJSON clean up C resources properly
# (no segfault, no corruption after recovery).
#
# The SAVEDESTRUCTOR_X mechanism ensures the SyckEmitter, tag buffer,
# and ref string are freed even when croak() longjmps past normal cleanup.

# 1. JSON circular structure croak (json_syck_mark_emitter max_depth)
{
    my $a = {};
    my $b = { inner => $a };
    $a->{cycle} = $b;

    my $ok = eval { JSON::Syck::Dump($a); 1 };
    ok( !$ok, "JSON::Syck::Dump croaks on circular structure" );
    like( $@, qr/circular/i, "error message mentions circular" );

    # Repeat to verify no corruption after croak
    for ( 1 .. 20 ) {
        eval { JSON::Syck::Dump($a) };
    }
    pass("repeated circular JSON dump does not crash");
}

# 2. JSON circular array
{
    my @arr;
    push @arr, \@arr;

    my $ok = eval { JSON::Syck::Dump(\@arr); 1 };
    ok( !$ok, "JSON::Syck::Dump croaks on circular array" );

    for ( 1 .. 20 ) {
        eval { JSON::Syck::Dump(\@arr) };
    }
    pass("repeated circular JSON array dump does not crash");
}

# 3. Normal Dump still works after croak recovery
{
    my $data = { key => "value", list => [1, 2, 3] };
    my $yaml = eval { Dump($data) };
    ok( defined $yaml, "YAML::Syck::Dump works after JSON croak recovery" );
    like( $yaml, qr/key:/, "output looks like YAML" );

    my $json = eval { JSON::Syck::Dump($data) };
    ok( defined $json, "JSON::Syck::Dump works after croak recovery" );
    like( $json, qr/"key"/, "output looks like JSON" );
}

# 4. YAML DumpCode with XS function croak (B::Deparse failure)
SKIP: {
    skip "B::Deparse may not be available", 3
        unless eval { require B::Deparse; 1 };

    local $YAML::Syck::DumpCode = 1;

    # POSIX::getpid is an XS function - B::Deparse can't deparse it
    my $xs_func;
    eval { require POSIX; $xs_func = \&POSIX::getpid; };
    skip "POSIX not available", 3 unless defined $xs_func;

    my $ok = eval { Dump($xs_func); 1 };
    ok( !$ok, "Dump croaks on XS function with DumpCode=1" );

    # Repeat to verify no C-level corruption
    for ( 1 .. 20 ) {
        eval { Dump($xs_func) };
    }
    pass("repeated XS function dump does not crash");

    # Verify recovery
    my $data = { a => 1 };
    my $yaml = eval { Dump($data) };
    ok( defined $yaml, "Dump works after XS function croak" );
}

# 5. Empty string Load (save scope fix)
{
    my $result = Load("");
    ok( !defined $result, "Load('') returns undef" );

    # Repeat to verify no scope leak
    Load("") for ( 1 .. 100 );
    pass("repeated empty Load does not crash");
}

done_testing;
