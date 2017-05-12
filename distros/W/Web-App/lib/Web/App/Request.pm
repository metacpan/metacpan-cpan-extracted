package Web::App::Request;
# $Id: Request.pm,v 1.13 2009/03/29 10:01:05 apla Exp $

use Class::Easy::Base;

use Encode qw/encode decode/;

use Web::App;

use CGI::Minimal;

has 'params', is => 'rw';
has 'screen', is => 'rw';
has 'processors', is => 'rw';
has 'presentation', is => 'rw';
has 'headers_sent', is => 'rw';

has 'data_available';
has 'path_info', is => 'rw';
has 'base_uri', is => 'rw';

has 'dir_info', is => 'rw';
has 'file_name', is => 'rw';
has 'file_extension', is => 'rw';

has 'redirected', is => 'rw', default => 0;

has 'unparsed_uri', is => 'rw';
has 'path', is => 'rw';

has 'uri', is => 'rw';
has 'host', is => 'rw';

has 'error_count', is => 'rw';

has 'type', is => 'rw'; # CGI or XHR

has 'screen_matches', is => 'rw';

sub preload {
	my $class = shift;
	my $app   = shift;
	
	my $pack = &detect_package;
	
	try_to_use ($pack) || die;
	
	$pack->_preload ($app)
		if $pack->can ('_preload');
	
}

sub new {
	my $class = shift;
	my $app   = shift;
	
	my $request = {
		processors => [],
		presenter => {},
	};
	
	debug ">>>>>>>>>>>>>>>> request handling <<<<<<<<<<<<<<<<";
	
	my $pack = &detect_package;
	
	try_to_use ($pack) || die;
	
	bless $request, $pack;
	
	$request->_init ($app)
		if $request->can ('_init');
	
	return $request;
}

sub process {
	my $self = shift;
	
	my $app = Web::App::Core->instance;
	
	my $response = Web::App::Response->new;
	
	my $screen_class = $app->screen_class;
	
	my $screen = $screen_class->for_request ($self);
	
	unless (defined $screen) {
		$screen = $screen_class->for_code (404);
		unless (defined $screen) {
			# we must have check for main screen during Screen init procedure
			# if not, this error appears on most error screens
			$screen = $screen_class->main_screen;
		}
	}
	
	if ($screen->auth) {
		my $session = Web::App::Session->new ($self);
		$screen = $screen_class->for_code (403)
			unless $session->authorized ($screen);
		
		return $self->present_and_transmit;
	}
	
	my $commands = $screen->commands;
	
	# TODO: coroutines
	
	my $get_through = "get_through_parallel";
	if (1 || $app->config->{no_coro}) {
		$get_through = "get_through";
	}
	
	# real request state change occurs if codes
	# 302/303, 401, 403, 404, 5xx received
	my $http_code = $self->$get_through ($screen->commands);
	
	if ($http_code >= 300) {
		# sometimes error screens have additional processing
		$screen = $screen_class->for_code ($response->http_code);
		
		# if we have error even when processing error screen, god bless america
		$self->$get_through ($screen->commands);
	}
	
	$self->present_and_transmit;
}

sub get_through { # screen queue
	my $self  = shift;
	my $queue = shift;
	
	my $response_data = $self->response->data;
	
	my $processing = $queue;
	
	if (ref $queue->[0] ne 'ARRAY') { # we assume command objects
		$processing = [$queue];
	}
	
	foreach my $processing_queue (@$processing) {
		foreach my $command (@$processing_queue) {
			my ($http_code, $data) = ($command->run);
			$response_data->{$command->response_slot} = $data
				if defined $data;
			
			return $http_code
				if $http_code != 200 and $command->important;
		}
	}
	
	return 200;
}

sub present_and_transmit {
	my $self = shift;
	
	my $document = $self->presentation ($self->response);
	
	$self->transmit ($document);
}

sub detect_package {
	my $pack = 'Web::App::Request';
	# environment is our way to check for available request modes
	if (exists $ENV{MOD_PERL}) {
		$pack = 'Web::App::Request::ModPerl';
	} elsif (exists $ENV{QUERY_STRING}) {
		$pack = 'Web::App::Request::CGI';
	} else {
		critical "unknown request type";
	}
	
	return $pack;
}

sub done_status {
	1;
}

sub redirect_status {
	1;
}

sub param {
	my $self = shift;
	
	return $self->params->param (@_);
}

sub check_params {
	my $class  = shift;
	my $app    = shift;
	my $params = shift;

	# этот метод проверяет данные в Apache::Request и переносит их
	# в данные для презентации. если данные не соответсвуют описанию,
	# то стек процессоров должен быть очищен.
	
	my $self = $app->request;
	
	my $fields = $self->screen->params;
	
	# use Data::Dumper;
	# die Dumper $self->screen_config
	#	unless scalar keys %$fields;
	
	foreach my $field (@$fields) {
		
		# warn "processing field: $field_name\n";
		
		my $required = $field->{'required'};
		my $type     = $field->{'type'};
		my $name     = $field->{'name'};
		
		my $regexp   = $self->get_regexp_for_type ($type);
		
		if ($required and (
				not exists ($self->params->{$name})
				or ref $self->params->{$name} ne 'ARRAY'
		)) {
			$self->empty_param ($field);
		}
		
		my $values = $self->params->{$name};
		foreach my $counter (0 .. $#$values) {
			
			my $value = $values->[$counter];
			
			local $1;
			
			if (!$value or $value !~ /$regexp/) {
				$self->invalid_param ($field);
				last;
			}
			
			$values->[$counter] = $1;
			
			last unless defined $field->{'multi'};
		}
		
	} # foreach
	
	$app->clear_process_queue
		if $self->error_count > 0 and !$params->{'no-queue-cleanup'};
	
	#warn Dumper ($fields), "\n"
	#	if $error_count > 0;
	
	return;
	
} # check_form_values


