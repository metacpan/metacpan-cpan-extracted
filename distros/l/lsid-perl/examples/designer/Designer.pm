# =====================================================================
# Copyright (c) 2002,2003 IBM Corporation
# All rights reserved.  This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
#
# =====================================================================
package Designer;

use strict;
use warnings;

use base 'CGI::Application';

use CGI qw(Standard);
use CGI::Session;

use Template;


my $TITLE = 'LSID Perl Authority Framework Generator';

my $KEYS = [ 'defaultLocation', 'authorityName', 'authorityID', 'namespaces', 'mappings', 
	     'mappingsPopup', 'metadataService', 'dataService', 'authorityService', 'useHTTPService',
	     'services', 'portList', 'portName', 'portLocation', 'portType', 'portProtocol'
	   ];


sub setup {

        my $self = shift;

        $self->run_modes(
                'start'=> 'start',
                'configuration'=> 'configuration',
                'services'=> 'services',
		'ports'=> 'ports',
                'view'=> 'view',

		);

	$self->tmpl_path('templates');

        $self->start_mode('start');
        $self->mode_param('rm');

}

sub cgiapp_init {

	my $self = shift;

	$self->session();
}

sub session {

	my $self = shift;

	my $query = $self->query();


	my $sessionCookie = ($query->cookie('LSIDDesigner') || $query->param('LSIDDesigner') || undef);

	my $session = CGI::Session->new('driver:File',
					$sessionCookie,
					{
						Directory=> '/var/tmp/'
					}
				) or die($CGI::Session::errstr);

	if(!$sessionCookie || ($sessionCookie ne $session->id()) ) {

		my $cookie = $query->cookie(	-name=>'LSIDDesigner', 
						-expires=> '+5m',
						-value=> $session->id()
					   );

		$self->header_add(-cookie=> $cookie);
	}
	else {

		# Refresh system
		my $cookie = $query->cookie('LSIDDesigner');

		$self->header_add(-cookie=> $cookie);
	}

	$self->param('session'=> $session);
	$self->param('sessionID'=> $session->id());
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
				     -onLoad=> 'doPopup();',
				     -style=> {
						'src'=> 'style.css',
					      },
				     -topmargin=> 0,
				     -leftmargin=> 0,
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

	my $template = $self->load_tmpl('start.html.template');
	my $output = $self->my_header();

        $output .= $query->start_form(-name=> 'start');
        $output .= '<input type="hidden" name="rm" value="configuration">';

	# Form elements

	my %elements;

	$elements{'submit'} = $query->submit(-name=> 'Proceed to Authority Configuration');

	# HTML::Template variables

	foreach my $var (keys(%elements)) {

		$template->param($var=> $elements{ $var });
	}


	# Page completion

	$output .= $template->output();
	$output .= $query->endform();
	$output .= $self->my_footer();	

	return $output;
}


sub configuration {

	my $self = shift;

	my $query = $self->query();
	my $session = $self->param('session');

	# Load the form if data is present, useful if the user presses the
	# back button
	$session->save_param( $query ) if($query->param());
	$session->load_param( $query, $KEYS );

	# Page initialization

	my $template = $self->load_tmpl('configuration.html.template');
	my $output = $self->my_header();

        $output .= $query->start_form(-name=> 'configuration');
        $output .= '<input type="hidden" name="rm" value="services">';


	# Form elements
	my %elements;

	$elements{'defaultLocation'} = $query->textfield(-name=> 'defaultLocation',
							 -default=> '',
							 -size=> 50,
							 -maxlength=> 255);

	$elements{'authorityName'} = $query->textfield(-name=> 'authorityName',
						       -default=> '',
						       -size=> 25,
						       -maxlength=> 255);

	$elements{'authorityID'} = $query->textfield(-name=> 'authorityID',
						     -default=> '',
						     -size=> 50,
						     -maxlength=> 255);

	#
	# Configure what services are available
	#
	my $labels = {  authorityService=> 'Authority Service',
			dataService=> 'Data Service',
			metadataService=> 'Metadata Service',
		     };

	$elements{'services'} = $query->checkbox_group(-name=> 'services',
						       -values=> [ sort(keys( %{ $labels } )) ], 
						       -default=> ['authorityService' ],
						       -linebreak=> 'true',
						       -labels=> $labels);

	$elements{'useHTTPService'} = $query->checkbox(-name=>'useHTTPService',
						       -checked=>'checked',
						       -value=>'1',
						       -label=>'Use HTTP Service');

	$elements{'submit'} = $query->submit(-name=> 'Continue to Service Definitions');

	# HTML::Template variables

	foreach my $var (keys(%elements)) {

		$template->param($var=> $elements{ $var });
	}


	# Page completion

	$output .= $template->output();
	$output .= $query->endform();
	$output .= $self->my_footer();	

	return $output;
}


