package WWW::Instapaper::Client;
use strict; use warnings;
use constant PACKAGE_VERSION => '0.1';
use constant DEBUG => 1;

use base 'Class::Base';
use LWP::UserAgent;
use HTTP::Request::Common 'POST';
# local %ENV;

our $VERSION = '0.901';

sub init {
	my ($self, $config) = @_;
	my %default;
	# my $package = shift;
	# my %config  = @_;
	# my ($self, %default);
	
	%default = (
		agent_string    => 'WWW-Instapaper-Client/'.PACKAGE_VERSION,
		api_url         => 'https://www.instapaper.com/api',
		http_proxy      => $ENV{HTTP_PROXY},
		http_proxyuser  => $ENV{HTTP_PROXY_USERNAME},
		http_proxypass  => $ENV{HTTP_PROXY_PASSWORD},
		username        => $ENV{instapaper_user},
		password        => $ENV{instapaper_pass},
	);
	
	# $self = bless \%default, $package;
	## make sure defaults are loaded
	for (keys %default) { $self->{$_} = $default{$_} }
	
	for (keys %$config) {
		die "Invalid parameter '$_'" unless exists $self->{$_};
		$self->{$_} = $config->{$_};
	}
	
	
	
	$self->{_ua} = LWP::UserAgent->new(
		agent => $self->{agent_string},
	);
	
	## remember, this is the LOCALIZED %ENV variable - won't change live environment.
	$ENV{HTTPS_PROXY}          = (defined $self->{http_proxy} ? $self->{http_proxy} : $ENV{HTTP_PROXY});
	$ENV{HTTPS_PROXY_USERNAME} = (defined $self->{http_proxyuser} ? $self->{http_proxyuser} : $ENV{HTTP_PROXY_USERNAME});
	$ENV{HTTPS_PROXY_PASSWORD} = (defined $self->{http_proxypass} ? $self->{http_proxypass} : $ENV{HTTP_PROXY_PASSWORD});
	$ENV{HTTP_PROXY}           = (defined $self->{http_proxy} ? $self->{http_proxy} : $ENV{HTTP_PROXY});
	$ENV{HTTP_PROXY_USERNAME}  = (defined $self->{http_proxyuser} ? $self->{http_proxyuser} : $ENV{HTTP_PROXY_USERNAME});
	$ENV{HTTP_PROXY_PASSWORD}  = (defined $self->{http_proxypass} ? $self->{http_proxypass} : $ENV{HTTP_PROXY_PASSWORD});
		
	# if (defined $self->{http_proxy)) {
		# my $proxy_url = $self->{http_proxy};
		# if (defined $self->{http_proxyuser}) {
			# my $authstr = $self->{http_proxyuser};
			# $authstr .= ":".$self->{http_proxypass} if defined $self->{http_proxypass};
			# $proxy_url =~ s{(\w+?:)//}{$1//$authstr\@};
			# warn "Updated Proxy URL to '$proxy_url'" if DEBUG;
		# }
		# $self->{_ua}->proxy(['http','https'], $proxy_url);
	# }
	
	return $self;
}

sub authenticate {
	my $self = shift;
	my $req = POST 
		$self->{api_url}.'/authenticate', 
		['username'=>$self->{username}, 'password'=>$self->{password}];
		
	my $response = $self->{_ua}->request($req);
	
	return 1 if ($response->is_success);
	
	return $self->error('Bad username or password')    if ($response->code == 403);
	return $self->error('Error with service or proxy') if ($response->code == 500);
	
	return $self->error("Unknown error condition: ".$response->code);  ## undefine error
}

sub add {
	my $self = shift;
	my %param = @_;
	
	unless (exists $param{title}) { $param{'auto-title'} = 1 }
	return $self->error("No URL provided") unless (defined $param{url});
	
	$param{username} = $self->{username};
	$param{password} = $self->{password};
	
	my $req = POST $self->{api_url}.'/add', [ %param ];
	my $response = $self->{_ua}->request($req);
	
	return [$response->header('Content-Location'), $response->header('X-Instapaper-Title')]
		if ($response->is_success);

	return $self->error('Bad username or password')    if ($response->code == 403);
	return $self->error('Error with service or proxy') if ($response->code == 500);
	return $self->error('Malformed request')           if ($response->code == 400);
	
	return $self->error("Unknown error condition: ".$response->code);  ## undefine error
}

