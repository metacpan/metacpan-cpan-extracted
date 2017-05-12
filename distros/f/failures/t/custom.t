use 5.008001;
use strict;
use warnings;
use Test::More 0.96;

# use if available
eval { require Test::FailWarnings; Test::FailWarnings->import };

use lib 't/lib';
use MyFailures;

subtest 'custom hierarchy' => sub {
    no strict 'refs';
    for ("MyFailures::io::file") {
        isa_ok( $_, "MyFailures::io",    $_ ) or diag explain \@{"$_\::ISA"};
        isa_ok( $_, "failure::io::file", $_ ) or diag explain \@{"$_\::ISA"};
    }
    for ("MyFailures::io") {
        isa_ok( $_, "MyFailures",  $_ ) or diag explain \@{"$_\::ISA"};
        isa_ok( $_, "failure::io", $_ ) or diag explain \@{"$_\::ISA"};
    }
    for ("MyFailures") {
        isa_ok( $_, "failure", $_ ) or diag explain \@{"$_\::ISA"};
    }
};

subtest 'custom hierarchy in custom namespace' => sub {
    no strict 'refs';
    for ("Other::Failure::io::file") {
        isa_ok( $_, "Other::Failure::io", $_ ) or diag explain \@{"$_\::ISA"};
        isa_ok( $_, "failure::io::file",  $_ ) or diag explain \@{"$_\::ISA"};
    }
    for ("Other::Failure::io") {
        isa_ok( $_, "Other::Failure", $_ ) or diag explain \@{"$_\::ISA"};
        isa_ok( $_, "failure::io",    $_ ) or diag explain \@{"$_\::ISA"};
    }
    for ("Other::Failure") {
        isa_ok( $_, "failure", $_ ) or diag explain \@{"$_\::ISA"};
    }
};

subtest 'custom attributes and methods' => sub {
    my $err;
    my $now = time;
    eval { MyFailures::io::file->throw; };
    ok( $err = $@, 'caught thrown error' );
    ok( $err->when >= $now, "timestamp attribute populated" );
    is( $err->payload, "Hello Payload", "custom throw set payload" );
    is( $err->did_build, 1, "BUILD set attribute" );
    is(
        $err->message(''),
        "Caught MyFailures::io::file: (@{[$err->when]})",
        "custom message added attribute to string"
    );
};

done_testing;
#
# This file is part of failures
#
# This software is Copyright (c) 2013 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
# vim: ts=4 sts=4 sw=4 et:
