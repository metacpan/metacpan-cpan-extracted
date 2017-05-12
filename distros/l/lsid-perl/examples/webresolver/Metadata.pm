# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation
# All rights reserved.  This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
#
# =====================================================================
package Metadata;

use strict;
use warnings;

use vars qw( $ARROW_IMG );

use LS::ID;
use LS::Authority;
use LS::Resource;

use LS::RDF::Metadata;

use LS::Client::BasicResolver;

require WebResolver;

$ARROW_IMG = '/webresolver/images/arrow.gif';


#
# resolveLSID( $lsid ) -
#
sub resolveLSID {

	my $lsid = shift;

	unless($lsid) {

	}

	my $client;
	unless( ($client = LS::Client::BasicResolver->new()) ) {

	}

	my $resource;
	unless( ($resource = $client->getResource(lsid=> $lsid)) ) {

	}

	return $resource;
}


#
# getUniqueMetadata( .. ) -
#
sub getUniqueMetadata {

	my %options = @_;

	my $resource;

	$resource = &resolveLSID($options{'lsid'}) if($options{'lsid'});

	if ($resource || ( $resource = $options{'resource'}) ) {

		my $metadataLocations = [];
		foreach my $service (keys(%{ $resource->getMetadataLocations() })) {

			push @{ $metadataLocations }, $resource->get_metadata_location(serviceName=> $service)->[0];
		}

		return $metadataLocations;
	}
	else {

		# Error
	}

	return undef;
}


#
# renderMetadata( ) -
#
sub renderMetadata {

	my (%options) = @_;

	my $lsid = $options{'lsid'};
	my $metadata = $options{'metadata'};

	unless($metadata) {

		return undef;
	}

	unless($lsid) {

		return undef;
	}

	my $rdfDoc = LS::RDF::MetadataDocument->new(lsid=> $lsid);

	$rdfDoc->parse( $metadata );

	my $renderHash = {};

	my ($firstLevel, $rest) = &Metadata::getFirstLevel( $rdfDoc, $lsid );

	&Metadata::buildRenderHash($firstLevel, $rest, $renderHash);

	my $html;

	#$html = "<div class='base-container'>\n";
	#$html .= "<div class='base-layer'>\n";

	$html .= &Metadata::createHTML( $renderHash, 1 );

	#$html .= "</div> <!-- BASE-LAYER -->\n";
	#$html .= "</div> <!-- BASE-CONTAINER TABLE END -->\n";

	#$html = '<div class="outerRender">' . $html . '</div>';
	#$html = "<span class='mainTitle'>$lsid</span>\n$html";

	return $html;
}


#
# createHTML( $renderHash ) -
#
sub createHTML {

	my $renderHash = shift;
	my $indentLevel  = shift;

	my $html;

	my $padding = $indentLevel * 8;

	my $customSortFn = sub {

		if(ref $renderHash->{ $a } eq 'HASH' &&
		   ref $renderHash->{ $b } eq 'HASH') {

			return $a cmp $b;
		}
		elsif(ref $renderHash->{ $a } eq 'HASH') {
		      
			return 1;
		}
		elsif(ref $renderHash->{ $b } eq 'HASH') {

			return -1;
		}
		else {

			return $a cmp $b;
		}
	};

	$html = "\n<table width='400px' border='0' cellpadding='0' cellspacing='0'>\n";
	#$html .= "<div class='base-container'>\n";
	#$html .= "<div class='base-layer'>\n";
	foreach my $key (sort($customSortFn keys(%{ $renderHash }))) {

		#$html .= "<div class='table-row'>\n";
		$html .= "<tr>\n";
		if(ref $renderHash->{ $key } eq 'HASH') {

			# Begin inner table
			my $newPadding = $padding + 8;

			unless($key =~ /^_\d+/) {

				# Make a caption for named edges (not blank nodes)
				#$html .= "<div class='left-layer11'><p class='keyTitle'>$key</p></div>\n";
				$html .= "<td><p class='keyTitle'>$key</p></td><td> &nbsp; </td>\n";
			}

			$html .= "</tr><tr>";

			# The column for this item is a new table
			#$html .= "<div class='left-layer11' style='padding-left: ${newPadding}px;'>\n";
			$html .= "<td colspan='3' style='padding-left: ${newPadding}px;'>\n";
			$html .= &Metadata::createHTML( $renderHash->{ $key }, $indentLevel++ );
			$html .= "</td></tr><tr><td colspan='10'> &nbsp; </td></tr>\n";
			#$html .= "</div>\n";
		}
		else {

			# A standard row, no inner table
			my $IMAGE = '<img src="' . $ARROW_IMG . '" alt="Arrow" />';

			#$html .= '<div class="left-layer11"><p class="item">'. $key . "</p></div>\n";
			$html .= '<td><p class="">'. $key . "</td>\n";

			if($key eq 'lsidLink') {

				#$html .= "<div class='left-layer11'><p class='item'>$IMAGE</p></div>\n";
				#$html .= "<div class='left-layer11'><p class='item'>";
				$html .= "<td><p class=''>$IMAGE</td>\n";
				$html .= "<td><p class=''>";
				foreach my $item (@{ $renderHash->{ $key } }) {

					$html .= '<a href="' . $WebResolver::BASE_URL . $item . '">' . "$item</a>\n";
				}
				#$html .= "</p></div>\n";
				$html .= "</p></td>\n";
			}
			else {

				#$html .= "<div class='left-layer11'><p class='item'>$IMAGE</p></div>\n";
				#$html .= "<div class='left-layer11'><p class='item'>";
				$html .= "<td class='left-layer11'><p class=''>$IMAGE</p></td>\n";
				$html .= "<td class='left-layer11'><p class=''>";
				foreach my $item (@{ $renderHash->{ $key } }) {

					if($item =~ /^urn:lsid:/) {

						$html .= "<a href='$WebResolver::BASE_URL$item'> $item </a> <br/>\n";
					}
					else {

						$html .= "$item<br/>\n";
					}
				}
				#$html .= "</p></div>\n"
				$html .= "</p></td>\n"
			}
		} # end row

		#$html .= "<div class='space-line'></div>\n";
		$html .= "</tr> <!-- END ROW -->\n\n\n";
	}

	$html .= "</table>\n";
	#$html .= "</div> <!-- BASE-LAYER -->\n";
	#$html .= "</div> <!-- BASE-CONTAINER TABLE END -->\n";

	return $html;
}