1;

__END__

=head1 NAME

WWW::Instapaper::Client - An implementation of the Instapaper client API
(see L<http://www.instapaper.com/api>)

=head1 SYNOPSIS

	require WWW::Instapaper::Client;
	
	my $paper = WWW::Instapaper::Client->new(
		username        => 'myname@mydomain.com', # E-mail OR username
		password        => 'SooperSekrit',
	);
	
	my $result = $paper->add(
		url   => 'http://some.domain/path/to/page.html',
		title => "Page Title",  # optional, will try to get automatically if not given
		selection => 'Some text on the page', #optional
	);
	
	if (defined $result) {
		print "URL added: ", $result->[0], "\n";  # http://instapaper.com/go/######
		print "Title: ", $result->[1], "\n";      # Title of page added
	}
	else {
		# Must be an error
		warn "Was error: " . $paper->error . "\n";
	}

=head1 DESCRIPTION

This module is an implementation of the Instapaper API.

=over 8

=item C<new>

	my $paper = WWW::Instapaper::Client->new( %parameters );

Returns a new instance of this class, configured with the appropriate parameters. Dies
if invalid parameters are provided.

Possible parameters are:

=over 8

=item user_agent

The user agent ("browser") the server will see. Defaults to C<WWW-Instapaper-Client/$VERSION>. 

=item username

The Instapaper username. Often, but not always, an e-mail address. Defaults to C<$ENV{instapaper_user}>

=item password

The password for the user's Instapaper account. The user may not have a password, in which case, any
value works.  Defaults to C<$ENV{instapaper_pass}>

=item api_url

The base URL for the Instapaper API. Defaults to C<https://www.instapaper.com/api>. You shouldn't need
to change this unless you're connecting to a non-Instapaper service that uses the same API.

=item http_proxy, http_proxyuser, http_proxypass

The path to an HTTPS-capable proxy, and the username and password as appropriate. The standard HTTP_PROXY
set of environment variables will work here; these are widely documented.  You only need to specify these
if you have a proxy B<AND> you don't have the environment variables set.

=back

=item C<add>

	my $result = $paper->add(
		url       =>  'http://path.to/page',  # required
		title     =>  'Page title',           # optional
		selection =>  'Text from page',       # optional
	);
	
	if (defined $result) {
		print "URL added: ", $result->[0], "\n";  # http://instapaper.com/go/######
		print "Title: ", $result->[1], "\n";      # Title of page added
	}
	else {
		# Must be an error
		warn "Was error: " . $paper->error . "\n";
	}

Adds the specified page URL to Instapaper. If a title is not provided, Instapaper will attempt to
acquire the title by retrieving the page; that is, we set C<auto-title = 1> for the Instapaper API
when a title is not provided.

You may optionally provide text that represents a selection from the page.

If successful, C<add> will return an ARRAYref containing the Instapaper "go" URL, and the page title
as recorded by Instapaper.

If an error is encountered, C<add> returns undefined and the error message is available in
C<$paper->error()>.

=item C<authenticate>

	$paper->authenticate or warn "Could not authenticate: ".$paper->error."\n";

Authenticates the user to Instapaper. This is useful to check that the credentials are valid before
e.g. storing them for later use.

If successful, C<authenticate> will return a true value.

If an error is encountered, C<authenticate> returns undefined and the error message is available in
C<$paper->error()>.

=back

=head1 CHANGELOG

=item Release 0.9_001

Fixed dependency bug in Build.PL - forgot that Class::Base was required.

=head1 AUTHOR

Darren Meyer - DPMEYER on PAUSE

=head1 COPYRIGHT

(c) 2010 Darren Meyer (DPMEYER on PAUSE), and available under the same terms as Perl itself.

=cut
