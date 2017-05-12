# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================

use strict;
use warnings;

use LS::ID;
use LS::Authority::WSDL::Constants;
use LS::Client::BasicResolver;




my $lsid;		# The LSID to resolve
my $cache_clean = 'no';	# Flag to clean the cache
my $username;		# Username for authentication
my $password;		# Password for authentication


# List of LSIDs to resolve if left unspecified on the command-line
my %LSID = ( 'urn:lsid:gene.ucl.ac.uk.lsid.i3c.org:hugo:MVP'=> undef,
             'urn:lsid:gene.ucl.ac.uk.lsid.i3c.org:hugo:AK5'=> undef,
             'urn:lsid:gene.ucl.ac.uk.lsid.i3c.org:hugo:AKAP7'=> undef,
             'urn:lsid:gene.ucl.ac.uk.lsid.i3c.org:hugo:AP4S1'=> undef,

	     'urn:lsid:ncbi.nlm.nih.gov.lsid.i3c.org:genbank_gi:30350027'=> undef,
	     'urn:lsid:ncbi.nlm.nih.gov.lsid.i3c.org:genbank:bm872070'=> undef,
	     'urn:lsid:ncbi.nlm.nih.gov.lsid.i3c.org:genbank:u34074'=> undef,
	     'urn:lsid:ncbi.nlm.nih.gov.lsid.i3c.org:genbank:l17325.1'=> undef,
	     'urn:lsid:ncbi.nlm.nih.gov.lsid.i3c.org:genbank:x00353'=> undef,
	     'urn:lsid:ncbi.nlm.nih.gov.lsid.i3c.org:genbank:nm_002165'=> undef,
	     'urn:lsid:ncbi.nlm.nih.gov.lsid.i3c.org:genbank_gi:30407099'=> undef,
	     'urn:lsid:ncbi.nlm.nih.gov.lsid.i3c.org:genbank:nm_bad'=> undef,


	     'urn:lsid:ncbi.nlm.nih.gov.lsid.i3c.org:proteins:aah52812'=> undef,
	     'urn:lsid:ncbi.nlm.nih.gov.lsid.i3c.org:proteins_gi:31127313'=> undef,


	     'urn:lsid:ncbi.nlm.nih.gov.lsid.i3c.org:pubmed:12441807'=> undef,


	     #'urn:lsid:ncbi.nlm.nih.gov.lsid.i3c.org:omim:601077'=> ( 'omimuser', 'omimpass' ),
	     #'urn:lsid:ncbi.nlm.nih.gov.lsid.i3c.org:omim:605956'=> ( 'omimuser', 'omimpass' ),
	     #'urn:lsid:ncbi.nlm.nih.gov.lsid.i3c.org:omim:601077-text'=> ( 'omimuser', 'omimpass' ),
	     #'urn:lsid:ncbi.nlm.nih.gov.lsid.i3c.org:omim:606518'=> ( 'omimuser', 'omimpass' ),


	     'urn:lsid:ncbi.nlm.nih.gov.lsid.i3c.org:locuslink:3397'=> undef,
	     'urn:lsid:ncbi.nlm.nih.gov.lsid.i3c.org:predicates:transvar'=> undef,


	     'urn:lsid:ncbi.nlm.nih.gov.lsid.i3c.org:predicates:lsid_xref'=> undef,
	     'urn:lsid:ncbi.nlm.nih.gov.lsid.i3c.org:predicates:locus'=> undef,
	     'urn:lsid:ncbi.nlm.nih.gov.lsid.i3c.org:types:mrna'=> undef,


	     'urn:lsid:ensembl.org.lsid.i3c.org:homosapiens_gene:ensg00000002016'=> undef,
	     'urn:lsid:ensembl.org.lsid.i3c.org:homosapiens_gene:ensg00000002016-fasta'=> undef,
	     'urn:lsid:ensembl.org.lsid.i3c.org:homosapiens_exon:ense00001160197'=> undef,
	     'urn:lsid:ensembl.org.lsid.i3c.org:homosapiens_exon:ense00001160197-fasta'=> undef,
	     'urn:lsid:ensembl.org.lsid.i3c.org:predicates:confidence'=> undef,
	     'urn:lsid:ensembl.org.lsid.i3c.org:predicates:exon'=> undef,
	     'urn:lsid:ensembl.org.lsid.i3c.org:types:gene'=> undef,
	     'urn:lsid:ensembl.org.lsid.i3c.org:homosapiens_ref:12153'=> undef,
	     'urn:lsid:ensembl.org.lsid.i3c.org:homosapiens_analysis:61'=> undef,
	     'urn:lsid:ensembl.org.lsid.i3c.org:homosapiens_translation:18099'=> undef,
	     'urn:lsid:ensembl.org.lsid.i3c.org:homosapiens_transcript:18099'=> undef,
	     'urn:lsid:ensembl.org.lsid.i3c.org:homosapiens_clone:ab015355'=> undef,
	     'urn:lsid:ensembl.org.lsid.i3c.org:homosapiens_clonefragment:24'=> undef,


	     'urn:lsid:genome.ucsc.edu.lsid.i3c.org:hg13:chr2_1-1000'=> undef,
	     'urn:lsid:genome.ucsc.edu.lsid.i3c.org:types:segment'=> undef,
	     'urn:lsid:genome.ucsc.edu.lsid.i3c.org:formats:dasgff'=> undef,
	     'urn:lsid:genome.ucsc.edu.lsid.i3c.org:predicates:type_reference'=> undef,

	   );



