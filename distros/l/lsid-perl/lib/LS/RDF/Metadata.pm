# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================
package LS::RDF::Metadata;



package LS::RDF::MetadataDocument;

use strict;
use warnings;

use LS::RDF::Constants;
use LS::RDF::ComplexDocument;


use base 'LS::RDF::ComplexDocument';




#
# new( %options ) -
#
sub new {

	my $self = shift;

	my %options = @_;

	unless(ref $self) { 

		unless($options{'lsid'}) {

			unless(UNIVERSAL::isa($options{'lsid'}, 'LS::ID')) {

				$options{'lsid'} = LS::ID->new($options{'lsid'});
			}
	
			return undef unless($options{'lsid'});
		}

		unless($options{'rdf'}) {

			#return undef;
		}

		require RDF::Core::Model;
		require RDF::Core::Model::Parser;
		require RDF::Core::Storage::Memory;
		require RDF::Core::Evaluator;
		require RDF::Core::NodeFactory;
		require RDF::Core::Query;

		$self = bless {

			_lsid=> undef,
			
			_model=> undef,
			_query=> undef,

			_err=> undef,
		}, $self;

		return undef unless( ($self->{'_model'} = RDF::Core::Model->new(Storage=> RDF::Core::Storage::Memory->new())) );

		$self->lsid($options{'lsid'});

		unless($self->parse($options{'rdf'})) {

			#return undef;
		}	
	}

	return $self;
}


#
# lsid( $lsid ) -
#
sub lsid {

	my $self = shift;

	@_ ? $self->{'_lsid'} = shift : return $self->{'_lsid'};
}


#
# parse( $rdf_string ) -
#
sub parse {

	my $self = shift;
	
	my $rdf_string = shift || return;


	my $rdf_model = $self->{'_model'};

	my $parser = RDF::Core::Model::Parser->new(
		Model => $rdf_model,
		Source => $rdf_string,
		SourceType => 'string',
		BaseURI => ${ LS::RDF::Constants::BASE_URI },
	);

	eval { $parser->parse(); };

	if ($@) {
		
		my $err_string = $@;
		$err_string =~ s/^\s+|\s+$//g;

		$self->{'_err'} = $err_string;
		return undef;
	}
	
	my $evaluator = RDF::Core::Evaluator->new(
		Model=> $rdf_model,
		Factory=> RDF::Core::NodeFactory->new,
		Namespaces=> {
			rdf=> 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
			biopathwaysp=> 'urn:lsid:lsid.biopathways.org:predicates:',
			dc=> 'http://purl.org/dc/elements/1.1/#',
		}
	);

	$self->{'_query'} = RDF::Core::Query->new(Evaluator=> $evaluator);
	
	$self->{'_err'} = undef;
}


#
# query( $query_string ) -
#
sub query {

	my $self = shift;
	my ($query_string) = @_;
	
	unless ($self->{'_model'} &&
		$self->{'_query'}) {

		return undef;
	}

	my $rs = $self->{'_query'}->query($query_string);
	
	return $rs;
}


sub statements {

        my $self = shift;

        if($self->SUPER::statements()) {

                return $self->SUPER::statements();
        }
        else {

                return $self->{'_model'}->getStmts();
        }

        return undef;
}


#
# getTypes -
#
sub getTypes {

	my $self = shift;

	my $rs = $self->query('Select ?type from [' . $self->lsid() . ']->rdf:type{?type}') || return;
	
	my @types;

	foreach my $row (@$rs) {
		my $resource = $row->[0] || next;
		
		push(@types, $resource->getURI());
	}

	$self->{'_err'} = undef;

	return \@types;
}


#
# getTitle -
#
sub getTitle {

	my $self = shift;

	my $rs = $self->query('Select ?title from [' . $self->lsid() . ']->dc:title{?title}') || return;

	my $row = $rs->[0] || return;
	my $resource = $row->[0] || return;

	$self->{'_err'} = undef;

	return $resource->getValue();
}


#
# getFormat -
#
sub getFormat {

	my $self = shift;

	my $rs = $self->query('Select ?format from [' . $self->lsid() . ']->dc:format{?format}') || return;

	my $row = $rs->[0] || return;
	my $resource = $row->[0] || return;

	$self->{'_err'} = undef;

	return $resource->getURI();
}


#
# getInstances -
#
sub getInstances {

	my $self = shift;

	my $rs = $self->query('Select ?instance, ?format from [' . $self->lsid() . ']->i3cp:storedas{?instance}->dc:format{?format}') || return;
	
	my @lsids;

	foreach my $row (@$rs) {
		my $resource = $row->[0] || next;
		my $format = $row->[1];
	
		push(@lsids, [$resource->getURI(), $format->getURI()]);
	}

	$self->{'_err'} = undef;
	
	return \@lsids;
}


