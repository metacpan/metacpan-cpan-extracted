package Treex::PML::Schema::Decl;

########################################################################
# PML Schema type declaration
########################################################################

use strict;
use warnings;

use vars qw($VERSION);
BEGIN {
  $VERSION='2.27'; # version template
}
no warnings 'uninitialized';
use Scalar::Util qw( weaken );
use Carp;
use Treex::PML::Schema::Constants;
use base qw(Treex::PML::Schema::XMLNode);

=head1 NAME

Treex::PML::Schema::Decl - implements PML schema type declaration

=head1 DESCRIPTION

This is an abstract class from which all specific type declaration
classes inherit.

=head1 INHERITANCE

This class inherits from L<Treex::PML::Schema::XMLNode>.

=head1 METHODS

=over 3

=cut

sub new { croak("Can't create ".__PACKAGE__) }

# compatibility with old Treex::PML::Type

sub type_decl { return $_[0] };

=item $decl->get_schema () 

=item $decl->schema ()

Return C<Treex::PML::Schema> the declaration belongs to.

=cut

sub schema    { return $_[0]->{-schema} }

=item $decl->get_schema ()

Same as C<< $decl->schema() >>.

=cut

sub get_schema { return $_[0]->schema }

=item $decl->get_decl_type ()

Return the type of declaration as an integer constant (see
L<Treex::PML::Schema/"CONSTANTS">).

=item $decl->get_decl_type_str ()

Return the type of declaration as string; one of: type, root,
structure, container, sequence, list, alt, cdata, choice, constant,
attribute, member, element.

=cut

sub get_decl_type     { return(undef); } # VIRTUAL
sub get_decl_type_str { return(undef); } # VIRTUAL

=item $decl->is_atomic ()

Return 1 if the declaration is of atomic type (cdata, choice,
constant), 0 if it is a structured type (structure, container,
sequence, list, alt), or undef, if it is an auxiliary declaration
(root, type, attribute, member, element).

=cut

sub is_atomic { croak "is_atomic(): UNKNOWN TYPE"; } # VIRTUAL

=item $decl->get_content_decl ()

For declarations with content (type, root, container, list, alt,
attribute, member, element), return the content declaration; return
undef for other declarations. This method transparently resolves
references to named types.

=cut

sub get_content_decl { 
  my $self = shift;
  my $no_resolve = shift;
  if ($self->{-decl}) {
    return $self->{ $self->{-decl} };
  } elsif (my $resolved = $self->{-resolved}) {
    return $resolved;
  } elsif (my $type_ref = $self->{type}) {
    my $schema = $self->{-schema};
    if ($schema) {
      my $type = $schema->{type}{ $type_ref };
      if ($no_resolve) {
        return $type;
      } elsif ($type) {
        weaken($self->{-resolved} = $type->get_content_decl);
        return $self->{-resolved};
      } else {
        return undef;
      }
    } else {
      croak "Declaration not associated with a schema";
    }
  }
  return(undef);
}

=item $decl->get_knit_content_decl ()

If the data type has a role '#KNIT', return a type declaration for the
knitted content (Note: PML 1.1.2 allows role '#KNIT' role on list,
element, and member declarations, but element knitting is not
currenlty implemented). Otherwise return the same as get_content_decl.

=cut


sub get_knit_content_decl {
  my $self = shift;
  return (defined($self->{role}) and $self->{role} eq '#KNIT') ?
    $self->get_type_ref_decl
      : $self->get_content_decl;
}

=item $decl->get_type_ref ()

If the declaration has content and the content is specified via a
reference to a named type, return the name of the referred type.
Otherwise return undef.

=cut

sub get_type_ref {
  return $_[0]->{type};
}

=item $decl->get_type_ref_decl ()

Retrun content declaration object (if any), but only if it is
specified via a reference to a named type. In all other cases, return
undef.

=cut

sub get_type_ref_decl { 
  my $self = shift;
  my $no_resolve = shift;
  if (my $resolved = $self->{-resolved}) {
    return $resolved;
  } elsif (my $type_ref = $self->{type}) {
    my $schema = $self->{-schema};
    if ($schema) {
      my $type = $schema->{type}{ $type_ref };
      return $no_resolve ? $type 
        : $type ? 
          ($self->{-resolved} = $type->get_content_decl)
          : undef ;
    }
  }
  return(undef);
}