&parseArguments;

print "Client settings:\n";
print "Cleaning cache:\n\t$cache_clean\n\n";

print "Username:\n\t$username\n\n" if($username);
print "Password:\n\t$password\n\n" if($password);


if($cache_clean eq 'yes') {

	print "Cleaning the cache, this could take a while.\n\n";
	my $cache = LS::Cache::Manager->new();
	
	$cache->clean_cache(verbose => 1); # Pass 1 for lots of output 0 for none

	# The authority object also has access to a cache manager and a clean_cache method

	print "Cache maintenance finished\n\n";

	exit;
}


if($lsid) {


	# Validate the LSID before proceeding
	unless (ref $lsid eq 'LS::ID' ) {

		print "Invalid LSID: $lsid\n";
		exit;
	}

	print "LSID Given:\n\t$lsid\n\n";
	print "Canonicalized LSID:\n\t" . $lsid->canonical() . "\n\n";

	&resolveLSID($lsid->canonical(), $username, $password);
}
else {

	foreach my $lsid (keys(%LSID)) {

		print "Attempting to resolve LSID:\n\t$lsid\n\n";

		$lsid = LS::ID->new($lsid);

		&resolveLSID($lsid->as_string, $LSID{$lsid->canonical()});

		print "\n\n\n";
	}
}




#
# Subroutines follow
#

sub resolveLSID {

	my ($lsid, $username, $password) = @_;


	#
	# Create a LSID resolver object and then proceed through all the steps
	# necessary to resolve the list of LSIDs
	#

	my $resolver = LS::Client::BasicResolver->new();

	#
	# Retrieve the authority WSDL and a list of ports that 
	# data and metadata can be retreived from
	#

	my $authority = $resolver->resolve(lsid=> $lsid);

	unless($authority) {

		print "The authority could not be located:\n\t";
		return;
	}

	print "The authority is located at:\n\t", $authority->host(), ":", $authority->port(), $authority->path(), "\n\n";

	#
	# Now that the authority has been resolved, get an interface
	# to make calls to it.
	#
	# LS::Client::Basic resolver caches resolved authorities so this call
	# does not execute the resolution process again.
	#
	# If a username and/or password was specified, build a credentials object
	# to send to the authority.
	#
	my $creds;

	if($username || $password) {

		print "Setting authentication information...\n\n";
		$creds = LS::Client::Credentials->new();
		$creds->username($username);
		$creds->password($password);
	}

	my $resource = $resolver->getResource(lsid=> $lsid,
					      credentials=> $creds);

	unless($resource) {

		print "Error getting the resource:\n\tUnknown Error\n\n";
		return;
	}

	#
	# Now display the data and metadata locations that this authority
	# knows about.
	#
	print "For the resource identified by the LSID:\n\n";

	my $locations = $resource->getDataLocations();

	foreach my $svc ( keys(%{ $locations })) {

		print "Service: '$svc', DATA can be retrieved at:\n";
		
		unless($locations->{$svc}) { 

			print "\tNo locations for this service\n\n";
			next;
		}

		foreach my $loc ( @{ $locations->{$svc} }) {

			my $url = $loc->url();

			if($loc->protocol eq $LS::Authority::WSDL::Constants::Protocols::HTTP) {

				$url =~ s#/$##;
				$url .= '?lsid=' . $lsid;
			}
			print "\t(", $loc->protocol(), ') ', $url, "\n";
		}

		print "\n\n";
	}

	my $metadata_locations = $resource->getMetadataLocations();


	foreach my $svc ( keys(%{ $metadata_locations })) {


		print "Service: '$svc', METADATA can be retreived at:\n";

		unless($metadata_locations->{$svc}) {

			print "\tNo locations for this service\n\n";
			next;
		}

		foreach my $loc (@{ $metadata_locations->{$svc} }) {

			my $url = $loc->url();

			if($loc->protocol eq $LS::Authority::WSDL::Constants::Protocols::HTTP) {

                                if($url =~ /\?.*$/) {

                                        $url .= '&lsid=' . $lsid;
                                }
                                else {

                                        $url =~ s#/$##;
                                        $url .= '/?lsid=' . $lsid;
                                }
			}
			print "\t(", $loc->protocol(), ') ', $url, "\n";
		}
		
		print "\n\n";
	}

}

sub quickResolveLSID {

	my ($lsid, $username, $password) = @_;

	#
	# Create a LSID resolver object and then proceed through all the steps
	# necessary to resolve the list of LSIDs
	#

	my $resolver = LS::Client::BasicResolver->new();

	#
	# Create a credentials object only if necessary
	#

	my $creds;

	if($username || $password) {

		$creds = LS::Client::Credentials->new();
		$creds->username($username);
		$creds->password($password);
	}

	print "\n\nRetrieving metadata to store in cache...\n";

	unless($resolver->getMetadata(lsid=> $lsid,
				      credentials=> $creds) ) {

		print "Error retrieving metadata:\n" .  ($resolver->errorString() || 'No detailed error message');
	}
}

sub parseArguments {

	foreach my $arg (@ARGV) {

		if($arg eq '-clean')  {
			$cache_clean = "yes";
		}
		elsif($arg =~ /-username=\"{0,1}(.*)\"{0,1}/) {
			$username = $1;
		}
		elsif($arg =~ /-password=\"{0,1}(.*)\"{0,1}/) {
			$password = $1;
		}
		elsif($arg =~ /^urn:lsid:/i) {

			$lsid = LS::ID->new($arg);
		}
	}
}

__END__