sub services {

	my $self = shift;

	my $query = $self->query();
	my $session = $self->param('session');

	#
	# Save values from previous stage in session
	#
	$session->save_param( $query ) if($query->param());
	$session->load_param( $query, $KEYS );


	# Page initialization

	my $template = $self->load_tmpl('services.html.template');
	my $output = $self->my_header();

        $output .= $query->start_form(-name=> 'services',
				      -onSubmit=> 'return doSubmit()');

        $output .= '<input type="hidden" name="rm" value="ports">';

	# Form elements
	my %elements;

	#
	# Add namespaces
	#
	$elements{'namespaces'} = $query->scrolling_list(-name=>'namespaces',
							 -values=> undef,
							 -default=> undef,
	                        			 -size=> 8,
	                        			 -multiple=> 'true',
                                			 -labels=> undef,
							 -class=> 'widelist');

	$elements{'newNamespace'} = $query->textfield(-name=> 'newNamespace',
						      -default=> '',
						      -size=> 25,
						      -maxlength=> 255);

	$elements{'removeNamespace'} = $query->button(-name=>'removeNamespace',
						      -value=>'Remove Selected Namespace(s)',
						      -onClick=>'doRemoveNamespace(this)');

	$elements{'addNamespace'} = $query->button(-name=>'addNamespace',
						   -value=>'Add Namespace',
						   -onClick=>'doAddNamespace(this)');


	#
	# Add mappings for namespaces
	#
	$elements{'mappings'} = $query->scrolling_list(-name=>'mappings',
						       -values=> undef,
						       -default=> undef,
	                        		       -size=> 8,
	                        		       -multiple=> 'true',
                                		       -labels=> undef,
						       -class=> 'widelist');


	$elements{'newMapping'} = $query->textfield(-name=> 'newMapping',
						    -default=> '',
						    -size=> 25,
						    -maxlength=> 255);

	my $popupLabels = { ':::namespace:::' => 'Please select a namespace...' };

	$elements{'mappingsPopup'} = $query->popup_menu(-name=>'mappingsPopup',
						        -values=> $popupLabels,
						        -labels=> $popupLabels,
						        -default=>':::namespace:::');

	$elements{'removeMapping'} = $query->button(-name=>'removeMapping',
						 -value=>'Remove Selected Mapping(s)',
						 -onClick=>'doRemoveMapping(this)');

	$elements{'addMapping'} = $query->button(-name=>'addMapping',
						 -value=>'Add Mapping',
						 -onClick=>'doAddMapping(this)');



	$elements{'submit'} = $query->submit(-name=> 'Continue to Port Definitions');

	# HTML::Template variables

	foreach my $var (keys(%elements)) {

		$template->param($var=> $elements{ $var });
	}


	# Page completion

	$output .= $template->output();
	$output .= $query->endform();
	$output .= $self->my_footer();

	return $output;
}


sub ports {

	my $self = shift;

	my $query = $self->query();
	my $session = $self->param('session');

	#
	# Save values from previous stage in session
	#
	$session->save_param( $query ) if($query->param());
	$session->load_param( $query, $KEYS );


	# Page initialization

	my $template = $self->load_tmpl('ports.html.template');
	my $output = $self->my_header();

        $output .= $query->start_form(-name=> 'ports',
				      -onSubmit=> 'return doSubmit()');

        $output .= '<input type="hidden" name="rm" value="view">';

	# Form elements
	my %elements;

	#
	# Add a port
	#
	$elements{'portList'} = $query->scrolling_list(-name=>'portList',
						       -values=> undef,
						       -default=> undef,
	                        		       -size=> 5,
	                        		       -multiple=> 'true',
                                		       -labels=> undef,
						       -class=> 'widelist');

	$elements{'portName'} = $query->textfield(-name=> 'portName',
						  -default=> '',
						  -size=> 25,
						  -maxlength=> 255);

	my $popupLabels = { ':::portType:::'=> 'Please select a port type...',
			    'newMetadataPort'=> 'Metadata Port',
			    'newDataPort'=>	'Data Port',
			  };

	$elements{'portType'} = $query->popup_menu(-name=>'portType',
						        -values=> [ sort(keys(%{ $popupLabels })) ],
						        -labels=> $popupLabels,
						        -default=> ':::portType:::');

	$elements{'portLocation'} = $query->textfield(-name=> 'portLocation',
						      -default=> '',
						      -size=> 50,
						      -maxlength=> 255);

	$elements{'removePort'} = $query->button(-name=>'removePort',
						      -value=>'Remove Selected Port(s)',
						      -onClick=>'doRemovePort(this)');

	$elements{'addPort'} = $query->button(-name=>'addPort',
						   -value=>'Add Port',
						   -onClick=>'doAddPort(this)');


	$popupLabels = { ':::portProtocol:::'=> 'Please select a protocol...',
			 'http'=> 'HTTP',
			 'soap'=> 'SOAP',
		       };

	$elements{'portProtocol'} = $query->popup_menu(-name=>'portProtocol',
						       -values=> [ sort(keys(%{ $popupLabels })) ],
						       -default=> '::portProtocol::',
						       -labels=> $popupLabels);

	$elements{'submit'} = $query->submit(-name=> 'Continue to Code Preview');

	# HTML::Template variables

	foreach my $var (keys(%elements)) {

		$template->param($var=> $elements{ $var });
	}


	# Page completion

	$output .= $template->output();
	$output .= $query->endform();
	$output .= $self->my_footer();

	return $output;
}


