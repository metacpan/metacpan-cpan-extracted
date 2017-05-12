# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation
# All rights reserved.  This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
#
# =====================================================================

package WebResolver;

use strict;
use warnings;

use vars qw( $BASE_URL $TITLE @EXAMPLES );

use base 'CGI::Application';

use CGI;
use CGI::Session;


use LS::ID;
use LS::Authority;
use LS::Resource;
use LS::RDF::Metadata;

use LS::Client::BasicResolver;

require Metadata;



$TITLE = 'Web Resolver';

$BASE_URL = '/resolver/';

@EXAMPLES = (
                'urn:lsid:gdb.org:GenomicSegment:GDB132938',
                'urn:lsid:gene.ucl.ac.uk.lsid.biopathways.org:hugo:MVP',
                'urn:lsid:ncbi.nlm.nih.gov.lsid.biopathways.org:pubmed:12441807',
                'urn:lsid:ncbi.nlm.nih.gov.lsid.biopathways.org:genbank_gi:30350027',
        );




sub setup {

        my $self = shift;

        $self->run_modes(
                'start'=> 'start',
		'summary'=> 'summary',
		'rawMetadata'=> 'rawMetadata',
		);

	$self->tmpl_path('templates');

        $self->start_mode('start');
        $self->mode_param('rm');
}


sub cgiapp_init {

	my $self = shift;

	$self->session();
}


sub cgiapp_prerun {

	my $self = shift;

	my $query = $self->query();
	my $session = $self->param('session');

	my $lsid;

	if($query->url_param('summary') && 
	   $query->url_param('summary') eq '1' &&
	   ($lsid = $query->url_param('lsid')) ) {

		$self->prerun_mode('summary');
		$session->param('lsid'=> $lsid);
	}
	elsif($query->url_param('image') &&
	      $query->url_param('image') eq '1' &&
	      ($lsid = $query->url_param('lsid')) ) {
		
		$self->prerun_mode('summary');
		
		$self->param('image'=> 1);
		$session->param('lsid'=> $lsid);
	}
	elsif($query->url_param('raw') &&
	      $query->url_param('raw') eq '1' &&
	      ($lsid = $query->url_param('lsid')) ) {
	      	
	      	$self->prerun_mode('rawMetadata');
	      	
	      	$session->param('lsid'=> $lsid);
	}
	elsif($query->url_param('data') &&
	      $query->url_param('data') eq '1' &&
	      ($lsid = $query->url_param('lsid')) ) {
	      	
	      	$self->prerun_mode('rawData');
	      	
	      	$session->param('lsid'=> $lsid);
	}
	else {

	}
}


sub session {

	my $self = shift;

	my $query = $self->query();

	my $session = CGI::Session->new('driver:File',
					($query->cookie('LSIDWebResolver') || $query->param('LSIDWebResolver') || undef),
					{
						Directory=> '/var/tmp/'
					}
				) or die($CGI::Session::errstr);

	my $sess_id = $session->id();

	$self->param('sessionid'=> $sess_id);
	$self->param('session'=> $session);

	if(!$sess_id || $query->cookie('LSIDWebResolver') ne $sess_id) {

		$self->header_props(-cookie=> $query->cookie(-name=> 'LSIDWebResolver',
							     -value=> $sess_id,
							     -path=> '/')
				);
	}
}

#
# General subroutines
#

sub my_header {

	my $self = shift;

	my $query = $self->query();

	my $template = $self->load_tmpl('header.html.template');

	my $header;

	$header = $query->start_html(-title=> $TITLE,
				     -style=> {
						'src'=> 'style.css',
					      },
				    );

	$header .= $template->output();

	return $header;
}

sub my_footer {

	my $self = shift;

	my $query = $self->query();

	my $template = $self->load_tmpl('footer.html.template');

	my $footer;

	$footer = $template->output();
	$footer .= $query->end_html();

	return $footer;
}

#
# Run modes follow
#

sub start {

	my $self = shift;

	my $query = $self->query();
	my $session = $self->param('session');



	# Page initialization
	my $template = $self->load_tmpl('start.html.template',
					die_on_bad_params=> 0,
				       );

	my $output = $self->my_header();

	my $FORM_NAME = 'webresolver';

	$output .= $query->start_form(-id=> $FORM_NAME,
					);

	$output .= '<p><input type="hidden" name="rm" value="summary" /></p>' . "\n";




	# Form elements
	my %elements;

	$elements{'lsid'} = $query->textfield(-name=> 'lsid',
					      -default=> '',
					      -size=> 65,
					      -maxlength=> 255) . "\n";

	$elements{'submit'} = $query->submit(-name=> 'GO',
					     -value=> 'Go',
					     -onClick=> "document.$FORM_NAME.action = '$BASE_URL' + " .
							"document.$FORM_NAME.lsid.value",
					    ) . "\n";

        my $i = 0;
        my $examples = [];

        while($i < scalar(@EXAMPLES)) {

		# Just in case
		if(0) {

	                my $textfield = $query->textfield(-name=> "text$i",
	                                                  -value=> $EXAMPLES[$i],
	                                                  -size=> 65,
							  -readonly=> 1,
	                                                 ) . "\n";
	
	                my $button = $query->button(-name=> "GO$i",
	                                            -value=> "GO",
	                                            -onClick=> "copyValue($FORM_NAME, 'text$i'); " . 
							       "document.$FORM_NAME.action = '$BASE_URL' + " . 
							       "document.$FORM_NAME.lsid.value; document.$FORM_NAME.submit();"
						) . "\n";
	
			push @{ $examples }, { 'text'=> $textfield, 'button'=> $button };
	
		}
		elsif(0) {

			my $link = "<a href='$BASE_URL$EXAMPLES[$i]'>$EXAMPLES[$i]</a>";

			push @{ $examples }, { 'text'=> $link, 'button'=> '' };
		}
		else {

			my $link = "<a href='$BASE_URL$EXAMPLES[$i]'>http://$ENV{HTTP_HOST}$BASE_URL$EXAMPLES[$i]</a>";

			push @{ $examples }, { 'text'=> $link, 'button'=> '' };
		}

                $i++;
        }

	$elements{'examples'} = $examples;

	# HTML::Template variables

	foreach my $name (keys(%elements)) {

		$template->param("$name"=> $elements{$name});
	}


	# Page completion

	$output .= $template->output();
	$output .= $query->endform();
	$output .= $self->my_footer();

	return $output;
}


sub summary {

	my $self = shift;

	my $query = $self->query();
	my $session = $self->param('session');


	my $lsid;
	unless( ($lsid = $self->validateLSID($query->param('lsid'))) ) {

		# TODO: Error message
		return $self->start();
	}

	# Save all the data to the session
	$session->save_param( $query ) if($query->param());
	$session->load_param( $query );


	my $authorityDetails;
	unless( ($authorityDetails = $self->getAuthorityDetails( $lsid )) ) {

		# TODO: Error message
		return $self->start();
	}

	# Data retreived from the LSID
	foreach my $key (keys(%{ $authorityDetails }) ) {

		$session->param($key=> $authorityDetails->{ $key });
	}

	# Page initialization
	my $template = $self->load_tmpl('summary.html.template', 
					die_on_bad_params=> 0,
				       );

	my $output = $self->my_header();

	my $FORM_NAME = 'summary';

	$output .= $query->start_form(-id=> $FORM_NAME);
	$output .= '<p><input type="hidden" name="rm" value="summary" />' . "\n";

	$output .= "<input type=\"hidden\" name=\"lsid\" value=\"$lsid\" />\n";
	$output .= "<input type=\"hidden\" name=\"image\" value=\"0\" /></p>\n";


	# Form elements
	my %elements;

	my $numData;
	my $numMetadata;


	# Copy the data about the authority to the form element hash
	# so that we can display these items on the page.
	foreach my $key (keys(%{ $authorityDetails })) {

		$elements{ $key } = $authorityDetails->{ $key };
	}

	$numData = $elements{'numData'};
	$numMetadata = $elements{'numMetadata'};

	$elements{'lsid'} = $lsid;

	# Default to no data available
	$elements{'dataAvailable'} = 0;
	$elements{'saveAs'} = $query->button(-name=> 'saveas',
					     -value=> 'Save As...',
					     -disabled,
					   ) . "\n";

	# If there is data, create a 'Save As' button
	if($numData > 0) {

		$elements{'dataAvailable'} = 1;

		# Get the first data location
                my $dataLocation = $authorityDetails->{'dataDetails'}->[0]->{'locations'}->[0]->{ 'link' };

                $elements{'saveAs'} = $query->button(-name=> 'saveas',
                                                     -value=> 'Save As...',
						     -onClick=> "document.location.href='$dataLocation';",
                                                   ) . "\n";

	}

	# No metadata by default
	$elements{'metadataAvailable'} = 0;
	$elements{'metadataSaveAs'} = $query->button(-name=> 'metadatasaveas',
                                                     -value=> 'Save As...',
                                                     -disabled,
                                                   ) . "\n";

	# Figure out what kind of metadata to display: an image or rendered HTML (the default)
	my $metadataFunctionType = 'getMetadata';
	$metadataFunctionType = 'getMetadataAsImage' if( ($query->param('metadataImage') && 
							  $query->param('metadataImage') eq '1') || $self->param('image'));

	# Fetch the metadata if there is metadata for this LSID
	if($numMetadata > 0) {

		my $metadataRef = $self->$metadataFunctionType( $lsid );

		if($metadataRef) {

			$elements{'metadataAvailable'} = 1;

			my $metadataLocation = $authorityDetails->{'metadataDetails'}->[0]->{'locations'}->[0]->{ 'link' };

			$elements{'metadata'} = ${ $metadataRef };
			$elements{'metadataSaveAs'} = $query->button(-name=> 'metadatasaveas',
								     -value=> 'Save As...',
								     -onClick=> "document.location.href='$metadataLocation';",
								   ) . "\n";
		}
	}

	$session->param('lsidDetails'=> [ %elements ] );

	# HTML::Template variables
	foreach my $name (keys(%elements)) {

		$template->param("$name"=> $elements{$name});
	}


	# Page completion
	$output .= $template->output();
	$output .= $query->endform();
	$output .= $self->my_footer();

	return $output;
}