=item $decl->get_base_type_name ()

If the declaration is a nested (even deeply) part of a named type
declaration, return the name of that named type.

=cut

sub get_base_type_name {
  my $path = $_[0]->{-path};
  if ($path=~m{^!([^/]+)}) {
    return $1;
  } else {
    return(undef);
  }
}

=item $decl->get_parent_decl ()

If this declaration is nested, return its parent declaration.

=cut

sub get_parent_decl { return $_[0]->{-parent} }

=item $decl->get_decl_path ()

Return a cannonical attribute path leading to the declaration
(starting either at a named type or the root type declaration).

=cut

sub get_decl_path { return $_[0]->{-path};  }

=item $decl->get_role

If the declaration is associated with a role, return it.

=cut

sub get_role      { return $_[0]->{role}||'' }


=item $decl->find (attribute-path,noresolve)

Locate a nested declaration specified by C<attribute-path> starting
from the current type. See C<$schema-E<gt>find_type_by_path> for details
about locating declarations.

=cut

sub find {
  my ($self, $path,$noresolve) = @_;
  # find node type
  my $type = $self->type_decl;
  return $self->schema->find_type_by_path($path,$noresolve,$type);
}

=item $decl->find_role (role, opts)

Search declarations with a given role nested within this declaration.
In scalar context, return the first declaration that matches, in array
context return all such declarations.

The last argument C<opts> can be used to pass some flags to the
algorithm. Currently only the flag C<no_children> is available. If
true, then the function never recurses into content declaration of
declarations with the role #CHILDNODES.

=cut

sub find_role {
  my ($self, $role, $opts) = @_;
  return $self->schema->find_role($role,$self->type_decl,$opts);
}

=item $decl->convert_from_hash (class, hash, schema, path)

Compatibility method building the schema object from a nested hash
structure created by XML::Simple which was used in older
implementations. This is useful for upgrading objects stored in old
binary dumps. Not to be used directly.

=cut

sub convert_from_hash {
  my ($class, $decl, $schema, $path) = @_;
  my $sub;
  my $decl_type;
  if ($sub = $decl->{structure}) {
    $decl_type = 'structure';
    bless $sub, 'Treex::PML::Schema::Struct';
    $sub->{'-attributes'}=[qw(role name type)];
    if (my $members = $sub->{member}) {
      my ($name, $mdecl);
      while (($name, $mdecl) = each %$members) {
        bless $mdecl, 'Treex::PML::Schema::Member';
        $mdecl->{'-xml_name'}='member';
        $mdecl->{'-attributes'}=[qw(name required as_attribute type role)];
        weaken($mdecl->{-parent}=$sub);
        weaken($mdecl->{-schema}=$schema);
        $class->convert_from_hash($mdecl,
                         $schema,
                         $path.'/'.$name
                        );
        if (!$mdecl->{-decl} and $mdecl->{role} eq '#KNIT') {
#          warn("Member $decl->{-parent}{-path}/$decl->{-name} with role=\"#KNIT\" must have a content type declaration: assuming <cdata format=\"PMLREF\">!\n");
          Treex::PML::Schema::__fix_knit_type($schema,$mdecl);
        }
      }
    }
  } elsif ($sub = $decl->{container}) {
    $decl_type = 'container';
    bless $sub, 'Treex::PML::Schema::Container';
    $sub->{'-attributes'}=[qw(role name type)];
    if (my $members = $sub->{attribute}) {
      my ($name, $mdecl);
      while (($name, $mdecl) = each %$members) {
        bless $mdecl, 'Treex::PML::Schema::Attribute';
        $mdecl->{'-xml_name'}='attribute';
        $mdecl->{'-attributes'}=[qw(name required type role)];
        weaken($mdecl->{-schema}=$schema);
        weaken($mdecl->{-parent}=$sub);
        $class->convert_from_hash($mdecl, 
                         $schema,
                         $path.'/'.$name
                        );
      }
    }
    $class->convert_from_hash($sub, $schema, $path.'/#content');
  } elsif ($sub = $decl->{sequence}) {
    $decl_type = 'sequence';
    bless $sub, 'Treex::PML::Schema::Seq';
    $sub->{'-attributes'}=[qw(role content_pattern type)];
    if (my $members = $sub->{element}) {
      my ($name, $mdecl);
      while (($name, $mdecl) = each %$members) {
        bless $mdecl, 'Treex::PML::Schema::Element';
        $mdecl->{'-xml_name'}='element';
        $mdecl->{'-attributes'}=[qw(name type role)];
        weaken($mdecl->{-schema}=$schema);
        weaken($mdecl->{-parent}=$sub);
        $class->convert_from_hash($mdecl, 
                         $schema,
                         $path.'/'.$name
                        );
      }
    }
  } elsif ($sub = $decl->{list}) {
    $decl_type = 'list';
    bless $sub, 'Treex::PML::Schema::List';
    $sub->{'-attributes'}=[qw(role ordered type)];
    $class->convert_from_hash($sub, $schema, $path.'/LM');
    if (!$sub->{-decl} and $sub->{role} eq '#KNIT') {
#      warn("List $sub->{-name} with role=\"#KNIT\" must have a content type declaration: assuming <cdata format=\"PMLREF\">!\n");
      Treex::PML::Schema::__fix_knit_type($schema,$sub,$path.'/LM');
    }
  } elsif ($sub = $decl->{alt}) {
    $decl_type = 'alt';
    bless $sub, 'Treex::PML::Schema::Alt';
    $sub->{'-attributes'}=[qw(role type)];
    $class->convert_from_hash($sub, $schema, $path.'/AM');
  } elsif ($sub = $decl->{choice}) {
    $decl_type = 'choice';
    # convert from an ARRAY to a hash
    if (ref($sub) eq 'ARRAY') {
      $sub = $decl->{choice} = bless { values => [
                                         map {
                                           ref($_) eq 'HASH' ? $_->{content} : $_
                                         } @$sub
                                       ],
                                     }, 'Treex::PML::Schema::Choice';
    } elsif (ref($sub)) {
      bless $sub, 'Treex::PML::Schema::Choice';
      if (ref($sub->{value}) eq 'ARRAY') {
        $sub->{values} = [
          map { $_->{content} } @{$sub->{value}}
        ];
        delete $sub->{value};
      }
    } else {
      croak __PACKAGE__.": Invalid <choice> element in type '$path'?\n";
    }
  } elsif ($sub = $decl->{cdata}) {
    $decl_type = 'cdata';
    bless $sub, 'Treex::PML::Schema::CDATA';
    $sub->{'-attributes'}=['format'];
  } elsif (exists $decl->{constant}) { # can be 0
    $sub = $decl->{constant};
    $decl_type = 'constant';
    unless (ref($sub)) {
      $sub = $decl->{constant} = bless { value => $sub }, 'Treex::PML::Schema::Constant';
    }
    ## this is just a scalar value
    # bless $sub, 'Treex::PML::Schema::Constant';
  }
  $sub->{'-xml_name'}=$decl_type;
  weaken( $decl->{-schema} = $schema );
  $decl->{-decl} = $decl_type;
  unless (exists($sub->{-schema}) and exists($sub->{-parent})) {
    weaken( $sub->{-schema} = $schema ) unless $sub->{-schema};
    weaken( $sub->{-parent} = $decl ) unless $sub->{-parent};
    $sub->{-path} = $path;
  }
  return $decl;
}


=item $decl->get_normal_fields ()

This method is provided for convenience.

For a structure type, return names of its members, for a container
return names of its attributes plus the name '#content' referring to
the container's content value. In both cases, eliminate fields of
values with role C<#CHILDNODES> and strip a possible C<.rf> suffix of
fields with role C<#KNIT>.

=cut

