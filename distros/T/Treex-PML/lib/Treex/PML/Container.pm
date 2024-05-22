
=head1 NAME

Treex::PML::Container - content and attributes

=head1 DESCRIPTION

This class implements the data type 'container'. A container consists
of a central value called content annotated by a set of name-value
pairs called attributes whose values are atomic. Treex::PML represents the
container class as a subclass of Treex::PML::Struct, where attributes are
represented as members and the content as a member with a reserved
name '#content'.

=head1 METHODS

=over 4

=cut

package Treex::PML::Container;
use Carp;
use strict;

use vars qw($VERSION);
BEGIN {
  $VERSION='2.28'; # version template
}
use base qw(Treex::PML::Struct);

=item Treex::PML::Container->new (value?, { name=>attr, ...}?,reuse?)

Create a new container (optionally initializing its value and
attributes). If reuse is true, the hash reference passed may be
reused (re-blessed) into the structure.

NOTE: Don't call this constructor directly, use Treex::PML::Factory->createContainer() instead!

=cut

sub new {
  my ($class,$value,$hash,$reuse) = @_;
  if (ref $hash) {
    $hash = {%$hash} unless ($reuse);
  } else {
    $hash = {};
  }
  bless $hash, $class;
  $hash->{'#content'} = $value unless !defined($value);
  return $hash;
}

=item $container->attributes ()

Return (assorted) list of names of all attributes.

=cut

sub attributes {
  return grep { $_ ne '#container' } keys %{$_[0]};
}

=item $container->value

Return the content value of the container.

=cut

sub value {
  return $_[0]->{'#content'};
}

=item $container->content

This is an alias for value().

=item $container->set_value($v), $container->set_content($v)

Set the central value of the container.

=cut

sub set_value {
    my ($self, $value) = @_;
    return $self->{'#content'} = $value
}

BEGIN{
*content = \&value;
*set_content = \&set_value;
*get_attribute = \&Treex::PML::Struct::get_member;
*set_attribute = \&Treex::PML::Struct::set_member;
}

=item $container->get_attribute($name)

Get value of a given attribute. This is just an alias for
the inherited C<Treex::PML::Struct::get_member()>.

=item $container->set_attribute($name, $value)

Set value of a given attribute. This is just an alias for
the inherited C<Treex::PML::Struct::set_member()>.

=back

=cut

=head1 SEE ALSO

L<Treex::PML>, L<Treex::PML::Factory>, L<Treex::PML::Schema>, L<Treex::PML::Struct>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2010 by Petr Pajas, 2010-2024 Jan Stepanek

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut


1;
