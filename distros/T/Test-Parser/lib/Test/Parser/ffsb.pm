package Test::Parser::ffsb;

my $i=0;

=head1 NAME

Test::Parser::ffsb - Perl module to parse output from runs of the 
FFSB testsuite.

=head1 SYNOPSIS

 use Test::Parser::ffsb;

 my $parser = new Test::Parser::ffsb;
 $parser->parse($text);
 printf("Num Executed:  %8d\n", $parser->num_executed());
 printf("Num Passed:    %8d\n", $parser->num_passed());
 printf("Num Failed:    %8d\n", $parser->num_failed());
 printf("Num Skipped:   %8d\n", $parser->num_skipped());

Additional information is available from the subroutines listed below
and from the L<Test::Parser> baseclass.

=head1 DESCRIPTION

This module provides a way to extract information out of FFSB test run
output.

=head1 FUNCTIONS

Also see L<Test::Parser> for functions available from the base class.

=cut

use strict;
use warnings;
use Test::Parser;

@Test::Parser::ffsb::ISA = qw(Test::Parser);
use base 'Test::Parser';

use fields qw(
              _state
              _current_test
              );

use vars qw( %FIELDS $AUTOLOAD $VERSION );
our $VERSION = '1.7';

=head2 new()

Creates a new Test::Parser::ffsb instance.
Also calls the Test::Parser base class' new() routine.
Takes no arguments.

=cut

sub new {
    my $class = shift;
    my Test::Parser::ffsb $self = fields::new($class);
    $self->SUPER::new();

    $self->name('FFSB');
    $self->type('standards');

    $self->{_state}        = undef;
    $self->{_current_test} = undef;

    $self->{num_passed} = 0;
    $self->{num_failed} = 0;
    $self->{num_skipped} = 0;

    return $self;
}

=head3

Override of Test::Parser's default parse_line() routine to make it able
to parse FFSB output.

=cut
sub parse_line {
    my $self = shift;
    my $line = shift;

    $self->{_state} ||= 'intro';

    return 1;
}

1;
__END__

=head1 AUTHOR

Bryce Harrington <bryce@osdl.org>

=head1 COPYRIGHT

Copyright (C) 2005 Bryce Harrington.
All Rights Reserved.

This script is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Test::Parser>

=end

