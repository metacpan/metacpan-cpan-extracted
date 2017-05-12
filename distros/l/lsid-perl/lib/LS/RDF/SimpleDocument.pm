# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================
package LS::RDF::Simple;


package LS::RDF::SimpleDocument;

use strict;
use warnings;

use LS;
use LS::RDF::Constants;

use base 'LS::Base';



#
# new( %options ) -
#
sub new { 

	my $self = shift;

	require RDF::Core::Model;
	require RDF::Core::Model::Serializer;

	require RDF::Core::Storage::Memory;
	require RDF::Core::Serializer;
	require RDF::Core::NodeFactory;
	require RDF::Core::Resource;
	require RDF::Core::Statement;

	unless (ref $self) {
		
		$self = bless {
			
			_factory=> RDF::Core::NodeFactory->new(BaseURI=> $LS::RDF::Constants::BASE_URI,
							       GenPrefix=> '_:lsid'),
			_statements=> [],

		}, $self;
	}
	
	return $self;
}


#
# addTripleLiteral( $subject, $predicate, $object ) -
#
sub addTripleLiteral {
	
	my $self = shift;
	
	my ($_sub, $_pred, $_obj) = @_;
	
	my $subject = $self->{'_factory'}->newResource($_sub);
	my $predicate = $subject->new($_pred);
	my $object = $self->{'_factory'}->newLiteral($_obj);
	
	$self->_create_statement($subject, $predicate, $object);
}


#
# add_triple_resource - Synonym for addTripleLiteral
#
sub add_triple_literal {

	my $self = shift;
	return $self->addTripleLiteral(@_);
}


#
# addTripleResource( $subject, $predicate, $object ) -
#
sub addTripleResource {
	
	my $self = shift;
	
	my ($_sub, $_pred, $_obj) = @_;
	
	my $subject = $self->{_factory}->newResource($_sub);
	my $predicate = $subject->new($_pred);
	my $object = $self->{'_factory'}->newResource($_obj);
	
	$self->_create_statement($subject, $predicate, $object);

	return $object;
}


#
# add_triple_resource - Synonym for addTripleResource.
#
sub add_triple_resource {

	my $self = shift;
	return $self->addTripleResource(@_);
}


#
# statements( ) - Returns the arrayref of statements
#
sub statements {

	my $self = shift;
	return $self->{'_statements'};
}


#
# output( ) -
#
sub output {

	my $self = shift;

	my $storage =  RDF::Core::Storage::Memory->new();
	my $model =  RDF::Core::Model->new(Storage=> $storage);

	foreach(@{ $self->{'_statements'} }) {

		$model->addStmt($_);
	}

	my $xml = '';
	
	my $serializer = RDF::Core::Model::Serializer->new(
			Model=> $model,
			Output=> \$xml,
			BaseURI=> ''
		);

	$serializer->serialize();

	return $xml;
}


#
# _create_statement( $subject, $predicate, $object ) - 
#
sub _create_statement {
	
	my $self = shift;
	
	my ($subject, $predicate, $object) = @_;
	my $statement = RDF::Core::Statement->new($subject, $predicate, $object);
		
	push(@{ $self->{'_statements'} }, $statement);
}


1;

__END__


=head1 NAME

LS::RDF::SimpleDocument - Simple RDF Document object

=head1 SYNOPSIS

 my $rdfDoc = LS::RDF::SimpleDocument->new();

 $rdfDoc->addTripleLiteral($lsid->as_string(), 
 			   'http://purl.org/dc/elements/1.1/#title', 
 			   $approved_gene_name);

 $rdfDoc->addTripleResource($lsid->as_string(), 
 			    'urn:lsid:myauthority.org:predicates:external_link', 
			    'urn:lsid:ncbi.nlm.nih.gov.lsid.i3c.org:pubmed:' . lc($pmid1ID));

 print '<?xml version="1.0"?>' . "\n" . $rdfDoc->output();

=head1 DESCRIPTION

This class provides a simple interface to create RDF documents. 

=head1 METHODS

=over

=item addTripleResource ( $subject, $predicate, $object )

Adds an RDF triple which contains a resource as its object.

=item addTripleLiteral ( $subject, $predicate, $object )

Adds an RDF triple which contains a literal as its object.

=item output ( )

Returns the RDF represented by this object as text.

=back

=head1 COPYRIGHT

Copyright (c) 2002,2003 IBM Corporation.
All rights reserved.   This program and the accompanying materials
are made available under the terms of the Common Public License v1.0
which accompanies this distribution, and is available at
L<http://www.opensource.org/licenses/cpl.php>

=cut
