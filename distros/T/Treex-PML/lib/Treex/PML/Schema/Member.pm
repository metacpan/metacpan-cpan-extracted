package Treex::PML::Schema::Member;

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

Treex::PML::Schema::Member - implements declaration of a member of a structure.

=head1 INHERITANCE

This class inherits from L<Treex::PML::Schema::Decl>.

=head1 METHODS

See the super-class for the complete list.

=over 3

=item $decl->get_decl_type ()

Returns the constant PML_MEMBER_DECL.

=item $decl->get_decl_type_str ()

Returns the string 'member'.

=item $decl->get_name ()

Return name of the member.

=item $decl->is_required ()

Return 1 if the member is declared as required, 0 otherwise.

=item $decl->is_attribute ()

Return 1 if the member is declared as attribute, 0 otherwise.

=item $decl->get_parent_struct ()

Return the structure declaration the member belongs to.

=item $decl->get_knit_name ()

Return the member's name with a possible suffix '.rf' chopped-off, if
either the member itself has a role '#KNIT' or its content is a list
and has a role '#KNIT'. Otherwise return just the member's name.

=back

=cut

sub is_atomic { undef }
sub get_decl_type { return PML_MEMBER_DECL; }
sub get_decl_type_str { return 'member'; }
sub get_name { return $_[0]->{-name}; }
sub is_required { return $_[0]->{required}; }
sub is_attribute { return $_[0]->{as_attribute}; }
*get_parent_struct = \&Treex::PML::Schema::Decl::get_parent_decl;

sub validate_object {
  shift->get_content_decl->validate_object(@_);
}

sub get_knit_name {
  my $self = shift;
  my $name = $self->{-name};
  my $knit_name = $name;
  if ($knit_name=~s/\.rf$//) {
    my $cont;
    if ( $self->{role} eq '#KNIT' or 
	   (($cont = $self->get_content_decl) and
	      ($cont->get_decl_type == PML_LIST_DECL
		 or
	       $cont->get_decl_type == PML_ALT_DECL)
		 and
		$cont->get_role eq '#KNIT')) {
      return $knit_name
    }
  }
  return $name;
}


1;
__END__

=head1 SEE ALSO

L<Treex::PML::Schema::Decl>, L<Treex::PML::Schema>, L<Treex::PML::Schema::Struct>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2010 by Petr Pajas, 2010-2024 Jan Stepanek

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut

