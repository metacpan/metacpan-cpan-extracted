package Web::App;
# $Id: App.pm,v 1.36 2009/03/23 00:44:49 apla Exp $

our $VERSION = '1.21';

use Class::Easy;
use Data::Dumper;

use IO::Easy;

use Web::App::Config;

use Web::App::Request;
use Web::App::Response;

use Web::App::Session;

has 'root';
has 'config';
has 'int';
has 'session';
has 'request';
has 'response';

has 'project', is => 'rw';

our $app = {};

1;

sub new {
	my $class   = shift;
	my $params  = {@_};
	
	bless $app, $class;
	
	debug "process initialization";
	
	my $t = timer ('project init');
	
	my $config_file;
	
	if ($params->{project}) {
		my $project = $params->{project};
		die "can't use package $project"
			unless try_to_use ($project);
		
		# modules always in lib for Web::App
		$app->{root} = $project->root;
		$app->{project} = $project;
		# !!! dirty xml hack
		$config_file = $project->root->append ('etc', $project->id . '-web-app.xml')
			unless -f $config_file;
	} else {
		$app->{root} = IO::Easy->new ($params->{'root'});
		$config_file = $params->{'config'} || 'etc/config.xml';
	}
	
	$t->lap ('config loading');
	
	# Анализирует входящий запрос, производит общую абстрактную
	# обработку запроса
  
	debug "creating Web::App object in $app->{root}";
	
	debug 'loading configuration';
	
	my $config = Web::App::Config->get ($app, $config_file);
	
	$app->{config} = $config;
	
	$t->lap ('modules loading');
	
	$config->init_modules;
	
	$t->end;
	
	return $app;
}

# accessors here

sub home {
	shift->{root};
}

sub app {
	$app;
}

sub receive_request {
	my $self = shift;
	
	# initialization
	my $request  = $self->{request}  = Web::App::Request->new ($app);
	my $response = $self->{response} = Web::App::Response->new;
	
	$request->handle ($self);
	
	$response->{data}->{request} = $request; # for presentation
	
	my $screen = $self->request->screen;
	
	# TODO CHANGE DESCRIPTION
	# we don't init session because some session
	# internals must be preloaded
	
	my $session = Web::App::Session->detect;
	
}

sub handler {
	my $self = shift;
	
	my $r = Web::App::Request->new ($app);
	
	return $r;
}

sub var {
	my $self = shift;
	return $self->response->data;
}

