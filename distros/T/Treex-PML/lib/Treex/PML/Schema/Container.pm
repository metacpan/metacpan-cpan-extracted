package Treex::PML::Schema::Container;

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
use UNIVERSAL::DOES;
use Treex::PML::Factory;

=head1 NAME

Treex::PML::Schema::Container - implements declaration of a container.

=head1 INHERITANCE

This class inherits from L<Treex::PML::Schema::Decl>, but provides
several methods which make its interface largely compatible with
the C<Treex::PML::Schema::Struct> class.

=head1 METHODS

See the super-class for the complete list.

=over 3

=item $decl->get_decl_type ()

Returns the constant PML_CONTAINER_DECL.

=item $decl->get_decl_type_str ()

Returns the string 'container'.

=item $decl->get_content_decl ()

Return declaration of the content type.

=item $decl->is_atomic ()

Returns 0.

=cut

sub get_decl_type { return PML_CONTAINER_DECL; }
sub get_decl_type_str { return 'container'; }
sub is_atomic { 0 }

sub init {
  my ($self,$opts)=@_;
  $self->{-parent}{-decl} = 'container';
}
sub serialize_get_children {
  my ($self,$opts)=@_;
  my @children = $self->SUPER::serialize_get_children($opts);
  return ((grep { $_->[0] eq 'attribute' } @children),
	  (grep { $_->[0] ne 'attribute' } @children));
}

=item $decl->get_attributes ()

Return a list of the associated attribute declarations
(C<Treex::PML::Schema::Attribute>).

=cut

sub get_attributes { 
  my $members = $_[0]->{attribute};
  return $members ? map { $_->[0] } sort { $a->[1]<=> $b->[1] } map { [ $_, $_->{'-#'} ] } values %$members : (); 
}

=item $decl->has_attributes ()

Return true if the container declares attributes.

=cut

sub has_attributes { 
  my $members = $_[0]->{attribute};
  return $members ? scalar(%$members) : 0;
}


=item $decl->get_attribute_names ()

Return a list of names of attributes associated with the container.

=cut

sub get_attribute_names { 
  my $members = $_[0]->{attribute};
  return $members ? map { $_->[0] } sort { $a->[1]<=> $b->[1] } map { [ $_, $members->{$_}->{'-#'} ] } keys %$members : (); 
}

=item $decl->get_attribute_by_name (name)

Return the declaration of the attribute with a given name.

=cut

sub get_attribute_by_name {
  my ($self, $name) = @_;
  my $members = $_[0]->{attribute};
  return $members ? $members->{$name} : undef;
}

=item $decl->find_attributes_by_content_decl (decl)

Lookup and return those attribute declarations whose content
declaration is decl.

=cut

sub find_attributes_by_content_decl {
  my ($self, $decl) = @_;
  return grep { $decl == $_->get_content_decl } $self->get_attributes;
}

=item $decl->find_attributes_by_type_name (name)

Lookup and return those attribute declarations whose content is
specified via a reference to the named type with a given name.

=cut

sub find_attributes_by_type_name {
  my ($self, $type_name) = @_;
  # using directly $member->{type}
  return grep { $type_name eq $_->{type} } $self->get_attributes;  
}

=item $decl->find_attributes_by_role (role)

Lookup and return declarations of all members with a given role.

=cut

sub find_attributes_by_role {
  my ($self, $role) = @_;
  # using directly $member->{role}
  return grep { $role eq $_->{role} } $self->get_attributes;  
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

  if (not UNIVERSAL::isa($object,'HASH')) {
    push @$log, "$path: Unexpected container object (should be a HASH): $object";
  } else {
    my @attributes = $self->get_attributes;
    foreach my $attr (@attributes) {
      my $name = $attr->get_name;
      my $val = $object->{$name};
      my $adecl = $attr->get_content_decl;
      if ($attr->is_required or $val ne q{}) {
	if (ref($val)) {
	  push @$log, "$path/$name: invalid content for attribute: ".ref($val);
	} elsif ($adecl) {
	  $adecl->validate_object($val, {
	    flags => $flags,
	    path => $path,
	    tag => $name, 
	    log => $log });
	}
      }
    }
    my $cdecl = $self->get_content_decl;
    if ($cdecl) {
      my $content = $object->{'#content'};
      my $skip_content = 0;
      if ($self->get_role eq '#NODE' and !($flags & PML_VALIDATE_NO_TREES)) {
	if (not UNIVERSAL::DOES::does($object,'Treex::PML::Node')) {
	  push @$log,"$path: container declared as #NODE should be a Treex::PML::Node object: $object";
	} else {
	  my $cdecl_is = $cdecl->get_decl_type;
	  if ($cdecl->get_role eq '#CHILDNODES') {
	    if ($content ne q{}) {
	      push @$log, "$path: #NODE container containing a #CHILDNODES should have empty #content: $content";
	    }
	    if ($flags & PML_VALIDATE_NO_CHILDNODES) {
	      $skip_content = 1;
	    } elsif ($cdecl_is == PML_SEQUENCE_DECL) {
	      $content = Treex::PML::Factory->createSeq([map { Treex::PML::Seq::Element->new($_->{'#name'},$_) } $object->children]);
	    } elsif ($cdecl_is == PML_LIST_DECL) {
	      $content = Treex::PML::Factory->createList([$object->children],1);
	    } else {
	      push @$log, "$path: #CHILDNODES should be either a list or sequence";
	    }
	  }
	}
      }
      unless ($skip_content) {
	$cdecl->validate_object($content,{ 
	  flags => $flags,
	  path => $path,
	  tag => '#content',
	  log =>$log
	 });
      }
    }
  }
  if ($opts and ref($opts->{log})) {
    push @{$opts->{log}}, @$log;
  }
  return @$log ? 0 : 1;
}

=back

=head1 COMPATIBILITY METHODS

=over 3

=item $decl->get_members ()

Return declarations of all associated attributes and of the content
type.

=cut

sub get_members {
  my $self = shift;
  return ($self->get_attributes, $self->get_content_decl);
}

=item $decl->get_member_by_name (name)

If name is equal to '#content', return the content type declaration,
otherwise acts like C<get_attribute_by_name>.

=cut

sub get_member_by_name {
  my ($self, $name) = @_;
  if ($name eq '#content') {
    return $self->get_content_decl
  } else {
    return $self->get_attribute_by_name($name);
  }
}

=item $decl->get_member_names ()

Return a list of all attribute names plus the string '#content'.

=cut

sub get_member_names {
  my $self = shift;
  return ($self->get_attribute_names, ($self->get_content_decl ? ('#content') : ()))
}


=item $decl->find_members_by_content_decl (decl)

Lookup and return those member (attribute or content) declarations
whose content declaration is decl.

=item $decl->find_members_by_type_name (name)

Lookup and return those member (attribute or content) declarations
whose content is specified via a reference to the named type with a
given name.

=item $decl->find_members_by_role (role)

Lookup and return declarations of all members (attribute or content)
with a given role.

=cut

*find_members_by_content_decl = \&Treex::PML::Schema::Struct::find_members_by_content_decl;
*find_members_by_type_name = \&Treex::PML::Schema::Struct::find_members_by_type_name;
*find_members_by_role = \&Treex::PML::Schema::Struct::find_members_by_role;

=back

=cut

1;
__END__

=head1 SEE ALSO

L<Treex::PML::Schema::Decl>, L<Treex::PML::Schema>, L<Treex::PML::Schema::Attribute>,
L<Treex::PML::Container>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2010 by Petr Pajas, 2010-2024 Jan Stepanek

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut

