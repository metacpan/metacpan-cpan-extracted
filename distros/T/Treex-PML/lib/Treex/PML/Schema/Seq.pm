package Treex::PML::Schema::Seq;

use strict;
use warnings;

use vars qw($VERSION);
BEGIN {
  $VERSION='2.26'; # version template
}
no warnings 'uninitialized';
use Carp;

use Treex::PML::Schema::Constants;
use base qw( Treex::PML::Schema::Decl );
use UNIVERSAL::DOES;

=head1 NAME

Treex::PML::Schema::Seq - implements declaration of a sequence.

=head1 INHERITANCE

This class inherits from L<Treex::PML::Schema::Decl>.

=head1 METHODS

See the super-class for the complete list.

=over 3

=item $decl->get_decl_type ()

Returns the constant PML_SEQUENCE_DECL.

=item $decl->get_decl_type_str ()

Returns the string 'sequence'.

=item $decl->is_mixed ()

Return 1 if the sequence allows text content, otherwise
return 0.

=item $decl->is_atomic ()

Returns 0.

=item $decl->get_content_decl ()

Returns undef.

=item $decl->get_content_pattern ()

Return content pattern associated with the declaration (if
any). Content pattern specifies possible ordering and occurences of
elements in DTD-like content-model grammar.

=cut

sub is_atomic { 0 }
sub get_decl_type { return PML_SEQUENCE_DECL; }
sub get_decl_type_str { return 'sequence'; }
sub get_content_decl { return(undef); }
sub is_mixed { return $_[0]->{text} ? 1 : 0 }
sub get_content_pattern {
  return $_[0]->{content_pattern};
}

sub init {
  my ($self,$opts)=@_;
  $self->{-parent}{-decl} = 'sequence';
}

=item $decl->get_elements ()

Return a list of element declarations (C<Treex::PML::Schema::Element>).

=cut

sub get_elements { 
  my $members = $_[0]->{element};
  return $members ? map { $_->[0] } sort { $a->[1]<=> $b->[1] } map { [ $_, $_->{'-#'} ] } values %$members : (); 
}

=item $decl->get_element_names ()

Return a list of names of elements declared for the sequence.

=cut

sub get_element_names { 
  my $members = $_[0]->{element};
  return $members ? map { $_->[0] } sort { $a->[1]<=> $b->[1] } map { [ $_, $members->{$_}->{'-#'} ] } keys %$members : (); 
}

=item $decl->get_element_by_name (name)

Return the declaration of the element with a given name.

=cut

sub get_element_by_name {
  my ($self, $name) = @_;
  my $members = $_[0]->{element};
  return $members ? $members->{$name} : undef;
}

=item $decl->find_elements_by_content_decl

Lookup and return those element declarations whose content declaration
is decl.

=cut

sub find_elements_by_content_decl {
  my ($self, $decl) = @_;
  return grep { $decl == $_->get_content_decl } $self->get_elements;
}

=item $decl->find_elements_by_type_name

Lookup and return those element declarations whose content is
specified via a reference to the named type with a given name.

=cut


sub find_elements_by_type_name {
  my ($self, $type_name) = @_;
  # using directly $member->{type}
  return grep { $type_name eq $_->{type} } $self->get_elements;  
}

=item $decl->find_elements_by_role

Lookup and return declarations of all elements with a given role.

=cut

sub find_elements_by_role {
  my ($self, $role) = @_;
  # using directly $member->{role}
  return grep { $role eq $_->{role} } $self->get_elements;  
}

sub validate_object {
  my ($self, $object, $opts) = @_;

  my ($path,$tag,$flags);
  my $log = [];
  if (ref($opts)) {
    $flags = $opts->{flags};
    $path = $opts->{path};
    $tag = $opts->{tag};
    $path.="/".$tag if $tag ne q{};
  }

  if (UNIVERSAL::DOES::does($object,'Treex::PML::Seq')) {
    my $i = 0;
    foreach my $element ($object->elements) {
      $i++;
      if (!UNIVERSAL::isa($element,'ARRAY')) {
	push @$log, "$path: invalid sequence content: ",ref($element);
      } elsif ($element->[0] eq '#TEXT') {
	if ($self->is_mixed) {
	  if (ref($element->[1])) {
	    push @$log, "$path: expected CDATA, got: ",ref($element->[1]);
	  }
	} else {
	  push @$log, "$path: text node not allowed here\n";
	}
      } else {
	my $ename = $element->[0];
	my $edecl = $self->get_element_by_name($ename);
	# KNIT on elements not supported yet
	if ($edecl) {
	  $edecl->validate_object($element->[1],{
	    flags => $flags,
	    path => $path,
	    tag => "[$i]",
	    log => $log,
	  });
	} else {
	  push @$log, "$path: undefined element '$ename'";
	}
      }
      my $content_pattern = $self->get_content_pattern;
      if ($content_pattern and !$object->validate($content_pattern)) {
	push @$log, "$path: sequence content (".join(",",$object->names).") does not follow the pattern ".$content_pattern;
      }
    }
  } else {
    push @$log, "$path: unexpected content of a sequence: $object";
  }
  if ($opts and ref($opts->{log})) {
    push @{$opts->{log}}, @$log;
  }
  return @$log ? 0 : 1;
}

=back

=cut 


1;
__END__

=head1 SEE ALSO

L<Treex::PML::Schema::Decl>, L<Treex::PML::Schema>,
L<Treex::PML::Schema::Element>, L<Treex::PML::Seq>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2010 by Petr Pajas, 2010-2024 Jan Stepanek

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut

