# ====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================

package LS::SOAP::Serializer;

use strict;
use vars qw(@ISA);

use SOAP::Lite;


@ISA = qw(SOAP::Serializer);


#
# new - The only change from SOAP::Serializer::new is to change some
# 	default attributes: 
#
#		- remove extraneous attributes from the envelope,
# 		- turn autotyping off, 
#		- remove extraneous namespace declarations from	the envelope, 
#		- set the namespace prefix that will be used on	the method element.
#
sub new {

	my $self = shift;
	my $initialized = ref $self;

	$self = $self->SUPER::new(@_);

	if (!$initialized) {


		my $ns = {
				$SOAP::Constants::NS_ENV=> $SOAP::Constants::PREFIX_ENV,
				$SOAP::Constants::DEFAULT_XML_SCHEMA=> 'xsd',
			};
		$self
			-> attr({})
			-> autotype(0)
			-> namespaces($ns)
			-> method_prefix('')
	}

	return $self;
}


#
# method_prefix - This is a method not found in SOAP::Serializer.  It allows
# 		  setting and retrieval of the namespace prefix used on the
# 		  method element in the envelope.
#
sub method_prefix {

	my $self = shift->new;
	@_ ? ($self->{_method_prefix} = shift, return $self) : return $self->{_method_prefix};
}


#
# encode_array - This does the same thing as SOAP::Serializer::encode_array,
# 		 except that it doesn't calculate the 'arrayType' attribute.
#
sub encode_array {

	my($self, $array, $name, $type, $attr) = @_;
	my $items = 'item'; 

	my @items = map {$self->encode_object($_, $items)} @$array;

	$type = qualify($self->encprefix => 'Array') if $self->autotype && !defined $type;

	return [
		$name || qualify($self->encprefix => 'Array'), 
		{'xsi:type' => $self->maptypetouri($type), %$attr},
          	[@items], 
          	$self->gen_id($array)
  	];
}


#
# envelope - The same as SOAP::Serializer::envelope, except we set the
# 	     prefix of the method element to the one that was explicitly
# 	     chosen, rather than allowing it to be internally generated.
#
sub envelope {

	my $self = shift->new;

	if ($_[0] eq 'method' || $_[0] eq 'response') {
		$_[1] = SOAP::Data 
				-> name($_[1])
				-> prefix($self->method_prefix)
				-> uri($self->uri);
	}

	$self->SUPER::envelope(@_);
}

1;

__END__
