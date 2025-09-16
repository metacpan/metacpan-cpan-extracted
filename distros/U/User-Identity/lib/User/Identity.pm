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

package User::Identity;{
our $VERSION = '1.03';
}

use base 'User::Identity::Item';

use strict;
use warnings;

use Carp;

#--------------------

use overload '""' => 'fullName';

#--------------------

my @attributes = qw/charset courtesy birth full_name formal_name firstname
	gender initials language nickname prefix surname titles/;

sub init($)
{	my ($self, $args) = @_;

	exists $args->{$_} && ($self->{'UI_'.$_} = delete $args->{$_})
		for @attributes;

	$self->SUPER::init($args);
}

sub type() { 'user' }
sub user() { $_[0] }

#--------------------

sub charset() { $_[0]->{UI_charset} || $ENV{LC_CTYPE} }


sub nickname()
{	my $self = shift;
	$self->{UI_nickname} || $self->name;
	# TBI: If OS-specific info exists, then username
}


sub firstname()
{	my $self = shift;
	$self->{UI_firstname} || ucfirst $self->nickname;
}


sub initials()
{	my $self = shift;
	return $self->{UI_initials} if defined $self->{UI_initials};

	if(my $firstname = $self->firstname)
	{	my $i = '';
		while( $firstname =~ m/(\w+)(\-)?/g )
		{	my ($part, $connect) = ($1,$2);
			$connect ||= '.';
			$part =~ m/^(chr|th|\w)/i;
			$i .= ucfirst(lc $1).$connect;
		}
		return $i;
	}
}


sub prefix() { $_[0]->{UI_prefix} }


sub surname() { $_[0]->{UI_surname} }


sub fullName()
{	my $self = shift;
	return $self->{UI_full_name} if defined $self->{UI_full_name};

	my ($first, $prefix, $surname) = @$self{ qw/UI_firstname UI_prefix UI_surname/};

	$surname = ucfirst $self->nickname if  defined $first && ! defined $surname;
	$first   = $self->firstname        if !defined $first &&   defined $surname;

	my $full = join ' ', grep defined, ($first, $prefix, $surname);
	$full = $self->firstname unless length $full;

	# TBI: if OS-specific knowledge, then unix GCOS?

	$full;
}


sub formalName()
{	my $self = shift;
	return $self->{UI_formal_name} if defined $self->{UI_formal_name};

	my $initials = $self->initials;

	my $firstname = $self->{UI_firstname};
	$firstname = "($firstname)" if defined $firstname;

	join ' ', grep defined,
		$self->courtesy, $initials, @$self{ qw/UI_prefix UI_surname UI_titles/ };
}


my %male_courtesy= (
	mister    => 'en',
	mr        => 'en',
	sir       => 'en',
	'de heer' => 'nl',
	mijnheer  => 'nl',
	dhr       => 'nl',
	herr      => 'de',
);

my %male_courtesy_default = (
	en        => 'Mr.',
	nl        => 'De heer',
	de        => 'Herr',
);

my %female_courtesy = (
	miss      => 'en',
	ms        => 'en',
	mrs       => 'en',
	madam     => 'en',
	mevr      => 'nl',
	mevrouw   => 'nl',
	frau      => 'de',
);

my %female_courtesy_default = (
	en        => 'Madam',
	nl        => 'Mevrouw',
	de        => 'Frau',
);

sub courtesy()
{	my $self = shift;
	return $self->{UI_courtesy} if defined $self->{UI_courtesy};

	my $table
	  = $self->isMale   ? \%male_courtesy_default
	  : $self->isFemale ? \%female_courtesy_default
	  :    return undef;

	my $lang = lc $self->language;
	return $table->{$lang} if exists $table->{$lang};

	$lang =~ s/\..*//;     # "en_GB.utf8" --> "en-GB"  and retry
	return $table->{$lang} if exists $table->{$lang};

	$lang =~ s/[-_].*//;   # "en_GB.utf8" --> "en"  and retry
	$table->{$lang};
}


# TBI: if we have a courtesy, we may detect the language.
# TBI: when we have a postal address, we may derive the language from
#      the country.
# TBI: if we have an e-mail addres, we may derive the language from
#      that.

sub language() { $_[0]->{UI_language} || 'en' }


sub gender() { $_[0]->{UI_gender} }


sub isMale()
{	my $self = shift;

	if(my $gender = $self->{UI_gender})
	{	return $gender =~ m/^[mh]/i;
	}

	if(my $courtesy = $self->{UI_courtesy})
	{	$courtesy = lc $courtesy;
		$courtesy =~ s/[^\s\w]//g;
		return 1 if exists $male_courtesy{$courtesy};
	}

	undef;
}


sub isFemale()
{	my $self = shift;

	if(my $gender = $self->{UI_gender})
	{	return $gender =~ m/^[vf]/i;
	}

	if(my $courtesy = $self->{UI_courtesy})
	{	$courtesy = lc $courtesy;
		$courtesy =~ s/[^\s\w]//g;
		return 1 if exists $female_courtesy{$courtesy};
	}

	undef;
}


sub dateOfBirth() { $_[0]->{UI_birth} }


sub birth()
{	my $birth = shift->dateOfBirth;
	my $time;

	if($birth =~ m/^\s*(\d{4})[-\s]*(\d{2})[-\s]*(\d{2})\s*$/)
	{	# Pre-formatted.
		return sprintf "%04d%02d%02d", $1, $2, $3;
	}

	eval "require Date::Parse";
	unless($@)
	{	my ($day,$month,$year) = (Date::Parse::strptime($birth))[3,4,5];
		if(defined $year)
		{	return sprintf "%04d%02d%02d",
				($year + 1900),
				(defined $month ? $month+1 : 0),
				($day || 0);
		}
	}

	# TBI: Other date parsers

	undef;
}


sub age()
{	my $birth = shift->birth or return;

	my ($year, $month, $day) = $birth =~ m/^(\d{4})(\d\d)(\d\d)$/;
	my ($today, $tomonth, $toyear) = (localtime)[3,4,5];
	$tomonth++;

	my $age = $toyear+1900 - $year;
	$age-- if $month > $tomonth || ($month == $tomonth && $day >= $today);
	$age;
}


sub titles() { $_[0]->{UI_titles} }

1;
