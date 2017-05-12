package Test::Parser::newpynfs;

my $i=0;

=head1 NAME

Test::Parser::newpynfs - Perl module to parse output from runs of the 
newpynfs testsuite.

=head1 SYNOPSIS

 use Test::Parser::newpynfs;

 my $parser = new Test::Parser::newpynfs;
 $parser->parse($text);
 printf("Num Executed:  %8d\n", $parser->num_executed());
 printf("Num Passed:    %8d\n", $parser->num_passed());
 printf("Num Failed:    %8d\n", $parser->num_failed());
 printf("Num Skipped:   %8d\n", $parser->num_skipped());

Additional information is available from the subroutines listed below
and from the L<Test::Parser> baseclass.

=head1 DESCRIPTION

This module provides a way to extract information out of newpynfs test run
output.

=head1 FUNCTIONS

Also see L<Test::Parser> for functions available from the base class.

=cut

use strict;
use warnings;
use Test::Parser;

@Test::Parser::newpynfs::ISA = qw(Test::Parser);
use base 'Test::Parser';

use fields qw(
              _current_test
              );

use vars qw( %FIELDS $AUTOLOAD $VERSION );
our $VERSION = '1.7';

=head2 new()

Creates a new Test::Parser::newpynfs instance.
Also calls the Test::Parser base class' new() routine.
Takes no arguments.

=cut

sub new {
    my $class = shift;
    my Test::Parser::newpynfs $self = fields::new($class);
    $self->SUPER::new();

    $self->name('newpynfs');
    $self->type('standards');

    $self->{_current_test} = undef;

    $self->{num_passed} = 0;
    $self->{num_failed} = 0;
    $self->{num_skipped} = 0;

    return $self;
}

=head3

Override of Test::Parser's default parse_line() routine to make it able
to parse newpynfs output.

=cut
sub parse_line {
    my $self = shift;
    my $line = shift;

    # Change state, if appropriate
    if (/^(\w+)\s+([\w\.]+)\s+: ([A-Z]+)$/) {
        my ($test, $desc, $result) = ($1, $2, $3);
        # This is a new test 
        print "$test - $desc - $result\n";

        # Add the previous one to the testcases list
        push @{$self->{testcases}}, $self->{_current_test};

        $self->{_current_test}->{name} = {
            name      => $test,
            desc      => $desc,
            result    => $result,
        };
        if ($result eq "PASS") {
            $self->{num_passed}++;
        } elsif ($result eq "OMIT") {
            $self->{num_skipped}++;
        } elsif ($result eq "FAILURE") {
            $self->{num_failed}++;
        }

    } elsif (/^\*\*\*/) {
        # This marks the end of the test
        $self->{_current_test} = undef;

    } elsif (defined $self->{_current_test}) {
        # The line is commentary about the test result

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

