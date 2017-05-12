package Web::App::Session;
# $Id: Session.pm,v 1.8 2009/03/29 10:03:43 apla Exp $

use Class::Easy;

use CGI::Cookie; # can we use CGI::Cookie::XS?
use Digest::MD5;

use Web::App;

has 'id', is => 'rw';
has 'user', is => 'rw';
has 'expired', is => 'rw';
has 'sudo_behaviour', is => 'rw';
has 'no_parse_cookie', is => 'rw';

# this module has two dependencies:
# data provider for request and accounts

sub init {
	my $class = shift;
	my $self  = shift;
	
	# bless $self, $class;
	
	my $app = Web::App->app;
	# $app->{session} = $self;
	
	my $salt_file = $self->{salt_file} ||= 'etc/salt';
	
	my $root = $app->root;
	
	$salt_file = $root->append ($salt_file)->as_file;
	my $salt;
	
	if (-f $salt_file and -r _) {
		my $perms = (stat $salt_file)[2];
		if ($perms & 044) {
			critical "can't use salt, because it readable by everyone";
		}
		$salt = $salt_file->contents;
	} else {
		debug "generating salt";
		my $digest = Digest::MD5->new;
		$digest->add ("$salt_file");
		$digest->add (time);
		$digest->add ("$app");
		$digest->add ("$root");
		$salt_file->store ($digest->hexdigest)
			|| critical "you must initialize salt, file '$salt_file' not writable";
		chmod (0600, $salt_file);
	}
	
	has 'salt', global => 1, is => 'ro', default => $salt;
	debug "salt ok";
	
	foreach my $provider (qw(request account)) {
		my $method = "${provider}_provider";
		my $pack = $self->{$method};
		
		critical "can't use undefined $provider provider"
			unless $pack;
		
		my $t = timer ("$provider provider ($pack) start");
		
		critical "can't use $provider provider: $pack is unusable ($@)"
			unless try_to_use ($pack);
		
		$t->end;
		
		has $method, default => $pack;
	}
	
	has 'entity', default => $self->{entity};
}

sub new {
	my $class  = shift;
	my $params = shift || {};
	
	$class = ref $class || $class;
	
	bless $params, $class;
}

# 

sub detect {
	my $class = shift;
	my $self = $class->new;

	my $app = Web::App->app;
	$app->{session} = $self;
	
	# hack for no real session
	return unless $self->can ('request_provider');
	
	my $r_provider = $self->request_provider;
	my $accountant = $self->account_provider;
	
	my $t = timer ('session detection');
	
	my @session_data = $r_provider->detected_session ($self->entity);
	
	$t->end;
	
	return unless scalar @session_data;
	
	my $session_id = $session_data[0];
	
	return unless $session_id;
	
	$t = timer ('session validation');
	
	my $is_valid = $accountant->session_valid (@session_data);
	
	$t->end;
	
	return unless $is_valid;
	
	$self->id ($session_id);
	
	my $user = $self->user;
	
	if (defined $user) {
		$app->var->{session_user} = $user;
	}
	
	debug "all ok";
}

sub create {
	my $self  = shift;
	my $app    = shift;
	my $params = shift;
	
	my $request = $app->request;
	
	if (0 && $self->id) {
		$app->redirect_to_screen ($request->params->param ('referer') || '');
		return;
	}
	
	my $r_provider = $self->request_provider;
	my $accountant = $self->account_provider;
	
	my @session = $accountant->retrieve_session ($self->id);
	
	unless (scalar @session) {
		debug "can't create auth";
		return;
	} 
	
	$r_provider->save ($self->entity, @session)
		if $session[0];
	
	$app->redirect_to_screen ($request->params->param ('referer') || '');
	
	return;
}

sub finish {
	my $self = shift;

	my $r_provider = $self->request_provider;
	my $accountant = $self->account_provider;
	
	my @session_data = $r_provider->detected_session ($self->entity);
	return unless scalar @session_data;
	
	$r_provider->remove ($self->entity);
	if ($accountant->can ('finish_session')) {
		$accountant->finish_session (@session_data);
	}
	
	my $app = Web::App->app;
	
	$app->redirect_to_screen ('');
}

sub check_user {
	my $class = shift;
	my $app   = shift;

	my $instance = Web::App::Library::SharedWork::Core->instance;
	my $self = $instance->{'auth'};
	
	my $cookies = CGI::Cookie->fetch;
	my $request = $app->request;
	
	my $cookie  = $cookies->{'user'};
	
	return unless defined $cookie;
	
	debug "cookie value is: '$cookie'";
	
	my ($user, $expires, $hash) = split (':', $cookie->value);
	
	my $chunk  = "$user:$expires";
	my $digest_string = $self->{'salt'}.$chunk;
	
	if (Digest::MD5::md5_hex ($digest_string) eq $hash) {
		$request->{'user'} = $user;
		debug "user is: '$user'";
	}
	
	$class->save_cookie ($app);
	
}


sub save_cookie {
	my $class = shift;
	my $app  = shift;
	
	my $instance = Web::App::Library::SharedWork::Core->instance;
	my $self = $instance->{'auth'};
	
	my $request = $app->request;
	my $user    = $request->{'user'};
	
	my $expires  = time + 60*60; # one hour
	my $hex_expires = sprintf '%x', $expires; 
	
	# now we encrypt cookie
	my $chunk  = "$user:$hex_expires";
	my $digest_string = $self->{'salt'}.$chunk;
		
	my $cookie = CGI::Cookie->new (
		-name  => 'user',
		-value => $chunk.':'.Digest::MD5::md5_hex ($digest_string),
		-expires => '+10y',
	);
	
	push @{$app->response->headers}, "Set-Cookie: $cookie";
}

sub login {
	my $class = shift;
	my $app   = shift;
	
	my $instance = Web::App::Library::SharedWork::Core->instance;
	my $self = $instance->{'auth'};
	my $users = $instance->{'users'};
	
	$self->init;
	
	my $request = $app->request;
	my $params  = $request->params;
	
	my $password = $users->passwd ($params->param ('email'));
	
	if (not defined $password or $password ne $params->param ('password')) {
		debug "passwords is: request '", $params->param ('password'), "' stored: '$password' ";
		$app->redirect_to_screen ('forgot-password/'.$params->param('referer'));
		$app->clear_process_queue;
	}
	
	$request->{'user'} = $params->param ('email');
}

sub redirect_fix {
	my $class = shift;
	my $app   = shift;
	
	my $referer = $app->request->params->param ('referer');
	$referer = ''
		unless defined $referer;
	
	$app->redirect_to_screen ($referer);
}

sub logoff {
	my $class = shift;
	my $app   = shift;
	
	my $cookie = CGI::Cookie->new (
		-name  => 'user',
		-value => '',
		-expires => scalar localtime 0,
	);

	push @{$app->internals->{'headers-out'}}, "Set-Cookie: $cookie";
	$app->redirect_to_screen ('');

}

1;