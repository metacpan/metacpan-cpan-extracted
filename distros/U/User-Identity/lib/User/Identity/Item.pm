# This code is part of Perl distribution User-Identity version 1.03.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2003-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

#oodist: *** DO NOT USE THIS VERSION FOR PRODUCTION ***
#oodist: This file contains OODoc-style documentation which will get stripped
#oodist: during its release in the distribution.  You can use this file for
#oodist: testing, however the code of this development version may be broken!

package User::Identity::Item;{
our $VERSION = '1.03';
}


use strict;
use warnings;

use Scalar::Util qw/weaken/;
use Carp;

#--------------------

sub new(@)
{	my $class = shift;
	return undef unless @_;       # no empty users.

	unshift @_, 'name' if @_ %2;  # odd-length list: starts with nick

	my %args = @_;
	my $self = (bless {}, $class)->init(\%args);

	if(my @missing = keys %args)
	{	local $" = '", "';
		warn "WARNING: Unknown ".(@missing==1? 'option' : 'options' ). " \"@missing\" for a $class\n";
	}

	$self;
}

sub init($)
{	my ($self, $args) = @_;

	unless(defined($self->{UII_name} = delete $args->{name}))
	{	croak "ERROR: Each item requires a name";
	}

	$self->{UII_description} = delete $args->{description};
	$self;
}

#--------------------

sub name(;$)
{	my $self = shift;
	@_ ? ($self->{UII_name} = shift) : $self->{UII_name};
}


sub description() { $_[0]->{UII_description} }

#--------------------

our %collectors = (
	emails      => 'User::Identity::Collection::Emails',
	locations   => 'User::Identity::Collection::Locations',
	systems     => 'User::Identity::Collection::Systems',
	users       => 'User::Identity::Collection::Users',
);  # *s is tried as well, so email, system, and location will work

sub addCollection(@)
{	my $self = shift;
	@_ or return;

	my $object;
	if(ref $_[0])
	{	$object = shift;
		$object->isa('User::Identity::Collection') or croak "ERROR: $object is not a collection";
	}
	else
	{	unshift @_, 'type' if @_ % 2;
		my %args  = @_;
		my $type  = delete $args{type};

		$type or croak "ERROR: Don't know what type of collection you want to add";

		my $class = $collectors{$type} || $collectors{$type.'s'} || $type;
		eval "require $class";
		$@ and croak "ERROR: Cannot load collection module $type ($class); $@\n";

		$object = $class->new(%args);
		defined $object or croak "ERROR: Creation of a collection via $class failed\n";
	}

	$object->parent($self);
	$self->{UI_col}{$object->name} = $object;
}



sub removeCollection($)
{	my $self = shift;
	my $name = ref $_[0] ? $_[0]->name : $_[0];

	   delete $self->{UI_col}{$name}
	|| delete $self->{UI_col}{$name.'s'};
}



sub collection($;$)
{	my $self       = shift;
	my $collname   = shift;
	my $collection = $self->{UI_col}{$collname} || $self->{UI_col}{$collname.'s'} || return;

	wantarray ? $collection->roles : $collection;
}



sub add($$)
{	my ($self, $collname) = (shift, shift);
	my $collection
	  = ref $collname && $collname->isa('User::Identity::Collection') ? $collname
	  :   ($self->collection($collname) || $self->addCollection($collname));

	unless($collection)
	{	carp "No collection $collname";
		return;
	}

	$collection->addRole(@_);
}


sub type { "item" }


sub parent(;$)
{	my $self = shift;
	@_ or return $self->{UII_parent};

	$self->{UII_parent} = shift;
	weaken($self->{UII_parent});
	$self->{UII_parent};
}


sub user()
{	my $self   = shift;
	my $parent = $self->parent;
	defined $parent ? $parent->user : undef;
}

#--------------------

sub find($$)
{	my $all        = shift->{UI_col};
	my $collname   = shift;
	my $collection
	  = ref $collname && $collname->isa('User::Identity::Collection') ? $collname
	  :    ($all->{$collname} || $all->{$collname.'s'});

	defined $collection ? $collection->find(shift) : ();
}

1;