sub expand_params {
	my $self   = shift;
	my $params = shift;
	
	my $session = $self->session;
	my $request = $self->request;
	my $form    = $request->params;
	
	my $dirs = {
		'data-dir'   => $self->root . '/var/db/sharedwork',
		'root'       => $self->root,
		'path_info'  => $request->path_info,
		'session_id' => $session->id,
		'screen_id'  => $request->screen->id,
		'dir_info'   => $request->dir_info,
		'file_name'  => $request->file_name,
		'file_extension' => $request->file_extension,
		'base_uri'   => $request->base_uri,
		'var'        => $self->var,
		'form'       => {map {
			$_ => $form->{$_}->[0]
		} grep {! /CGI\:\:Minimal/} keys %$form},
	};
	
	my $counter = 1;
	foreach my $match (@{$request->screen_matches}) {
		$dirs->{$counter} = $match;
		$counter++;
	}
	
	if (defined ref $params and ref $params eq 'HASH') {
		foreach my $key (keys %$params) {
			#supports xslt notation: {$aaa}
			# 3-letters
			my $val = $params->{$key};
			my $pos = index ($val, '{$');
			while ($pos > -1) {
				my $end = index ($val, '}', $pos);
				my $str = substr ($val, $pos + 2, $end - $pos - 2);
				
				# warn "found replacement: key => $key, requires => \$$str\n";
				
				my $fix;
				if (index ($str, '/') > -1) { # treat as path
					# warn join ', ', keys %{$self->var};
					$fix = Web::App::Config::path_to_val ($dirs, $str);
				} else { # scalar
					$fix = $dirs->{$str};
				}
				
				# warn "value for replace is: $fix\n";
				
				if ($pos == 0 and $end == (length ($val) - 1)) {
					$val = $fix;
				} else {
					substr ($val, $pos, $end - $pos + 1, $fix);
				}
				$pos = index ($val, '{$', $end);
			}
			$params->{$key} = $val;
			# warn ("key is: $key, param is: $1");
		}
	} else { # what this?
		$params =~ s/(?:\$\{|\{\$)([\w\-_0-9]+)\}/$dirs->{$1}/g;
		return $params;
	}
	
}


sub process_request {
	my $self = shift;

	my $request  = $self->request;
	my $response = $self->response;

	my $screen = $self->request->screen;
	
	# adding processors from config for current screen into request
	my $processors = [];
	if ($request->data_available) {
		$processors = $screen->process_calls;
	} else {
		$processors = $screen->init_calls;
	}
	
	push @{$request->processors}, @$processors
		if defined $processors;
	
	$request->presentation ($screen->{'presentation'});
	
	while (my $processor = $request->next_processor) {
		
		last unless defined $processor;
		
		my $processor_params = {%$processor}; # copy
		
		my $result_place = delete $processor_params->{place};
		
		$self->expand_params ($processor_params);
		
		my $processor_call = $processor_params->{sub};

		debug "launch '$processor_call'";
		
		my ($pack, $method) = split '->', $processor_call;
		if ($pack =~ /^\$([^:]+)$/) {
			$pack = $app->$1;
		}
		
		my $result = eval {
			$pack->$method ($self, $processor_params);
		};
		
		if (defined $result and $result) {
			
			die "you must supply place for results"
				unless $result_place;
			
			die "you can't override $result_place"
				if exists $app->var->{$result_place};
			
			$app->var->{$result_place} = $result;
		}
		
		# eval "$processor_call (\$self, \$processor_params)";
		critical "after '$processor_call' launch: $@"
			if $@;
	}
	
	debug "processors finished";
	
	my $location = $self->{'redirect-to'};
	
	# !!! need to be replaced for correct headers output.

	debug Dumper $response->data
		if $Class::Easy::DEBUGIMMEDIATELY;
	
	if ($location) {
		if ($Class::Easy::DEBUGIMMEDIATELY) {
			# print "Location: <a href='$location'>$location</a>\n\n";
			debug "actual headers are below";
		} else {
			$self->response->headers->header ('Location' => $location);
		}
	}


}

sub handle_request ($$) {
	my $class = shift;
	my $r     = shift;
	
	my $self = $class->app;
	
	delete $self->{'redirect-to'};
	
	my $t = timer ('request retrieval');
	
	$self->receive_request;
	
	$t->lap ('accessors');
	
	my $request = $self->request;
	my $screen  = $request->screen;
	
	my $session = $self->session;
	
	$t->lap ('authentication');
	
	if ($screen->authenticated ($session)) {
		
		$t->lap ('processors work');
		
		$self->process_request;
		
	} else {

		debug "screen not authenticated";
		$self->clear_process_queue;
		$self->set_presentation_screen ('login');

	}
	
	$t->lap ('presentation');
	
	my $content;
	my $status;

	my $can_set_status = $request->can ('set_status');

	if ($self->redirected) {
		$request->set_status (302)
			if $can_set_status;

		$self->send_headers;

	} else {
		$request->set_status (200)
			if $can_set_status;

		$self->prepare_presenter;
		$content = $self->run_presenter;
		
		$self->send_headers;
	
		$request->send_content ($content);
	}

	$t->end;
	debug "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< request finished";
	$t->total;
	
	$request->done_status;
}

sub prepare_presenter {
	my $app = shift;
	
	# maybe processor changed presentation
	my $presentation = $app->request->presentation;
	
	my $presenter = $app->config->presenters->{$presentation->{'type'}};
	
	$app->response->presenter ($presenter);
	
	$presenter->headers;

}

sub debug_log { # TODO: more optimal way without copying
	my $self  = shift;
	
	my $result = $Web::App::LOG;
	
	$Web::App::LOG = '';
	
	my $presentation = $self->request->presentation;
	my $presentation_type = $presentation->{'type'};
	
	# we must prettify log for html
	
	my $presenters = $self->config->presenters;
	my $presenter;
	
	if ($presentation_type) {
		$presenter  = $presenters->{$presentation_type};
	} else {
		if ($self->response->headers->content_type =~ /text\/html/) {
			$presenter = $presenters->{'xslt'};
			warn "we hacked into xslt";
		}
	}

	if ($presenter and $presenter->can ('wrap_log')) {
		return $presenter->wrap_log ($result);
	} else {
		return $result;
	}

}

sub send_headers {
	my $app = shift;
	
	my $request = $app->request;
	
	return if $request->headers_sent;
	
	my $headers = $app->response->headers;
	
	$request->send_headers ($headers);
	debug "headers are: ", $headers->as_string;
	
	$request->headers_sent (1);
}

sub set_presentation {
	my $self = shift;
	my $presentation = shift;
	
	$self->request->presentation ($presentation);
}

sub set_presentation_screen {
	my $self = shift;
	my $screen_name = shift;
	
	my $screen = $self->config->screen ($screen_name)->{'?'};
	
	$self->request->presentation ($screen->{'presentation'});
	
	$self->request->screen ($screen);
	
}

sub clear_process_queue {
	my $self = shift;
	
	debug 'requested for clearing processor queue, processed';
	
	$self->request->processors ([]);
}

sub redirect_to_screen {
	my $self   = shift;
	my $screen = shift;
	
	my $request = $self->request;
	
	return unless $request->type eq 'CGI';
	
	# TODO CRITICAL: fix for proto (https) and port
	
	my $base_uri = $request->base_uri;
	my $host     = $request->host;
	if ($self->project and exists $self->project->config->{'hostname'}) {
		$host = $self->project->config->{'hostname'};
	}

	if ( $request->{'session-id'} ) {
		my $session_id = $request->{'session-id'};
		$self->{'redirect-to'} = "http://$host$base_uri/$session_id\@$screen";
	
	} else {
		$self->{'redirect-to'} = "http://$host$base_uri/$screen";
	}
}

sub redirect {
	my $self = shift;
	my $url  = shift;
	
	debug "requested redirect to uri: $url";

	my $request = $self->request;
	
	$self->{'redirect-to'} = $url;
}

sub redirected {
	my $self = shift;
	
	my $status = 0;
	$status = 1 if exists $self->{'redirect-to'} and $self->{'redirect-to'} ne '';
	return $status; 
}

sub run_presenter {
	my $self	  = shift;
	
	my $presentation = $self->request->presentation;

	debug "presenter: " . $presentation->{'type'}
		. (defined $presentation->{'file'} ? " in " . $presentation->{'file'} : '');

	my $presenter  = $self->response->presenter;
	
	critical "maybe you want to register presenter, because i nothing knows about '$presentation->{type}'"
		unless defined $presenter;
	
	my $data = $self->response->data;
	
	my $content;
	eval {
		$content =  $presenter->process ($self, $data, %$presentation);
	};
	
	debug $@ if $@;
	
	return $content;
}

1;
