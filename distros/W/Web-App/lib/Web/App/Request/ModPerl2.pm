package Web::App::Request::ModPerl2;

use Class::Easy;

use Web::App::Request;
use base qw(Web::App::Request);

return 1
	unless $ENV{MOD_PERL};

our $MOD_PERL = 2;
$MOD_PERL = $ENV{MOD_PERL_API_VERSION}
	if $ENV{MOD_PERL_API_VERSION};

use Apache2::Const -compile => qw(:common :http);

use Apache2::RequestUtil;
use Apache2::RequestRec;

# UNAVAILABLE FOR MAC OS X
# use Apache2::SizeLimit;
use Apache2::ServerUtil;

# $Apache2::Size::MAX_PROCESS_SIZE  = 256*1024;  # 256MB
# $Apache2::Size::MIN_SHARE_SIZE    = 128*1024;  # 128MB
# $Apache2::Size::MAX_UNSHARED_SIZE = 160*1024;  # 160MB

# my $dir_config = Apache2::ServerUtil->server->dir_config;

has 'http_code', is => 'rw', default => Apache2::Const::DONE;

sub r {
	my $r = Apache2::RequestUtil->request;
	
	die unless defined $r;
	
	return $r;
}

sub rewrite_root {
	my $r = shift;
	
	$r->uri ('/index.html')
		if $r->uri eq '/';
	return Apache2::Const::DECLINED;
}

sub _preload {
	my $class = shift;
	my $app   = shift;
	
	my $server = Apache2::ServerUtil->server;
	my $location = '';
	
	$server->add_config (['PerlTransHandler +Web::App::Request::ModPerl2::rewrite_root']);
	
	my @ending = (
		'	SetHandler modperl',
		'	PerlResponseHandler Web::App->handle_request',
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
		unparsed_uri => $r->unparsed_uri,
	);
} 

sub done_status {
	Apache2::Const::OK;
}

sub redirect_status {
	Apache2::Const::REDIRECT;
}


sub test ($$) {
	my $class = shift;
	my $r     = shift;
	
	# my $r = Apache2::RequestUtil->request;
	$r->content_type ('text/html');
	#$r->headers_out
	
	foreach (sort keys %ENV) {
		$r->print ("$_ => $ENV{$_}<br/>\n");
	}
	
	$r->print ("HELLO!!!");
	
	Apache2::Const::OK;
}

sub r_method {
	my $object = shift;
	my $method = shift;
	
	$object->$method (@_, r());
}

sub send_headers {
	my $self = shift;
	my $headers = shift;
	
	my $method = 'headers_out';
	if ($headers->header ('Location')) {
		debug "redirect detected";
		$self->redirected (1);
		$method = 'err_headers_out';
	}
	
	r->$method->clear;
	
	foreach my $key (($headers->header_field_names)) {
		my $val = $headers->header ($key);
		if ($key =~ /content-type/i) {
			r->content_type ($val);
		} else {
			# $key =~ s/\b(\w)/uc $1/ge;
			r->$method->{$key} = $val;
		}
	}
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