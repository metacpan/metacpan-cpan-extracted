# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
#
# =====================================================================
package testAssigningAuth;

use strict;
use warnings;

use Data::Dumper;

# Not much to do here
sub new {

	my $self = shift;

	$self = bless {
		}, $self;

	return $self;
}

sub assignLSID {

	my $self = shift;

	my $authority = shift;
	my $namespace = shift;

	my $prop = shift;
	my $string;

	foreach(@{ $prop } ) {

		my ($n) = keys(%{ $_ });
		my $v = $_->{$n};
		$string .= "$n$v";
	}
	return LS::ID->new("urn:lsid:$authority:$namespace:$string");
}

sub assignLSIDFromList {

	my $self = shift;

	my $prop = shift;

	my $string;

	foreach(@{ $prop } ) {

		my ($n) = keys(%{ $_ });
		my $v = $_->{$n};
		$string .= "$n$v";
	}

	my $suggested = shift;

	foreach(@{ $suggested }) {

		$string .= $_->as_string;
	}

	$string =~ s/:/;/g;
	
	return LS::ID->new("urn:lsid:authority:namespace:$string");
}

sub getLSIDPattern {

	my $self = shift;

	my $authority = shift;
	my $namespace = shift;

	my $prop = shift;
	my $string;

	foreach(@{ $prop } ) {

		my ($n) = keys(%{ $_ });
		my $v = $_->{$n};
		$string .= "$n$v";
	}

	return "$authority-$namespace-$string";
}

sub getLSIDPatternFromList {

	my $self = shift;

	my $prop = shift;
	my $string;

	foreach(@{ $prop } ) {

		my ($n) = keys(%{ $_ });
		my $v = $_->{$n};
		$string .= "$n$v";
	}

	my $list = shift;

	foreach(@{ $list }) {

		$string .= $_;
	}

	$string =~ s/:/;/;

	return $string;
}

sub assignLSIDForNewRevision {

	my $self = shift;

	my $lsid = shift;

	return $lsid;
}

sub getAllowedPropertyNames {
	my $self = shift;

	return [ 'NAME1', 'NAME2' ];
}

sub getAuthoritiesAndNamespaces {
	my $self = shift;

	my $an_ref = [
			{ 'authority1'=> 'namespace1' },
			{ 'authority2'=> 'namespace2' },

			];

	return $an_ref;
}

1;

__END__