#
# getFirstLevel( $rdfDocument, $subject ) -
#
sub getFirstLevel {

	my $rdfDoc = shift;
	my $lsid = shift;

	my $statement;
	my $firstLevel = [];
	my $rest = [];

	my $enumerator = $rdfDoc->statements();

	$statement = $enumerator->getFirst();
	while( $statement ) {

		my $subject = $statement->getSubject();
		if($subject->getURI() eq $lsid) {

			push @{ $firstLevel }, $statement;
		}
		else {

			push @{ $rest }, $statement;
		}

		$statement = $enumerator->getNext();
	}

	return ($firstLevel, $rest);
}


#
# buildRenderHash( ) -
#
sub buildRenderHash {

	my $statementList = shift;
	my $rest = shift;
	my $renderHash = shift;

	foreach my $stmt (@{ $statementList }) {

		if(UNIVERSAL::isa($stmt->getObject(), 'RDF::Core::Literal')) {

			if($renderHash->{ $stmt->getPredicate()->getLocalValue() }) {

				push @{ $renderHash->{ $stmt->getPredicate()->getLocalValue() } },
				     $stmt->getObject()->getValue();
			}
			else {

				$renderHash->{ $stmt->getPredicate()->getLocalValue() } = [];
				push @{ $renderHash->{ $stmt->getPredicate()->getLocalValue() } },
				     $stmt->getObject()->getValue();
			}
		}
		else {


			my ($firstLevel, $newRest) = &Metadata::findRDFSubject( $rest, $stmt->getObject()->getURI() );

			if(scalar(@{ $firstLevel })) {

				$renderHash->{ $stmt->getPredicate()->getLocalValue() } = {};

				&Metadata::buildRenderHash( $firstLevel, 
							    $newRest, 
							    $renderHash->{ $stmt->getPredicate()->getLocalValue() } 
							);
			}
			else {

				if($renderHash->{ $stmt->getPredicate()->getLocalValue() } ) {

					push @{ $renderHash->{ $stmt->getPredicate()->getLocalValue() } },
					     $stmt->getObject()->getURI();
				}
				else {

					$renderHash->{ $stmt->getPredicate()->getLocalValue() } = [];

					push @{ $renderHash->{ $stmt->getPredicate()->getLocalValue() } },
					     $stmt->getObject()->getURI();
				}
			}
		}
	}
}


#
# findRDFSubject( ) -
#
sub findRDFSubject {

	my $statementList = shift;
	my $subject = shift;

	my $subjectList = [];
	my $rest = [];

	foreach my $statement (@{ $statementList }) {

		if($statement->getSubject()->getURI() eq $subject) {

			push @{ $subjectList }, $statement;
		}
		else {

			push @{ $rest }, $statement;
		}
	}

	return ($subjectList, $rest);
}

1;

__END__

