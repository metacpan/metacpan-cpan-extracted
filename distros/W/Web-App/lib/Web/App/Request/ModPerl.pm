package Web::App::Request::ModPerl;

use Class::Easy;

use base qw(Web::App::Request);

return 1
	unless $ENV{MOD_PERL};

our $mod_perl_api = 1;
$mod_perl_api = $ENV{MOD_PERL_API_VERSION}
	if exists $ENV{MOD_PERL_API_VERSION} and $ENV{MOD_PERL_API_VERSION} == 2;

my $mod_perl_config = [
	{},
	{
		request => 'Apache',
		server  => 'Apache',
		const   => 'Apache::Constants',
		strings => {
			stage   => '',
			handler => 'perl-script',
		}

	},
	{
		request => 'Apache2::RequestUtil',
		# request_rec => 'Apache2::RequestRec',
		server  => 'Apache2::ServerUtil',
		const   => 'Apache2::Const',
		strings => {
			stage => 'Response',
			handler => 'modperl',
		}
	}
];

my $mod_perl = $mod_perl_config->[$mod_perl_api];

my $strings = delete $mod_perl->{strings};

if ($mod_perl_api == 2) {
	try_to_use_inc ('Apache2::RequestRec');
	*{Apache2::RequestRec::send_http_header} = sub {return};
}

for my $k (keys %$mod_perl) {
	next if $k eq 'sizelimit' and $^O eq 'darwin';
	try_to_use_inc ($mod_perl->{$k});
}

my $const = $mod_perl->{const};

if ($mod_perl_api == 2) {
	$const->import (-compile => qw(:common :http));
} else {
	$const->import (qw(:common :http));
}

# UNAVAILABLE FOR MAC OS X
# use Apache2::SizeLimit;

# $Apache2::Size::MAX_PROCESS_SIZE  = 256*1024;  # 256MB
# $Apache2::Size::MIN_SHARE_SIZE    = 128*1024;  # 128MB
# $Apache2::Size::MAX_UNSHARED_SIZE = 160*1024;  # 160MB

# my $dir_config = Apache2::ServerUtil->server->dir_config;

has 'http_code', is => 'rw', default => $const->DONE;

sub r {
	my $r = $mod_perl->{request}->request;
	
	die unless defined $r;
	
	return $r;
}

sub server {
	return $mod_perl->{server}->server;
}

sub rewrite_root {
	my $r = shift;
	
	$r->uri ('/index.html')
		if $r->uri eq '/';
	return $const->DECLINED;
}

sub _preload {
	my $class = shift;
	my $app   = shift;
	
	my $server = $class->server;
	my $location = '';
	
	return if $mod_perl_api != 2;

	$server->add_config (['PerlTransHandler +Web::App::Request::ModPerl::rewrite_root']);
	
	my @ending = (
		"	SetHandler $strings->{handler}",
		"	Perl$strings->{stage}Handler Web::App->handle_request",
		'	DefaultType text/html',
		'</Location>',
	);
	
	my $screens = $app->config->screens;
	
	my $base_uri = $screens->{'#base-uri'};
	
	if ($base_uri and $base_uri ne '/') {
		debug "preloading into $base_uri";
		die "base-uri key in screens config must begins with '/'"
			if $base_uri !~ /^\//;
		my $location = "<Location $base_uri>";
		#warn join "\n", ($location, @ending);
		$server->add_config([
			$location,
			@ending	
		]);
		
	} else {
		debug "preloading into /";
		my @screen_ids = grep {/^(\?|[^\#\/]+)$/} keys %$screens;
		debug join ', ', @screen_ids;
		foreach my $screen_id (@screen_ids) {
			$screen_id = 'index.html'
				if $screen_id eq '?';
			
			debug "init screen /$screen_id";
			
			my $location = "<Location /$screen_id>";
			#warn join "\n", ($location, @ending);
			$server->add_config([
				$location,
				@ending
			]);
		}
	}
	
}


# this code called every request
sub _init {
	my $self = shift;
	my $app  = shift;
	
	my $r = r;
	
	my $uri = $r->uri;
	# my $path_info = $r->path_info;
	
	my $screens = $app->config->screens;
	
	my $base_uri = $screens->{'#base-uri'}; #($uri =~ /(.*)$path_info$/)[0];
	$base_uri =~ s/\/$//; # we don't want double slashes
	
	my $path_info = ($uri =~ /^$base_uri(.*)$/)[0];
	
	debug "uri: $uri, p_i: $path_info, base_uri: $base_uri";
	
	my $host = $self->incoming_headers->{'X-Forwarded-Host'} || $r->hostname;
	
	$self->set_field_values (
		host      => $host,
		uri       => $uri,
		base_uri  => $base_uri,
		path      => $path_info,
	);
} 

sub set_status {
	my $self = shift;
	my $code = shift;
	if ($self->can('r')) {
		if ($code == 200) {
			debug "setting r->status->HTTP_OK";
			$self->r->status ($const->HTTP_OK);
		} elsif ($code == 302) {
			debug "setting r->status->HTTP_MOVED_TEMPORARILY";
			$self->r->status ($const->HTTP_MOVED_TEMPORARILY);
		}
	}
}

sub done_status {
	$const->DONE;
}

sub redirect_status {
	$const->REDIRECT;
}


sub r_method {
	my $object = shift;
	my $method = shift;
	
	if ($mod_perl_api == 1) {
		$object->$method (@_);
	} elsif ($mod_perl_api == 2) {
		$object->$method (@_, r());
	}
}

sub send_headers {
	my $self = shift;
	my $headers = shift;
	
	my $r = r;

	my $method = 'headers_out';
	if ($headers->header ('Location')) {
		debug "redirect detected";
		$self->redirected (1);
		$method = 'err_headers_out';
	}
	
	$r->$method->clear;
	
	foreach my $key (($headers->header_field_names)) {
		my $val = $headers->header ($key);
		if ($key =~ /content-type/i) {
			$r->content_type ($val);
		} else {
			# $key =~ s/\b(\w)/uc $1/ge;
			$r->$method->{$key} = $val;
		}
	}

	$r->send_http_header;
}

sub incoming_headers {
	my $self = shift;
	
	return r->headers_in;
}

sub send_content {
	my $self    = shift;
	my $content = shift;
	
	debug "content output";
	
	utf8::decode ($content);
	
	r->print ($content);
}

1;
