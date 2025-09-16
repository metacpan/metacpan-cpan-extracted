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

package User::Identity::System;{
our $VERSION = '1.03';
}

use base 'User::Identity::Item';

use strict;
use warnings;

use User::Identity;
use Scalar::Util 'weaken';

#--------------------

sub type { "network" }


sub init($)
{	my ($self, $args) = @_;

	$self->SUPER::init($args);
	exists $args->{$_} && ($self->{'UIS_'.$_} = delete $args->{$_})
		for qw/hostname location os password username/;

	$self->{UIS_hostname} ||= 'localhost';
	$self;
}

#--------------------

sub hostname() { $_[0]->{UIS_hostname} }
sub username() { $_[0]->{UIS_username} }
sub os()       { $_[0]->{UIS_os} }
sub password() { $_[0]->{UIS_password} }


sub location()
{	my $self      = shift;
	my $location  = $self->{MI_location} or return;

	unless(ref $location)
	{	my $user  = $self->user or return;
		$location = $user->find(location => $location);
	}

	$location;
}

1;