sub get_normal_fields {
  my ($self,$path)=@_;
  my $type = defined($path) ? $self->find($path) : $self;
  my $struct;
  my $members;
  return unless ref $type;
  my $decl_is = $type->get_decl_type;
  if ($decl_is == PML_TYPE_DECL ||
      $decl_is == PML_ROOT_DECL ||
      $decl_is == PML_ATTRIBUTE_DECL ||
      $decl_is == PML_MEMBER_DECL ||
      $decl_is == PML_ELEMENT_DECL ) {
    if ($type = $type->get_content_decl) {
      $decl_is = $type->get_decl_type; 
    } else {
      return ();
    }
  }
  my @members = ();
  if ($decl_is == PML_STRUCTURE_DECL) {
    @members = 
      map { $_->get_knit_name }
        grep { $_->get_role ne '#CHILDNODES' }
          $type->get_members;
  } elsif ($decl_is == PML_CONTAINER_DECL) {
    my $cdecl = $type->get_content_decl;
    @members = ($type->get_attribute_names, 
                ($cdecl && $type->get_role ne '#CHILDNODES') ? '#content' : ());
  }
}

=item $decl->get_childnodes_decls ()

If the $decl has the role #NODE, this method locates a sub-declaration
with role #CHILDNODES and returns a list of declarations of the child
nodes.

=cut

sub get_childnodes_decls {
  my ($self) = @_;
  if ($self->get_decl_type == PML_ELEMENT_DECL) {
    $self = $self->get_content_decl;
  }
  return unless $self->get_role eq '#NODE';
  my ($ch) = $self->find_members_by_role('#CHILDNODES');
  if ($ch) {
    my $ch_is = $ch->get_decl_type;
    if ($ch_is == PML_MEMBER_DECL) {
      $ch = $ch->get_content_decl;
      $ch_is = $ch->get_decl_type;
    }
    if ($ch_is == PML_SEQUENCE_DECL) {
      return $ch->get_elements;
    } elsif ($ch_is == PML_LIST_DECL) {
      return $ch->get_content_decl;
    }
  }
  return;
}


=item $decl->get_attribute_paths (\%opts)

Return attribute paths leading from this declaration to all (possibly
deeply) nested declarations of atomic type. This method is an alias for

  $decl->schema->get_paths_to_atoms([$decl],\%opts)

See L<Treex::PML::Schema> for details.

=cut

sub get_attribute_paths { # OLD NAME
  my ($self,$opts)=@_;
  return $self->get_paths_to_atoms($opts);
}

=item $decl->get_paths_to_atoms (\%opts)

Same as

  $decl->schema->get_paths_to_atoms([$decl],\%opts)

See L<Treex::PML::Schema> for details.

=cut

sub get_paths_to_atoms {
  my ($self,$opts)=@_;
  return $self->schema->get_paths_to_atoms([$self],$opts);
}

=item $decl->validate_object($object);

See C<validate_object()> method of L<Treex::PML::Schema>.

=cut

sub validate_object {
  croak "Not implemented for the class ".__PACKAGE__;
}

=item $decl->for_each_decl (sub{ ... })

This method traverses all nested sub-declarations and calls a given
subroutine passing the sub-declaration object as a parameter.

=cut

sub for_each_decl {
  my ($self,$sub)=@_;
  $sub->($self);
  # (a container or #KNIT member can have both type and children)
  # traverse descendant type declarations
  for my $d (qw(member attribute element)) {
    if (ref $self->{$d}) {
      foreach (values %{$self->{$d}}) {
        $_->for_each_decl($sub);
      }
      last if $d eq 'attribute'; # there may be content
      return; # otherwise
    }
  }
  for my $d (qw(list alt structure container sequence),
             qw(cdata choice constant)) {
    if (exists $self->{$d}) {
      $self->{$d}->for_each_decl($sub);
      return;
    }
  }
}

=item $decl->write ({option => value})

This method serializes a declaration to XML. See Treex::PML::Schema->write for
details and Treex::PML::Schema::XMLNode->write for implementation.

=cut


=back

=cut


1;
__END__

=head1 SEE ALSO

L<Treex::PML::Schema>, L<Treex::PML::Schema::XMLNode>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2010 by Petr Pajas, 2010-2024 Jan Stepanek

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut

