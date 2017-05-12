# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================
package LS::Service::AdvancedDataService;

use strict;
use warnings;

use vars qw( $METHODS );

use LS;
use LS::ID;

use base 'LS::Service::DataService';

sub BEGIN {

	$METHODS = [
		'mappings',
	];
	
	LS::makeAccessorMethods($METHODS, __PACKAGE__);
}

#
# new( %options ) -
#
sub new {

	my $self = shift;
	$self = $self->SUPER::new( @_ );
	
	return undef
		unless(ref $self);
	
	$self->mappings( {} );
	return $self;
}


#
# addNamespaceMappings( %mappings ) -
#
sub addNamespaceMappings {

	my $self = shift;
	my %mappings = @_;

	foreach my $regex (keys(%mappings)) {
		$self->mappings()->{ $regex } = $mappings{ $regex };
	}
}


#
# findNamespace( $namespace ) -
#
sub findNamespace {

	my $self = shift;
	my $namespace = shift;

	my $ns = $self->SUPER::findNamespace( $namespace );
	
	# Exact match takes precedence
	return $ns
		if($ns);

	# Look for a mapping
	foreach my $regex (keys(%{ $self->mappings() }) ) {

		if($namespace =~ m/$regex/) {

			my $cmp_namespace = $self->mappings->{ $regex };
			
			$ns = $self->SUPER::findNamespace( $cmp_namespace );
			last
				if($ns);
		}

	} # end foreach

	return $ns;
}

1;

__END__
