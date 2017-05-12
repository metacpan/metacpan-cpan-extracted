package Test::Parser::lhcs_regression;

=head1 NAME

Test::Parser::lhcs_regression - Perl module to parse output from runs of the 
Linux Hotplug CPU Support (lhcs_regression) testsuite.

=head1 SYNOPSIS

 use Test::Parser::lhcs_regression;

 my $parser = new Test::Parser::LTP;
 $parser->parse($text);
 printf("Num Executed:  %8d\n", $parser->num_executed());
 printf("Num Passed:    %8d\n", $parser->num_passed());
 printf("Num Failed:    %8d\n", $parser->num_failed());
 printf("Num Skipped:   %8d\n", $parser->num_skipped());

Additional information is available from the subroutines listed below
and from the L<Test::Parser> baseclass.

=head1 DESCRIPTION

This module provides a way to extract information out of lhcs_regression test run
output.

=head1 FUNCTIONS

Also see L<Test::Parser> for functions available from the base class.

=cut

use strict;
use warnings;
use Test::Parser;

@Test::Parser::lhcs_regression::ISA = qw(Test::Parser);
use base 'Test::Parser';

use fields qw(
              _state
              );

use vars qw( %FIELDS $AUTOLOAD $VERSION );
our $VERSION = '1.7';

=head2 new()

Creates a new Test::Parser::lhcs_regression instance.
Also calls the Test::Parser base class' new() routine.
Takes no arguments.

=cut

sub new {
    my $class = shift;
    my Test::Parser::lhcs_regression $self = fields::new($class);
    $self->SUPER::new();

    $self->name('lhcs_regression');
    $self->type('standards');

    $self->{num_passed} = 0;
    $self->{num_failed} = 0;
    $self->{num_skipped} = 0;

    return $self;
}

=head3

Override of Test::Parser's default parse_line() routine to make it able
to parse LTP output.

The lhcs_regression format is simple, with each test case issuing a status line of
the form "foobar.42 PASS: Blah blah".  A regular expression in this
subroutine matches lines that look like that, increments the
passed/failed/skipped count accordingly, puts the info in a hash and
adds it to the testcases array.

=cut
sub parse_line {
    my $self = shift;
    my $line = shift;

    if ($line =~ /^([\w\.]+)\s+([A-Z]+):(.*)$/) {
        my $test;
        $test->{name} = $1;
        $test->{result} = $2;

        if ($test->{result} eq 'PASS') {
            $self->{num_passed}++;
        } elsif ($test->{result} eq 'FAIL') {
            $self->{num_failed}++;
        } else {
            $self->{num_skipped}++;
        }

        push @{$self->{testcases}}, $test;
    }

    return 1;
}

1;
__END__

=head1 AUTHOR

Bryce Harrington <bryce@osdl.org>

=head1 COPYRIGHT

Copyright (C) 2006 Bryce Harrington.
All Rights Reserved.

This script is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Test::Parser>

=end

