package Treex::PML::Schema::Element;

use strict;
use warnings;

use vars qw($VERSION);
BEGIN {
  $VERSION='2.22'; # version template
}
no warnings 'uninitialized';
use Carp;

use Treex::PML::Schema::Constants;
use base qw( Treex::PML::Schema::Decl );

=head1 NAME

Treex::PML::Schema::Element - implements declaration of an element of a
sequence.

=head1 INHERITANCE

This class inherits from L<Treex::PML::Schema::Decl>.

=head1 METHODS

See the super-class for the complete list.

=over 3

=item $decl->get_decl_type ()

Returns the constant PML_ELEMENT_DECL.

=item $decl->get_decl_type_str ()

Returns the string 'element'.

=item $decl->get_name ()

Return name of the element.

=item $decl->get_parent_sequence ()

Return the sequence declaration the member belongs to.

=back

=cut

sub is_atomic { undef }
sub get_decl_type { return PML_ELEMENT_DECL; }
sub get_decl_type_str { return 'element'; }
sub get_name { return $_[0]->{-name}; }
*get_parent_sequence = \&Treex::PML::Schema::Decl::get_parent_decl;

sub validate_object {
  shift->get_content_decl->validate_object(@_);
}


1;
__END__

=head1 SEE ALSO

L<Treex::PML::Schema::Decl>, L<Treex::PML::Schema>, L<Treex::PML::Schema::Seq>,
L<Treex::PML::Seq>, L<Treex::PML::Seq::Element>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2010 by Petr Pajas

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut

