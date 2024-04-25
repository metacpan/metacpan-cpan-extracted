package Treex::PML::Schema::Type;

use strict;
use warnings;

use vars qw($VERSION);
BEGIN {
  $VERSION='2.27'; # version template
}
no warnings 'uninitialized';
use Carp;

use Treex::PML::Schema::Constants;
use base qw( Treex::PML::Schema::Decl );


=head1 NAME

Treex::PML::Schema::Type - implements named type declaration in a PML schema

=head1 INHERITANCE

This class inherits from L<Treex::PML::Schema::Decl>.

=head1 METHODS

See the super-class for the complete list.

=over 3

=item $decl->get_name ()

Returns type name.

=item $decl->get_decl_type ()

Returns the constant PML_TYPE_DECL.

=item $decl->get_decl_type_str ()

Returns the string 'type'.

=item $decl->get_content_decl ()

Returns the associated data-type declaration.

=back

=cut

sub is_atomic { undef }
sub get_decl_type { return PML_TYPE_DECL; }
sub get_decl_type_str { return 'type'; }
sub get_name { return $_[0]->{-name}; }
sub validate_object {
  my $self = shift;
  $self->get_content_decl->validate_object(@_);
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!


=head1 SEE ALSO

L<Treex::PML::Schema::Decl>, L<Treex::PML::Schema>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2010 by Petr Pajas, 2010-2024 Jan Stepanek

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut

