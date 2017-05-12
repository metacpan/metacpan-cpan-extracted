# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================
package LS::RDF::Complex;


package LS::RDF::ComplexDocument;

use strict;
use warnings;


use LS::RDF::Constants;
use LS::RDF::SimpleDocument;


use base 'LS::RDF::SimpleDocument';


#
# new( %options ) -
#
sub new { 

	my $self = shift;

	unless (ref $self) {

		my $class = $self->SUPER::new(@_);
		
		$self = bless $class, $self;
	}
	
	return $self;
}


#
# addBlankNode( $subject, $predicate ) -
#
sub addBlankNode {

	my $self = shift;

	my ($_sub, $_pred) = @_;

	my $subject = $self->{'_factory'}->newResource($_sub);
	my $predicate = $subject->new($_pred);
	my $object = $self->{'_factory'}->newResource();

	$self->_create_statement($subject, $predicate, $object);

	return $object->getURI();
}


#
# createBag( ) - Creates an RDF Bag
#
sub createBag {

	my $self = shift;

	my $elementFactory = (	$self->{'_bagElementFactory'} || 
				RDF::Core::NodeFactory->new(BaseURI=> ${ LS::RDF::Constants::BASE_URI },
							    GenPrefix=> '_:element')
			     );

	$self->{'_bagElementFactory'} = $elementFactory unless($self->{'_bagElementFactory'});

	my $predicateFactory = ( $self->{'_bagPredicateFactory'} || 
				 RDF::Core::NodeFactory->new(BaseURI=> ${ LS::RDF::Constants::BASE_URI },
							     GenCounter=> 1,
							     GenPrefix=> 'http://www.w3.org/1999/02/22-rdf-syntax-ns#_')
				);

	$self->{'_bagPredicateFactory'} = $predicateFactory unless($self->{'_bagPredicateFactory'});

	my $bag = LS::RDF::Bag->new(factory=> 	       $self->{'_factory'},
				    elementFactory=>   $elementFactory,
				    predicateFactory=> $predicateFactory);

	return $bag;

}


#
# addBag( $subject, $predicate, $bag ) -
#
sub addBag {

	my $self = shift;
	my $subject = shift;
	my $predicate = shift;

	my $bag = shift;

	unless(UNIVERSAL::isa($bag, 'LS::RDF::Bag')) {

		# FIXME: Carp
		return undef;
	}

	$self->addTripleResource($subject, $predicate, $bag->bagID());

	foreach my $stmt ( @{ $bag->statements() } ) {

		push @{ $self->{'_statements'} }, $stmt; 
	}
}


package LS::RDF::Bag;

use strict;
use warnings;

use vars qw( @ISA );

@ISA = ( 'LS::RDF::ComplexDocument' );


#
# new( %options ) -
#
sub new {

	my $self = shift;
	my (%options) = @_;

	my $elementFactory;
	unless( ($elementFactory = $options{'elementFactory'}) ) {

		$elementFactory = RDF::Core::NodeFactory->new(BaseURI=> ${ LS::RDF::Constants::BASE_URI },
							      GenPrefix=> '_:element');
	}

	my $predicateFactory;
	unless( ($predicateFactory = $options{'predicateFactory'}) ) {

		$predicateFactory = RDF::Core::NodeFactory->new(BaseURI=> ${ LS::RDF::Constants::BASE_URI },
								GenCounter=> 1,
								GenPrefix=> 'http://www.w3.org/1999/02/22-rdf-syntax-ns#_');
	}

	delete($options{'elementFactory'});
	delete($options{'predicateFactory'});

	my $factory;
	unless( ($factory = $options{'factory'}) ) { 

		$factory = RDF::Core::NodeFactory->new(BaseURI=> ${ LS::RDF::Constants::BASE_URI },
						       GenPrefix=> '_:lsid');
	}

	unless(ref $self eq 'LS::RDF::Bag') {

		my $class = $self->SUPER::new(@_);

		$self = bless $class, $self;


		# Record the node factories
		$self->{'_factory'} = $factory;
		$self->{'_elementFactory'} =   $elementFactory;
		$self->{'_predicateFactory'} = $predicateFactory;

		# The main bag node is a blank node
		$self->{'_bagResource'} = $elementFactory->newResource();
		$self->{'_bagID'} = $self->{'_bagResource'}->getURI();

		# Add the rdf:type to the bag
		$self->_create_statement($self->{'_bagResource'},
					 $self->{'_bagResource'}->new('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
					 $factory->newResource('http://www.w3.org/1999/02/22-rdf-syntax-ns#Bag')
					);
	}


	
	return $self;
}


#
# bagID( ) - Returns the bag's subject ID
#
sub bagID {

	my $self = shift;
	return $self->{'_bagID'};
}


#
# addBlankElement( ) - 
#
sub addBlankElement {

	my $self = shift;

	my $factory = $self->{'_elementFactory'};
	my $predFactory = $self->{'_predicateFactory'};

	my $object = $factory->newResource;

	$self->_create_statement($self->{'_bagResource'},
				 $predFactory->newResource(),
				 $object
				);

	return $object->getURI();
}


#
# addElementResource( $element ) - Adds an element to the bag as a resource 
#
sub addElementResource {

	my $self = shift;
	my $element = shift;

	my $factory = $self->{'_elementFactory'};
	my $predFactory = $self->{'_predicateFactory'};

	$self->_create_statement($self->{'_bagResource'}, 
				 $predFactory->newResource,
				 $factory->newResource($element)
				);
}


#
# addElementLiteral( $element ) -
#
sub addElementLiteral {

	my $self = shift;
	my $element = shift;

	my $factory = $self->{'_elementFactory'};
	my $predFactory = $self->{'_predicateFactory'};

	$self->_create_statement($self->{'_bagResource'},
				 $predFactory->newResource(),
				 $factory->newLiteral($element)
				);
}



1;

__END__


=head1 NAME

LS::RDF::ComplexDocument - An object that allows more complex RDF documents to be created

=head1 SYNOPSIS

 my $rdfDoc = LS::RDF::ComplexDocument->new;

 $rdfDoc->addTripleLiteral($lsid->as_string(), 'http://purl.org/dc/elements/1.1/#title', $approved_gene_name);
 $rdfDoc->addTripleResource($lsid->as_string(), 'urn:lsid:myauthority.org:predicates:external_link', 'urn:lsid:ncbi.nlm.nih.gov.lsid.i3c.org:pubmed:' . lc($pmid1ID));

 print '<?xml version="1.0"?>' . $rdfDoc->output();

=head1 DESCRIPTION

This class provides a simple interface to create RDF documents. 

=head1 METHODS

=over

=item addTripleResource ( $subject, $predicate, $object )

Adds an RDF triple which contains a resource as its object.

=back

=head1 COPYRIGHT

Copyright (c) 2002,2003 IBM Corporation.
All rights reserved.   This program and the accompanying materials
are made available under the terms of the Common Public License v1.0
which accompanies this distribution, and is available at
L<http://www.opensource.org/licenses/cpl.php>

=cut
