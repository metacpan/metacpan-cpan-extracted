package WWW::Phanfare::Class::Account;
use Moose;
use MooseX::Method::Signatures;
use WWW::Phanfare::Class::Site;

method uid { $self->attribute('uid') }
has parent => ( is=>'ro', required=>1, lazy_build=>1 );
sub _build_parent { shift }
sub _childclass { 'WWW::Phanfare::Class::Site' }

# Name and ID of primary site
#
method _idnames {
  return [{
    id => $self->attribute('primary_site_id'),
    name => $self->attribute('primary_site_name'),
  }];
}

with 'WWW::Phanfare::Class::Role::Branch';
with 'WWW::Phanfare::Class::Role::Attributes';

1;

=head1 NAME

WWW::Phanfare::Class::Account - Account Node

=head1 DESCRIPTION

Child class of Class. Parent class for Site class.

=head1 SEE ALSO

L<WWW::Phanfare::Class>

=head1 AUTHOR

Soren Dossing, C<< <netcom at sauber.net> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Soren Dossing.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