#
# getAbstract -
#
sub getAbstract {

	my $self = shift;

	my $rs = $self->query('Select ?abstract from ?abstract->i3cp:storedas=>[' . $self->lsid() . ']') || return;

	my $row = $rs->[0] || return;
	my $resource = $row->[0] || return;

	$self->{'_err'} = undef;

	return $resource->getURI();
}


#
# getInstanceFormat -
#
sub getInstancesFormat {

	my $self = shift;
	my ($format) = @_;

	$format = LS::ID->new($format) unless ref $format;
	
	if (!$format) {
		$self->{'_err'} = "Invalid format";
		return;
	}
	
	my $rs = $self->query('Select ?instance from [' . $self->lsid() . "]->i3cp:storedas{?instance}->dc:format=>[" . $format->canonical. "]") || return;
	
	my @lsids;

	foreach my $row (@$rs) {
		my $resource = $row->[0] || next;
		
		push(@lsids, $resource->getURI());
	}

	$self->{'_err'} = undef;
	
	return \@lsids;
}

1;

__END__

=head1 NAME

LS::RDF::MetadataDocument - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTORS

The following method is used to construct a new C<LS::RDF::MetadataDocument> object:

=over

=head1 METHODS

=over

=item get_types ( )

Queries the resource's metadata service for the types of the
resource, and returns the results as a reference to an array of
strings, or C<undef> if an error occurs.  Error messages 
can be checked by calling the C<errorString> method.

Examples:

 $types = $resource->get_types;

 if (defined $types) {
	print "Types:", join(', ', @$types), "\n";
 }
 else {
	print "Error getting types: ", $resource->errorString, "\n";
 }

=item get_format ( )

Queries the resource's metadata service for the format of the
resource, and returns the result as an LSID string, or C<undef>
if an error occurs.  A resource will have a format if its
type is urn:lsid:i3c.org:types:content.  Error messages 
can be checked by calling the C<errorString> method.

Examples:

 $format = $resource->get_format;

 if (defined $format) {
	print "Format: $format\n";
 }
 else {
	print "Error getting format: ", $resource->errorString, "\n";
 }


=item get_instances ( )

Queries the resource's metadata service for the concrete
instances of the resource.  The return value is a reference
to an array, or C<undef> if an error occurs.  Each element of
the array is a reference to a two-element array.  The first element
is an LSID string identifying the concrete instance.  The second
element is an LSID string identifying the format of the concrete
instance.  A resource of type urn:lsid:i3c.org:types:content will
have no concrete instances.  Error messages can be checked by 
calling the C<errorString> method.

Examples:

 $instances = $resource->get_instances;

 if ($instances) {
	print "Instances:\n";

	foreach $resource (@$instances) {
		$lsid = $resource->[0];
		$format = $resource->[1];

		print "\t$lsid\n";
	}
 }
 else {
	print "Error getting instances: ", $resource->errorString, "\n";
 }


=item get_instances_in_format ( $format )

Queries the resource's metadata service for the concrete
instances of the resource in the specified format.  C<$format>
is the LSID which identifies the format, and may either be
a string or an object of class C<LS::ID>.  The return value 
is a reference to an array of LSID strings, or C<undef> if an error
occurs.  A resource of type urn:lsid:i3c.org:types:content will
have no concrete instances.  Error messages can be checked by calling 
the C<errorString> method.

Examples:

 $instances = $resource->get_instances_in_format('URN:LSID:i3c.org:formats:jpg:');

 if ($instances) {
	print "Instances:\n";

	foreach $lsid (@$instances) {
		print "\t$lsid\n";
	}
 }
 else {
	print "Error getting jpg instances: ", $resource->errorString, "\n";
 }


=item get_abstract ( )

Queries the resource's metadata service for the abstract resource
of this resource.  A resource of type urn:lsid:i3c.org:types:content will
have an abstract resource.  The return value is an LSID string, or C<undef>
if an error occurs.  Error messages can be checked by calling the 
C<errorString> method.

Examples:

 $abstract = $resource->get_abstract;

 if ($abstract) {
	print "Abstract: $abstract\n";
 }
 else {
	print "Error getting abstract: ", $resource->errorString, "\n";
 }


=item data_locations ( )

Deprecated. Use get_data_locations instead.

=item data_location ( $protocol, [ $method ] )

Deprecated. Use get_data_location instead.

=back

=head1 COPYRIGHT

Copyright (c) 2002,2003 IBM Corporation.
All rights reserved.   This program and the accompanying materials
are made available under the terms of the Common Public License v1.0
which accompanies this distribution, and is available at
L<http://www.opensource.org/licenses/cpl.php>

=cut