sub rawMetadata {
	
	my $self = shift;

	my $query = $self->query();
	my $session = $self->param('session');


	my $lsid;
	unless( ($lsid = $self->validateLSID($query->param('lsid'))) ) {

		# TODO: Error message
		return $self->start();
	}

	# Fetch the metadata if there is metadata for this LSID
	# Resolve the LSID
	my $resource;
	unless( ($resource = &Metadata::resolveLSID($lsid)) ) {

		# TODO: Error message
		return $self->start();
	}
	
	# Just write the RAW metadata to the client
	my $output;
	
	my $metadataResponse = $resource->getMetadata();
	unless($metadataResponse) {
		
		return undef;
	}
	
        # This is a RAW XML page .. no HTML content
        $self->header_props(-type=>'application/xml');
	
	my $metadataHandle = $metadataResponse->response();	
	while(<$metadataHandle>) {
		
		$output .= "$_\n";
	} 
	
	return $output;
}


sub rawData {

        my $self = shift;

        my $query = $self->query();
        my $session = $self->param('session');


        my $lsid;
        unless( ($lsid = $self->validateLSID($query->param('lsid'))) ) {

                # TODO: Error message
                return $self->start();
        }

        my $resource;
        unless( ($resource = &Metadata::resolveLSID($lsid)) ) {

                # TODO: Error message
                return $self->start();
        }

        my $dataResponse = $resource->getData();
        unless($dataResponse) {

                # TODO: Error message
                return $self->start();
        }

        my $url = 'http://lsid.biopathways.org/authority/data/?lsid=' . $lsid;
        $self->header_type('redirect');
        $self->header_props(-url=>$url);

        return '';
}



#
# getAuthorityDetails( $lsid ) -
#
sub getAuthorityDetails {

	my $self = shift;

	my $lsid = shift;

	my %elements;

	# Resolve the LSID
	my $resource;
	return undef unless( ($resource = &Metadata::resolveLSID($lsid)) );

	#
	# Build the authority's full hostname
	#
	my $authority = $resource->authority();
	my $authorityEndpoint = 'http://' . $authority->host() . ':' . $authority->port();

	if($authority->path() =~ /^\//) { 

		$authorityEndpoint .= $authority->path();
	}
	else {

		$authorityEndpoint .= '/' . $authority->path();
	}

	$elements{'authority'} = $authorityEndpoint;



	# Form elements

	my $numData = 0;
	my $numMetadata = 0;

	my $dataDetails = [];
	my $metadataDetails = [];


	# Build a list of HTTP Data ports
	foreach my $service (keys(%{ $resource->getDataLocations() }) ) {

		my $serviceRef = {};

		push @{ $dataDetails }, $serviceRef;

		foreach my $loc (@{ $resource->getDataLocations->{$service} }) {

			my $locRef = {};

			if($loc->protocol() eq 'http') {

				$numData++;

				$locRef->{'link'} = $loc->url();
				$locRef->{'link'} =~ s/\/$//;

				$locRef->{'link'} .= '/?lsid=' . $lsid;

				push @{ $serviceRef->{'locations'} }, $locRef;
			}
		}

		shift @{ $dataDetails } unless(exists($serviceRef->{'locations'}->[0]->{'link'}));
	}
	$elements{'numData'} = $numData;


	# Build a list of HTTP metadata ports
	foreach my $service (keys(%{ $resource->getMetadataLocations() }) ) {

		my $serviceRef = {};

		push @{ $metadataDetails }, $serviceRef;

		$serviceRef->{'name'} = $service;
		$serviceRef->{'locations'} = [];

		foreach my $loc (@{ $resource->getMetadataLocations->{$service} }) {

			my $locRef = {};

			if($loc->protocol() eq 'http') {

				$numMetadata++;

				$locRef->{'link'} = $loc->url();
				$locRef->{'link'} =~ s/\/$//;

				$locRef->{'link'} .= '/?lsid=' . $lsid;

				push @{ $serviceRef->{'locations'} }, $locRef;
			}
		}

		shift @{ $metadataDetails } unless(exists($serviceRef->{'locations'}->[0]->{'link'}));
	}
	$elements{'numMetadata'} = $numMetadata;

	$elements{'metadataAvailable'} = 1 	if($numMetadata > 0);
	$elements{'dataAvailable'}     = 1	if($numData     > 0);

	# The first loop is over the service names, the inner loop is on the location
	$elements{'dataDetails'}     = $dataDetails;
	$elements{'metadataDetails'} = $metadataDetails;

	return \%elements;
}


sub getMetadata {

	my $self = shift;

	my $lsid = shift;

	my $xml;

	my $resource;
	if( ($resource = &Metadata::resolveLSID($lsid)) ) {

		my $metadata;
                return undef unless( ($metadata = $resource->getMetadata()) );

		my $file = $metadata->response();

		local $/ = undef;

		my $tmp = <$file>;

		$xml = &Metadata::renderMetadata(lsid=> $lsid, 
						 metadata=> $tmp);

		return \$xml;
	}

	return undef;
}


sub getMetadataAsImage {

	my $self = shift;

	my $lsid = shift;

	my $xml;

	my $resource;
	if( ($resource =  &Metadata::resolveLSID($lsid)) ) { 

		my $metadata;
		return undef unless( ($metadata = $resource->getMetadata()) );

		my $file = $metadata->response();

		local $/ = undef;

		my $tmp = <$file>;

		# LWP Code
		require LWP::UserAgent;
		my $ua = LWP::UserAgent->new();

		my $req = HTTP::Request->new(POST => 'http://www.w3.org/RDF/Validator/ARPServlet');
		$req->content_type('application/x-www-form-urlencoded');

		$req->content("TRIPLES_AND_GRAPH=Graph%2EOnly&FORMAT=PNG_LINK&RDF=". URI::Escape::uri_escape($tmp));

		my $res = $ua->request($req);
		my $html = $res->as_string();
		# LWP Code

		if($html =~ /<a href="(ARPServlet.tmp\/servlet_\d+.png)">Get\/view/) {

			$xml = '<div>' .
			       '<img border="1" alt="Fetching metadata, this may take a few moments.." ' .
			       'src="http://www.w3.org/RDF/Validator/' . $1 . '">' .
			       '</div>';

			return \$xml;
		}

	}

	return undef;
}


sub validateLSID {

	my $self = shift;
	my $lsid = shift;


	# Remove whitespace
	$lsid =~ s/ //g;

	# Add the prefix if necessary
	if($lsid !~ /^urn[:]lsid[:]/) {

		$lsid = "urn:lsid:$lsid";
	}
	elsif($lsid !~ /^urn[:]/) {

		$lsid = "urn:$lsid";
	}
	else {

		# ?
	}

	return $lsid;
}


1;

__END__

