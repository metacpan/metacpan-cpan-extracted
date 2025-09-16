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

package User::Identity::Location;{
our $VERSION = '1.03';
}

use base 'User::Identity::Item';

use strict;
use warnings;

use User::Identity;
use Scalar::Util 'weaken';

#--------------------

sub type { "location" }


sub init($)
{	my ($self, $args) = @_;

	$args->{postal_code} ||= delete $args->{pc};

	$self->SUPER::init($args);

	exists $args->{$_} && ($self->{'UIL_'.$_} = delete $args->{$_})
		for qw/city country country_code fax organization pobox pobox_pc postal_code state street phone/;

	$self;
}

#--------------------

sub street() { $_[0]->{UIL_street} }


sub postalCode() { $_[0]->{UIL_postal_code} }


sub pobox() { $_[0]->{UIL_pobox} }


sub poboxPostalCode() { $_[0]->{UIL_pobox_pc} }


sub city() { $_[0]->{UIL_city} }


sub state() { $_[0]->{UIL_state} }


sub country()
{	my $self = shift;
	return $self->{UIL_country} if defined $self->{UIL_country};

	my $cc = $self->countryCode or return;

	eval 'require Geography::Countries';
	return if $@;

	scalar Geography::Countries::country($cc);
}


sub countryCode() { $_[0]->{UIL_country_code} }


sub organization() { $_[0]->{UIL_organization} }


sub phone()
{	my $self = shift;

	my $phone = $self->{UIL_phone} or return ();
	my @phone = ref $phone ? @$phone : $phone;
	wantarray ? @phone : $phone[0];
}


sub fax()
{	my $self = shift;

	my $fax = $self->{UIL_fax} or return ();
	my @fax = ref $fax ? @$fax : $fax;
	wantarray ? @fax : $fax[0];
}


sub fullAddress()
{	my $self = shift;
	my $cc   = $self->countryCode || 'en';

	my ($address, $pc);
	if($address = $self->pobox) { $pc = $self->poboxPostalCode }
	else { $address = $self->street; $pc = $self->postalCode }

	my ($org, $city, $state) = @$self{ qw/UIL_organization UIL_city UIL_state/ };
	defined $city && defined $address or return;

	my $country = $self->country;
	$country
	  = defined $country ? "\n$country"
	  : defined $cc      ? "\n".uc($cc)
	  :   '';

	if(defined $org) {$org .= "\n"} else {$org = ''};

	if($cc eq 'nl')
	{	$pc = "$1 ".uc($2)."  " if defined $pc && $pc =~ m/(\d{4})\s*([a-zA-Z]{2})/;
		return "$org$address\n$pc$city$country\n";
	}
	else
	{	$state ||= '';
		return "$org$address\n$city$state$country\n$pc";
	}
}

1;
