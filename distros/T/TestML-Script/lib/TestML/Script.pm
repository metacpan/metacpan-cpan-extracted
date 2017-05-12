##
# name:      TestML::Script
# abstract:  Support for running TestML as a script
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011

use 5.008003;
use TestML 0.22 ();

package TestML::Script;

our $VERSION = '0.01';

use TestML::Runtime;

use XXX;

sub run {
    my $class = shift;
    my $script = shift;

    local @ARGV = @_;
    my $runtime = TestML::Runtime->new(
        base => '',
        testml => $script,
    );
    $runtime->run();
    exit 0;
}

1;

=head1 SYNOPSIS

    #!/usr/bin/env testml

    %TestML 1.0

    Print("Hello, world");

=head1 DESCRIPTION

TestML is a computer programming language for writing Acmeist unit tests (unit
tests that run under any programming language and any test framework).

This module will let you run TestML as a standalone script.
