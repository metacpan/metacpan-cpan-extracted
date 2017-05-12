package Treex::PML::Schema::Struct;

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
use UNIVERSAL::DOES;

=head1 NAME

Treex::PML::Schema::Struct - implements declaration of a structure.

=head1 INHERITANCE

This class inherits from L<Treex::PML::Schema::Decl>.

=head1 METHODS

See the super-class for the complete list.

=over 3

=item $decl->get_decl_type ()

Returns the constant PML_STRUCTURE_DECL.

=item $decl->get_decl_type_str ()

Returns the string 'structure'.

=item $decl->get_structure_name ()

Return declared structure name (if any).

=item $decl->get_content_decl ()

Returns undef.

=item $decl->is_atomic ()

Returns 0.

=cut



sub is_atomic { 0 }
sub get_decl_type { return PML_STRUCTURE_DECL; }
sub get_decl_type_str { return 'structure'; }
sub get_content_decl { return(undef); }
sub get_structure_name { return $_[0]->{name}; }

sub init {
  my ($self,$opts)=@_;
  $self->{-parent}{-decl} = 'structure';
}

=item $decl->get_members ()

Return a list of the associated member declarations
(C<Treex::PML::Schema::Member>).

=cut

sub get_members { 
  my $members = $_[0]->{member};
  return $members ? map { $_->[0] } sort { $a->[1]<=> $b->[1] } map { [ $_, $_->{'-#'} ] } values %$members : (); 
}

=item $decl->get_member_names ()

Return a list of names of all members of the structure.

=cut

sub get_member_names { 
  my $members = $_[0]->{member};
  return $members ? map { $_->[0] } sort { $a->[1]<=> $b->[1] } map { [ $_, $members->{$_}->{'-#'} ] } keys %$members : (); 
}

=item $decl->get_member_by_name (name)

Return the declaration of the member with a given name.

=cut

sub get_member_by_name {
  my ($self, $name) = @_;
  my $members = $_[0]->{member};
  return $members ? $members->{$name} : undef;
}

=item $decl->get_attributes ()

Return a list of member declarations (C<Treex::PML::Schema::Member>) declared
as attributes.

=cut

sub get_attributes { 
  my $members = $_[0]->{member};
  return $members ? map { $_->[0] } sort { $a->[1]<=> $b->[1] } map { [ $_, $_->{'-#'} ] } 
    grep { $_->{as_attribute} } values %$members : (); 
}

=item $decl->get_attribute_names ()

Return a list of names of all members of the structure declared as
attributes.

=cut

sub get_attribute_names { 
  my $members = $_[0]->{member};
  return $members ? map { $_->[0] } sort { $a->[1]<=> $b->[1] } map { [ $_, $members->{$_}->{'-#'} ] } 
    grep { $_->{as_attribute} } keys %$members : (); 
}



=item $decl->find_members_by_content_decl (decl)

Lookup and return those member declarations whose content declaration
is decl.

=cut

sub find_members_by_content_decl {
  my ($self, $decl) = @_;
  return grep { $decl == $_->get_content_decl } $self->get_members;
}

=item $decl->find_members_by_type_name (name)

Lookup and return those member declarations whose content is specified
via a reference to the named type with a given name.

=cut

sub find_members_by_type_name {
  my ($self, $type_name) = @_;
  # using directly $member->{type}
  return grep { defined($_->{type}) and $_->{type} eq $type_name } $self->get_members;  
}

=item $decl->find_members_by_role (role)

Lookup and return declarations of all members with a given role.

=cut

sub find_members_by_role {
  my ($self, $role) = @_;
  # using directly $member->{role}
  return grep { defined($_->{role}) and $_->{role} eq $role } $self->get_members;
}

sub validate_object {
  my ($self,$object,$opts) = @_;

  my ($path,$tag,$flags);
  my $log = [];
  if (ref($opts)) {
    $flags = $opts->{flags};
    $path = $opts->{path};
    $tag = $opts->{tag};
    $path.="/".$tag if $tag ne q{};
  }

  my $members = $self->get_members;
  if (!UNIVERSAL::isa($object,'HASH')) {
    push @$log, "$path: Unexpected content of the structure '$self->{name}': '$object'";
  } else {
    my @members = $self->get_members;
    foreach my $member (grep { $_->is_attribute } @members) {
      my $name = $member->get_name;
      if (ref $object->{$name}) {
	push @$log,"$path/$name: invalid content for member declared as attribute: ".ref($object->{$name});
      }
    }
    foreach my $member (@members) {
      my $name = $member->get_name;
      my $role = $member->get_role;
      my $mtype = $member->get_content_decl;
      my $val = $object->{$name};
      my $knit_name = $member->get_knit_name;
      if ($role eq '#CHILDNODES' and !($flags & PML_VALIDATE_NO_TREES)) {
	if (not UNIVERSAL::DOES::does($object,'Treex::PML::Node')) {
	  push @$log, "$path/$name: #CHILDNODES member on a non-node object: $object";
	}
	unless ($flags & PML_VALIDATE_NO_CHILDNODES) {
	  my $content;
	  my $mtype_is = $mtype->get_decl_type;
	  if ($mtype_is == PML_SEQUENCE_DECL) {
	    $content = Treex::PML::Factory->createSeq([map { Treex::PML::Seq::Element->new($_->{'#name'},$_) } $object->children]);
	  } elsif ($mtype_is == PML_LIST_DECL) {
	    $content = Treex::PML::Factory->createList([$object->children],1);
	  } else {
	    push @$log, "$path: #CHILDNODES should be either a list or sequence type";
	  }
	  $mtype->validate_object($content,
				  { flags => $flags,
				    path => $path,
				    tag => $name,
				    log => $log,
				  } );
	}
      } elsif ($name ne $knit_name) {
	my $knit_val = $object->{$knit_name};
	my $mtype;
	if ($knit_val ne q{} and $val ne q{}) {
	  push @$log, "$path/$knit_name: both '$name' and '$knit_name' are present for a #KNIT member";
	} elsif ($val ne q{}) {
	  $knit_name = $name;
	  $knit_val = $val;
	  $mtype = $member->get_content_decl;
	} else {
	  $mtype = $member->get_knit_content_decl;
	}
	if (defined $mtype) {
	  if ($knit_val ne q{} or $member->is_required) {
	    $mtype->validate_object($knit_val,
				       { flags => $flags,
					 path => $path,
					 tag => $knit_name,
					 log => $log
					});
	  }
	} else {
	  push @$log, "$path/$knit_name: can't determine data type of the #KNIT member";
	}
      } elsif ($val ne q{}) {
	$mtype->validate_object($val,
				{ flags => $flags,
				  path => $path,
				  tag => $name,
				  log => $log,
				} );
      } elsif ($member->is_required) {
	push @$log, "$path/$name: CDATA member declared as required cannot be empty!";
      }
    }
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

L<Treex::PML::Schema::Decl>, L<Treex::PML::Schema>, L<Treex::PML::Schema::Member>, L<Treex::PML::Struct>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2010 by Petr Pajas

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut

