package Tie::Scalar::Epoch;

use strict;
use warnings;

use base qw(Tie::Scalar);
use vars qw($VERSION);
use Carp;

$VERSION = '0.01';

sub TIESCALAR {
    my $class   = shift;
    my $options = shift || {};
    return bless $options, $class;
}

sub STORE {
    my $self = shift;
    # die unless asked not to (by having no_die in the tie statement)
    croak "Can't store to a Tie::Scalar::Epoch variable" unless $self->{no_die};
    carp "Can't store to a Tie::Scalar::Epoch variable" if $^W;
}

sub FETCH {
    my $self = shift;
    return time;
}

# module return
1;

=head1 NAME

Tie::Scalar::Epoch - Create a scalar that always returns the number 
of non-leap seconds since whatever time the system considers to be the epoch.

=head1 SYNOPSIS

    # create a variable and tie 
    tie my $epoch, 'Tie::Scalar::Epoch';
    
    print "$epoch\n";        # eg. 1351113480
    sleep 2;                 # wait 2 seconds...
    print "$epoch\n";    # ... 1351113482
    
    # this will die; $epoch is a readonly variable
    $epoch = '2012';

    # don't die if no_die is true
    tie my $epoch, 'Tie::Scalar::Epoch', { no_die => 1 };
    $epoch = '2012';
  
    
=head1 DESCRIPTION

This is a B<very> simple class that creates readonly scalars
that always return the current epoch. 

A variables tied to this class is readonly, and attempting to
assign to it will raise an exception.

=head1 OPTIONS

The following options can be passed in a hashref to C<tie>.

=over

=item C<no_die>

Do not throw an exception when attempting to assign to a
tied scalar. This module will still emit a warning if you
have warnings enabled.

=back

=head1 SEE ALSO

L<perltie>, L<Tie::Scalar>, 

=head1 AUTHOR

Victor Houston, C<< <vichouston@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright E<copy>2012 by Victor Houston.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
