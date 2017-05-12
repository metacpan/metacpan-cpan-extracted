package Tie::Scalar::Timestamp;

use strict;
use warnings;

use base qw(Tie::Scalar);
use vars qw($VERSION $DEFAULT_STRFTIME);
use Carp;
use POSIX qw(strftime);

$VERSION = '0.01';

$DEFAULT_STRFTIME = '%Y-%m-%dT%H:%M:%S';

sub TIESCALAR {
    my $class = shift;
    my $options = shift || {};
    return bless $options, $class;
}

sub STORE {
    my $self = shift;
    # die unless asked not to (by having no_die in the tie statement)
    croak "Can't store to a Tie::Scalar::Timestamp variable" unless $self->{no_die};
    carp "Can't store to a Tie::Scalar::Timestamp variable" if $^W;
}

sub FETCH {
    my $self = shift;
    my $pattern = $self->{strftime} || $DEFAULT_STRFTIME;
    strftime $pattern, ($self->{utc} ? gmtime : localtime );
}

# module return
1;

=head1 NAME

Tie::Scalar::Timestamp - Create a scalar that always returns the current timestamp

=head1 SYNOPSIS

    # create a timestamp variable that uses localtime 
    # and yyyy-mm-ddThh:mm:ss (ISO8601) format
    tie my $timestamp, 'Tie::Scalar::Timestamp';
    
    print "$timestamp\n";    # e.g. 2005-02-25T11:02:34
    sleep 2;                 # wait 2 seconds...
    print "$timestamp\n";    # ...  2005-02-25T11:02:36
    
    # this will die; $timestamp is a readonly variable
    $timestamp = '2004';
    
    # create a timestamp variable that returns just the time in UTC
    tie my $utc_timestamp, 'Tie::Scalar::Timestamp', { strftime => '%H:%M:%S', utc => 1 };
    
    # set the default format
    $Tie::Scalar::Timestamp::DEFAULT_STRFTIME = '%H:%M:%S';

=head1 DESCRIPTION

This is a B<very> simple class that creates readonly scalars
that always return the current timestamp. By default, it uses
the format C<yyyy-mm-ddThh:mm:ss> (or, in strftime notation,
C<%Y-%m-%dT%H:%M:%S>) and local time. You can optionally pass
a hashref of options to the call to C<tie> to specify a pattern
and whether to use UTC time instead of local time.

A variables tied to this class is readonly, and attempting to
assign to it will raise an exception.

=head1 OPTIONS

The following options can be passed in a hashref to C<tie>.

=over

=item C<strftime>

The strftime pattern to fromat the timestamp as. The default
pattern is C<%Y-%m-%dT%H:%M:%S>. To change the default, set
C<$Tie::Scalar::Timestamp::DEFAULT_STRFTIME> to your prefered
pattern.

=item C<utc>

Use UTC time instead of local time.

=item C<no_die>

Do not throw an exception when attempting to assign to a
timestamp. This module will still emit a warning if you
have warnings enabled.

=back

=head1 SEE ALSO

L<perltie>, L<Tie::Scalar>, L<strftime(3)>

=head1 AUTHOR

Peter Eichman, C<< <peichman@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright E<copy>2005 by Peter Eichman.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
