package Zenoss::Error;
use strict;
use Carp;

use Moose::Role;

#**************************************************************************
# Globals
#**************************************************************************
$Carp::MaxArgNums = -1;
$Carp::Internal{ (__PACKAGE__) }++;

#**************************************************************************
# Public methods
#**************************************************************************
#======================================================================
# _croak
#======================================================================
sub _croak {
    my $self = shift;
    croak(@_);
} # END _croak

#======================================================================
# _confess
#======================================================================
sub _confess {
    my $self = shift;
    confess(@_);
} # END _confess

#**************************************************************************
# Package end
#**************************************************************************
no Moose;

1;

__END__

=head1 NAME

Zenoss::Error - Internal module that helps with providing errors

=head1 DESCRIPTION

B<This is not for public consumption.>

This is a helper to Zenoss::* for Carp calls.  Mainly used so when a croak/confess occurs, the appropriate calling
class appears in the error message.

=head1 SEE ALSO

=over

=item *

L<Zenoss>

=back

=head1 AUTHOR

Patrick Baker E<lt>patricksbaker@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Patrick Baker E<lt>patricksbaker@gmail.comE<gt>

This module is free software: you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

You can obtain the Artistic License 2.0 by either viewing the
LICENSE file provided with this distribution or by navigating
to L<http://opensource.org/licenses/artistic-license-2.0.php>.

=cut