# This code is part of Perl distribution User-Identity version 3.00.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2003-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package User::Identity::Collection;{
our $VERSION = '3.00';
}

use base 'User::Identity::Item';

use strict;
use warnings;

use User::Identity ();

use Hash::Ordered  ();

use Carp;
use List::Util     qw/first/;


#--------------------

use overload '""' => sub {
	my $self = shift;
	$self->name . ": " . join(", ", sort map $_->name, $self->roles);
};


use overload '@{}' => sub { [ $_[0]->roles ] };

#--------------------

sub type { "people" }


sub init($)
{	my ($self, $args) = @_;
	defined($self->SUPER::init($args)) or return;

	$self->{UIC_itype} = delete $args->{item_type} or die;
	tie %{$self->{UIC_roles}}, 'Hash::Ordered';
	my $roles = $args->{roles};

	my @roles
	  = ! defined $roles      ? ()
	  : ref $roles eq 'ARRAY' ? @$roles
	  :   $roles;

	$self->addRole($_) for @roles;
	$self;
}

#--------------------

sub roles() { values %{ $_[0]->{UIC_roles}} }


sub itemType { $_[0]->{UIC_itype} }

#--------------------

sub addRole(@)
{	my $self = shift;
	my $maintains = $self->itemType;

	my $role;
	if(ref $_[0] && ref $_[0] ne 'ARRAY')
	{	$role = shift;
		$role->isa($maintains)
			or croak "ERROR: Wrong type of role for ".ref($self) . ": requires a $maintains but got a ". ref($role);
	}
	else
	{	$role = $maintains->new(ref $_[0] ? @{$_[0]} :  @_);
		defined $role
			or croak "ERROR: Cannot create a $maintains to add this to my collection.";
	}

	$role->parent($self);
	$self->{UIC_roles}{$role->name} = $role;
	$role;
}


sub removeRole($)
{	my ($self, $which) = @_;
	my $name = ref $which ? $which->name : $which;
	my $role = delete $self->{UIC_roles}{$name} or return ();
	$role->parent(undef);
	$role;
}


sub renameRole($$$)
{	my ($self, $which, $newname) = @_;
	my $name = ref $which ? $which->name : $which;

	if(exists $self->{UIC_roles}{$newname})
	{	$self->log(ERROR => "cannot rename $name into $newname: already exists");
		return ();
	}

	my $role = delete $self->{UIC_roles}{$name};
	unless(defined $role)
	{	$self->log(ERROR => "cannot rename $name into $newname: doesn't exist");
		return ();
	}

	$role->name($newname);   # may imply change other attributes.
	$self->{UIC_roles}{$newname} = $role;
}


sub sorted() { sort {$a->name cmp $b->name} shift->roles}

#--------------------

sub find($)
{	my ($self, $select) = @_;

	    !defined $select ? ($self->roles)[0]
	  : !ref $select     ? $self->{UIC_roles}{$select}
	  : wantarray        ? (grep $select->($_, $self), $self->roles)
	  :    first { $select->($_, $self) } $self->roles;
}

1;