sub view {

	my $self = shift;

	my $query = $self->query();
	my $session = $self->param('session');

	#
	# Save the other parameters
	#
	$session->save_param( $query ) if($query->param());
	$session->load_param( $query, $KEYS );

	# Source template

	my $vars = {};
	foreach my $k (@{ $KEYS }) {


		$vars->{ 'useHTTPService' } = 0;

		if($k eq 'services' ) {

			my $services = $session->param( $k );

			$services = [ $services ] unless(ref $services eq 'ARRAY');

			$vars->{ 'authorityService' } = 0;
			$vars->{ 'metadataService' } = 0;
			$vars->{ 'dataService' } = 0;

			foreach my $svc (@{ $services }) {

				$vars->{ $svc } = 1;
			}
		}
		elsif($k eq 'mappings') {

			my $mappings = $session->param( $k );

			$mappings = [ $mappings ] unless(ref $mappings eq 'ARRAY');

			my $mapRef = {};
			foreach my $map (@{ $mappings }) {

				next unless($map);

				my ($ns, $m) = split(/=> /, $map);
				$mapRef->{ $m } = $ns;
			}

			$vars->{ $k } = $mapRef if($mapRef);
		}
		elsif($k eq 'portList') {

			my $ports = $session->param( $k );

			$ports = [ $ports ] unless(ref $ports eq 'ARRAY');

			my $portRef = {};

			$vars->{ $k } = [];

			foreach my $p (@{ $ports }) {

				next unless($p);

				my ($name, $endpoint, $type) = split(/=>/, $p);

				$name =~ s/ //g;
				$endpoint =~ s/ //g;
				$type =~ s/ //g;

				$portRef->{'name'} = $name;

				if($endpoint =~ /^(http|soap)\:\/\/(.*)/) {
					$portRef->{'protocol'} = $1;
					$portRef->{'endpoint'} = $2;
				}
				else {

					$portRef->{'protocol'} = "+++ ERROR PROTOCOL +++";
					$portRef->{'endpoint'} = "+++ ERROR ENDPOINT +++";
				}

				if($type eq 'DataPort' || 
				   $type eq 'MetadataPort') {

					$portRef->{'type'} = "add$type";
				}
				else {

					$portRef->{'type'} = "+++ ERROR IN PORT TYPE +++";
				}

				push @{ $vars->{ $k } }, $portRef;
			}

		}
		else {

			$vars->{ $k } = $session->param( $k );
		}
	}







	# Page initialization
	my $template;
	my $output = $self->my_header();

	$output .= $query->start_form(-name=> 'view');
	$output .= '<input type="hidden" name="rm" value="view">' . "\n";
	$output .= '<input type="hidden" name="code" value="">' . "\n"; 

	my $code;

	if($query->param('code') eq 'driver') {

		my $sourceTemplate = Template->new();
		$sourceTemplate->process( 'authority.tt',  $vars, \$code);

		$code = "<pre>$code</pre>";
	}
	elsif($query->param('code') eq 'namespaces' ) {

		my $ns = {};

		$ns->{'namespaces'} = $vars->{'namespaces'};

		my $namespaceTemplate = Template->new();
		$namespaceTemplate->process('Namespaces.tt', $ns, \$code);

		$code = "<pre>$code</pre>";
	}
	else {

		my $inst_template = $self->load_tmpl('instructions.html.template');

		$code = $inst_template->output();
	}

	$template = $self->load_tmpl('view.html.template');

	# Form elements
	my %elements;

	$elements{'code'} = $code;

	$elements{'submit'} = $query->submit(-name=> 'restart',
					     -onClick=> "document.view.rm.value='start';",
					     -value=> 'Restart Process');

	# HTML::Template variables

	foreach my $var (keys(%elements)) {

		$template->param($var=> $elements{ $var });
	}

	# Page completion

	$output .= $template->output();
	$output .= $query->endform();
	$output .= $self->my_footer();

	return $output;
}



1;

__END__

