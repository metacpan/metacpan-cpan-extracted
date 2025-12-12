# This code is part of Perl distribution User-Identity version 4.00.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2003-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package User::Identity::Collection;{
our $VERSION = '4.00';
}

use parent 'User::Identity::Item';

use strict;
use warnings;

use Log::Report     'user-identity';

use User::Identity  ();
use Hash::Ordered   ();

use List::Util      qw/first/;

#--------------------

use overload '""' => sub {
	my $self = shift;
	$self->name . ": " . join(", ", sort map $_->name, $self->roles);
};


use overload '@{}' => sub { [ $_[0]->roles ] };

#--------------------

sub type { 'people' }


sub init($)
{	my ($self, $args) = @_;
	defined($self->SUPER::init($args)) or return;

	$self->{UIC_itype} = delete $args->{item_type} or panic;
	tie %{$self->{UIC_roles}}, 'Hash::Ordered';

	my $roles = $args->{roles};
	my @roles = ! defined $roles ? () : ref $roles eq 'ARRAY' ? @$roles : $roles;
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
			or error __x"wrong type of role for {collection}: requires a {expect} but got a {type}.",
				collection => ref $self, expect => $maintains, type => ref $role;
	}
	else
	{	$role = $maintains->new(ref $_[0] ? @{$_[0]} :  @_)
			or error __x"cannot create a {type} to add this to my collection.", type => $maintains;
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

	! exists $self->{UIC_roles}{$newname}
		or error __x"cannot rename {from} into {to}: already exists", from => $name, to => $newname;

	my $role = delete $self->{UIC_roles}{$name}
		or error __x"cannot rename {from} into {to}: doesn't exist", from => $name, to => $newname;

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
