package Zenoss::MetaHelper;
use strict;

use Moose::Role;

#**************************************************************************
# Private methods
#**************************************************************************
#======================================================================
# _INSTALL_META_METHODS
#======================================================================
sub _INSTALL_META_METHODS {
    my @meta_method;
    my $caller = caller();
    (my $router_name = lc($caller)) =~ s/^.*::(\w+)$/$1/g;
    foreach my $method ($caller->meta->get_method_list) {
        if ($method !~ m/^${router_name}_|^meta|^_/) {
            push(@meta_method, "${router_name}_${method}");
            $caller->meta->add_method(
                "${router_name}_${method}",
                sub{
                    my ($self, $args) = @_;
                    $self->$method($args, uc($router_name));
                }
            );
        }
    }
} # END _INSTALL_META_METHODS

#**************************************************************************
# Package end
#**************************************************************************
no Moose;

1;

__END__

=head1 NAME

Zenoss::MetaHelper - Internal module that helps create Meta Methods

=head1 DESCRIPTION

B<This is not for public consumption.>

This is a helper to install Meta Methods.  For example, Zenoss::Router::Tree has methods
in it that are installed to various routers.  IE Zenoss::Router::Network implements methods
from Zenoss::Router::Tree, but the methods are renamed to be in line with the calling router.

Breaking that down:

Zenoss::Router::Tree has a method called addNode, but it will appear as network_addNode in
Zenoss::Router::Network.

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