#!/usr/bin/perl
# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================

package hugo;

use strict;
use warnings;

use DBI;

use LS::ID;

use LS::Service::Response;
use LS::Service::Fault;

use LS::RDF::SimpleDocument;

use base 'LS::Service::Namespace';

sub new {

	my ($self, %options) = @_;

	$options{'name'} = 'hugo';

	return $self->SUPER::new(%options);
}

sub getMetadata {

	my ($self, $lsid, $format) = @_;

	my $DBNAME = 'hugo';
	my $DBUSER = 'username';
	my $DBPASS = 'password';

	$lsid = $lsid->canonical();

	my $id = $lsid->object();
	$id .= ':' . $lsid->revision()
		if($lsid->revision());
	
	my $dbh = DBI->connect("dbi:mysql:$DBNAME", $DBUSER, $DBPASS);
	
	return LS::Service::Fault->serverFault('Can not access database', 500)
		unless($dbh);	
		
	# Create a new RDF Document to add triples
	my $lookup;	
	my $rdfDoc = LS::RDF::SimpleDocument->new();

	return LS::Service::Fault->serverFault('Internal error, unable to initialize RDF document', 500) 
		unless($rdfDoc);

	# Deal with the various meta-data items
	$lookup = $dbh->prepare(
		'SELECT status,approved_gene_name,location,seq_accessionID,' .
		'prev_gene_name,hgncID,Ref_Seq ' .
		'FROM hugo WHERE approved_gene_symbol=?'
	);

	if($lookup) {

		my $rs = $lookup->execute($id);
		
		return LS::Service::Fault->fault('Unknown LSID')
			unless($rs);

		my ($status, $approved_gene_name, $location, $seq_accessionID,
			$prev_gene_name, $hgncID, $RefSeq, $aliases 
		   ) = $lookup->fetchrow_array();

		$rdfDoc->addTripleLiteral($lsid->as_string(), 
					  'http://purl.org/dc/elements/1.1/#title', 
					  $approved_gene_name) 
			if ($approved_gene_name);

		$rdfDoc->addTripleLiteral($lsid->as_string(), 
					  'urn:lsid:gene.ucl.ac.uk.lsid.biopathways.org:predicates:location', 
					  $location) 
			if($location);

		#$rdfDoc->addTripleLiteral($lsid->as_string(), 
		#			   'urn:lsid:gene.ucl.ac.uk.lsid.biopathways.org:predicates:seq_accessionid', 
		#			   $seq_accessionID) 
		#	if($seq_accessionID);

		$rdfDoc->addTripleLiteral($lsid->as_string(), 
					  'urn:lsid:gene.ucl.ac.uk.lsid.biopathways.org:predicates:status', 
					  $status) 
			if($status);

		$rdfDoc->addTripleLiteral($lsid->as_string(), 
					  'urn:lsid:gene.ucl.ac.uk.lsid.biopathways.org:predicates:prev_gene_name', 
					  $prev_gene_name) 
			if($prev_gene_name);

		#$rdfDoc->addTripleLiteral($lsid->as_string(), 
		#			   'urn:lsid:gene.ucl.ac.uk.lsid.biopathways.org:predicates:hgncid', 
		#			   $hgncID) 
		#	if($hgncID);

		#$rdfDoc->addTripleLiteral($lsid->as_string(), 
		#			   'urn:lsid:gene.ucl.ac.uk.lsid.biopathways.org:predicates:refseq', 
		#			   $RefSeq) 
		#	if($RefSeq);

		$rdfDoc->addTripleLiteral($lsid->as_string(), 
					  'urn:lsid:gene.ucl.ac.uk.lsid.biopathways.org:predicates:aliases', 
					  $aliases) 
			if($aliases);
	}

	$lookup->finish();
	
	# Deal with the links to other authorities
	$lookup = $dbh->prepare(
		'SELECT LocusLinkID, gdbID, OMIM, SwissProtID, pmid1, pmid2 ' .
		'FROM hugo WHERE approved_gene_symbol=?'
	);
	
	if ($lookup) {

		my $rs = $lookup->execute($id);
		last unless ($rs); # This may not return any records

		my ( $locusID, $gdbID, $omimID, $swissID, $pmid1ID, $pmid2ID ) =
			$lookup->fetchrow_array();
		
		$rdfDoc->addTripleResource($lsid->as_string(), 
					   'urn:lsid:gene.ucl.ac.uk.lsid.biopathways.org:predicates:external_link', 
					   'urn:lsid:ncbi.nlm.nih.gov.lsid.biopathways.org:locuslink:' . lc($locusID))
			if($locusID);
				
		#$rdfDoc->addTripleResource($lsid->as_string(), 
		#			    'urn:lsid:gene.ucl.ac.uk.lsid.biopathways.org:predicates:external_link', 'GDB:'. lc($gdbID))
		#	if($gdbID);

		$rdfDoc->addTripleResource($lsid->as_string(), 
					   'urn:lsid:gene.ucl.ac.uk.lsid.biopathways.org:predicates:external_link', 
					   'urn:lsid:ncbi.nlm.nih.gov.lsid.biopathways.org:omim:' . lc($omimID))
			if($omimID);

		$rdfDoc->addTripleResource($lsid->as_string(), 
					   'urn:lsid:gene.ucl.ac.uk.lsid.biopathways.org:predicates:external_link', 
					   'urn:lsid:ebi.ac.uk.lsid.biopathways.org:swissprot-proteins:'  . lc($swissID))
			if($swissID);

		$rdfDoc->addTripleResource($lsid->as_string(), 
					   'urn:lsid:gene.ucl.ac.uk.lsid.biopathways.org:predicates:external_link', 
					   'urn:lsid:ncbi.nlm.nih.gov.lsid.biopathways.org:pubmed:' . lc($pmid1ID))
			if($pmid1ID);
				
		$rdfDoc->addTripleResource($lsid->as_string(), 
					   'urn:lsid:gene.ucl.ac.uk.lsid.biopathways.org:predicates:external_link', 
					   'urn:lsid:ncbi.nlm.nih.gov.lsid.biopathways.org:pubmed:' . lc($pmid2ID))
			if($pmid2ID);
	}
	
	$format = 'application/xml' if(!$format);
	return LS::Service::Response->new(response=> '<?xml version="1.0"?>' . $rdfDoc->output(),
					  format=> $format);
}



package predicates;

use strict;
use warnings;

use LS::ID;

use LS::Service::Response;
use LS::Service::Fault;

use LS::RDF::SimpleDocument;

use base 'LS::Service::Namespace';

sub new {

	my ($self, %options) = @_;

	$options{'name'} = 'predicates';

	return $self->SUPER::new(%options);
}

sub getMetadata {

	my ($self, $lsid, $format) = @_;

	$lsid = $lsid->canonical();
	
	my $id = $lsid->object();
	$id .= ':' . $lsid->revision() 
		if($lsid->revision());
		
	my $PREDICATE_ROOT = 'predicates';
	
	return LS::Service::Fault->fault('Unknown LSID') unless(-e "$PREDICATE_ROOT/$id.metadata");
	return LS::Service::Fault->serverFault('Unable to load metadata', 600) 
		unless(open(PREDICATE_FILE, "$PREDICATE_ROOT/$id.metadata"));
	
	my $data = do { local $/; <PREDICATE_FILE> };
	
	close(PREDICATE_FILE);
	
	$format = 'application/xml' if(!$format);
	return LS::Service::Response->new(response=> $data,
					  format=> $format);
}

1;
