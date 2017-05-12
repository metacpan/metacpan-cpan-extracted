package Web::App::Request::CGI;

use Class::Easy;
use Encode qw/encode decode decode_utf8/;

use Web::App::Request;
use base qw(Web::App::Request);

use CGI::Minimal;

##########################################################
############### FORM PROCESSING STUFF ####################
##########################################################

sub ok {
	my $self = shift;
	
	return 1;
}

# this code called every request
sub _init {
	my $self = shift;
	
	my $path_info = $ENV{'PATH_INFO'};
	my $base_uri  = $ENV{'SCRIPT_NAME'};
	
	my $uri       = "$base_uri$path_info";
	
	$self->set_field_values (
		host      => $ENV{'HTTP_HOST'},
		uri       => $uri,
		base_uri  => $base_uri,
		path      => $path_info,
		unparsed_uri => $ENV{'REQUEST_URI'},
	);
}

sub send_headers {
	my $self = shift;
	my $headers = shift;
	
	print $headers->as_string, "\n";
}

sub auth_cookie {
	my $self = shift;
	
	my $cookies = CGI::Cookie->fetch;
	
	my $cookie  = $cookies->{'user'};
	
	return unless defined $cookie;
	
	debug "cookie value is: '$cookie'";
	
	return $cookie;
	
	my ($user, $expires, $hash) = split (':', $cookie->value);
	
	my $chunk  = "$user:$expires";
	my $digest_string = $self->{'salt'}.$chunk;
	
	if (Digest::MD5::md5_hex ($digest_string) eq $hash and time < hex $expires) {
		#$request->{'user'} = $user;
		debug "user is: '$user'";
	} else {
		# $app->var->{'auth'} = 'session-expired';
		debug "hash for '$digest_string': received '$hash', but wait for: ", Digest::MD5::md5_hex ($digest_string);
	}
}

1;