sub next_processor {
	my $self = shift;
	
	my $processor = shift @{$self->{processors}};
	return $processor;
}

sub cgi {
	shift->{'params'};
}

# любые значения формы должны быть разобраны следующим образом
# тогда можно вывести два списка: поля, блокирующие прохождение формы
# и поля, которые попросту не будут учтены при ее использовании
# необходимость	пропущенное значение		неправильное значение
# необходимо	absent, blocker				blocker
# по желанию	absent						invalid

sub invalid_param {
	my $self = shift;
	$self->param_error (shift, 'WRONG');
}

sub empty_param {
	my $self  = shift;

	$self->param_error (shift, 'EMPTY');
}

sub duplicate_param {
	my $self = shift;
	$self->param_error (shift, 'DUPLICATE');
	
}

sub param_error {
	my $self  = shift;
	my $field = shift;
	my $code  = shift;
	
	my $app = Web::App->app; 
	
	my $var = $app->var;
	
	$self->{error_count} ++;
	
	$var->{errors}->{$field->{name}} = [
		$field->{required} ? 'required' : 'optional',
		$code
	];
	
}

sub add_error_reason {
	my $self = shift;
	my $code = shift;
	my $details = shift;
	
	my $app = Web::App->instance;
	push @{$app->request->params->{'error-reasons'}}, $code;
	log_error ("'$code': $details");
}

sub get_regexp_for_type {
	my $self = shift;
	my $type = shift;
	
	critical "can't get type from undefined or empty string"
		if not defined $type or $type eq '';
	
	if ($type =~ /^regexp:(.*)$/) {
		return qr/^($1)$/;
	} elsif ($type eq 'email') {
		return qr/^([\040-\176]+\@[-A-Za-z0-9.]+\.[A-Za-z]+)$/;
	} else {
		critical "'$type' is not known";
	}
}

sub status {
	return 1;
}

sub CGI::Minimal::fix_params {
	my $query = shift;
	
	foreach my $form_field (($query->param)) {
		my @values = ();
		next if scalar grep {$_ ne ''} ($query->param_filename ($form_field));
		foreach my $raw_value (($query->param ($form_field))) {
			# try to decode
			my $decoded;
			local $@;
			eval {$decoded = decode_utf8 ($raw_value)};
			if (defined $decoded and not $@) {
				push @values, $decoded;
				next;
			}
			push @values, $raw_value;
		}
		$query->param ({$form_field => \@values});
		$query->{$form_field} = \@values;
	}
	
}

sub handle {
	my $self = shift;
	my $app  = shift;
	
	my $config = $app->config;
	
	my $path = $self->path;
	
	$path =~ s/^\///;
	debug "request path_info is: '$path'";
	
	my ($screen, $path_info, $matches) = $config->screen_from_request ($path);
	
	$path_info =~ s/\/\//\//sg
		if defined $path_info;

	my ($dir_info, $file_name, $file_extension);
	($dir_info, $file_name, $file_extension) = ($path_info =~ /^(?:(.*)\/+)?([^\/]+)\.([^\.\/]+)$/s)
		if defined $path_info;
	
	no warnings 'uninitialized';
	debug "path_info '$path_info', dir_info '$dir_info', file_name '$file_name', file_extension '$file_extension'";
	use warnings 'uninitialized';
	
	my $screen_name = $screen->id;
	
	$screen_name ne '' 
		? debug 'this is request for screen: ' . $screen_name . (
			scalar @$matches
				? ' [' . join (', ', @$matches) . ']'
				: ''
		)
		: debug 'this is request for main system screen with empty id';
	
	my $t = timer ('CGI::Minimal init');
	
	CGI::Minimal::reset_globals;
	# CGI::Minimal::allow_hybrid_post_get (1);
	CGI::Minimal::max_read_size ($screen->request->{'max-size'});
	my $query = CGI::Minimal->new;

	$t->lap ('fixups');
	
	$query->fix_params;
	
	if (scalar $query->param) {
		$self->{data_available} = 1;
	}
	
	# now screen id defined. we must check for default values
	foreach my $screen_param (@{$screen->params}) {
		$query->{$screen_param->{'name'}} = $screen_param->{'default'}
			if not exists $query->{$screen_param->{'name'}} 
				and $#{$screen_param->{'default'}} > -1;
	}
	
	$t->lap ('field values from Class::Easy');
	
	$self->set_field_values (
		dir_info  => $dir_info,
		file_name => $file_name,
		file_extension => $file_extension,
		path_info => $path_info,
		screen    => $screen,
		params    => $query,
		screen_matches => $matches
	);
	
	$t->end;
	
	$self->type ('CGI');
	
	return unless $self->can ('incoming_headers');
	
	my $headers = $self->incoming_headers;
	
	return unless $headers;
	
	my $xhr_header = 'X-Request-Type';
	return unless $headers->{$xhr_header} and $headers->{$xhr_header} eq 'XHR';
	
	debug "XHR request detected";
	
	$self->type ('XHR');
	
}

sub send_content {
	my $self    = shift;
	my $content = shift;
	
	debug "content output";
	
	# fix for "Wide characters to print"
	binmode STDOUT, ":utf8";
	utf8::decode ($content);
	$| = 1;
	
	print $content;
}

sub TO_JSON {
	my $self = shift;
	
	return {%$self}; 
}

1;
