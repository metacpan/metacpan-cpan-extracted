package WWW::Phanfare::Class::Role::Leaf;
use MooseX::Method::Signatures;
use Moose::Role;

# A leaf node must have a value
#
requires 'value';

with 'WWW::Phanfare::Class::Role::Node';

=head1 NAME

WWW::Phanfare::Class::Role::Leaf - End node in object tree representing value

=head1 DESCRIPTION

Set or get a value.

=head1 SEE ALSO

L<WWW::Phanfare::Class>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Soren Dossing.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
