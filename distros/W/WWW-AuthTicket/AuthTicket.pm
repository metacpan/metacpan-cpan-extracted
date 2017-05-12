package WWW::AuthTicket;

=pod

=head1 NAME

AuthTicket.pm

=head1 SYNOPSIS

Handle authorization for web services or restricted areas of a website.

This object oriented module is meant to be sub-classed.

=head1 USAGE

Keep in mind that you'll want to create your own class that inherits this one.
See the SUB-CLASSING EXAMPLE section below.

use WWW::AuthTicket;

my $auth = WWW::AuthTicket->new(-env => \%ENV, -secret_key => '[ABC123]');

my ($auth_ok, $msg) = $auth->verify_auth_cookie();

unless ($auth_ok) {

	## send to log in screen (problem described in $msg)

}

my ($successful, $msg) = $auth->authenticate_user($username, $password);

if ($successful) {

	print "Set-Cookie: " . $auth->issue_auth_cookie() . "\n";

}
else {

	## failure reason in $msg

}

## log out

print "Set-Cookie: " . $auth->void_auth_cookie() . "\n";

=head1 METHODS

=over

=cut

use strict;
use CGI::Cookie;
use Digest::SHA1 qw(sha1_hex);
use vars qw($VERSION);

$VERSION = 0.01;

use constant TRUE => 1;
use constant FALSE => !TRUE;

use constant DEFAULT_SECRET_KEY => '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
use constant DEFAULT_COOKIE_NAME => 'auth';
use constant RET_ADDR_COOKIE_NAME => 'requesturi';
use constant NEVER_EXPIRES => '0E0';
use constant HTTP_DEFAULT_PORT => '80';

=pod

=item new()

Object constructor. Specify parameters as key/value pairs. Possible keys are:

=over

=item -env (required)

A reference to the %ENV hash

=item -secret_key (optional, but recommended)

A string of any length for the hashing algorithm

=item -auth_expires (optional)

Length of time in minutes before the authorization should expire
(default is no expiration, just the end of the browser's session).
You would only need to specify this parameter when you are going to
call C<issue_auth_cookie()> because this value gets embedded in the
cookie itself with C<issue_auth_cookie()>.

=item -cookie_name (optional)

If you want to call the cookie something other than the default name, "auth"

=item -cookie_domain (optional)

Use this to specify a domain for use in the cookie.
Default is to use the "SERVER_NAME" environment variable which makes the cookie
valid only for that particular host. You would specify a value here if you want
the cookie to be good for other hosts under your domain.

=back

my $auth = WWW::AuthTicket->new(-env => \%ENV, -secret_key => '*foobarbaz*');

=cut

sub new
{
	my $class = shift;
	my %args  = @_;

	my $env_href = $args{'-env'};

	die "Environment variable hash reference is missing" unless ref($env_href) eq 'HASH';
	die "Can't find client's IP address - \$ENV{REMOTE_ADDR} empty" unless $env_href->{REMOTE_ADDR};

	my $secret_key    = $args{'-secret_key'}    || DEFAULT_SECRET_KEY;
	my $auth_expires  = $args{'-auth_expires'}  || NEVER_EXPIRES;
	my $cookie_name   = $args{'-cookie_name'}   || DEFAULT_COOKIE_NAME;
	my $cookie_domain = $args{'-cookie_domain'} || $env_href->{SERVER_NAME};

	## truncated version of ip address to account for proxy servers
	(my $ip_trunc = $env_href->{REMOTE_ADDR}) =~ s/\d{1,3}$//;

	my %cookies = CGI::Cookie->parse($env_href->{'HTTP_COOKIE'});

	my $self = {
		'env'           => $env_href,
		'ip_truncated'  => $ip_trunc,
		'secret_key'    => $secret_key,
		'auth_expires'  => $auth_expires,
		'cookie_name'   => $cookie_name,
		'cookie_domain' => $cookie_domain,
		'cookies'       => \%cookies,
		'cookie_values' => {}, ## to be determined by authenticate_user()
		};

	return bless $self, $class;
}

=pod

=item authenticate_user()

Given a username/user ID and password, verifies the credentials and returns
a boolean for whether or not the verification was successful and a message
explaining any failure that might have occurred.

my ($successful, $msg) = $auth->authenticate_user($username, $password);

B<NOTE:> This module can (and should) be sub-classed in order to provide your own
customized authentication handling - like with a database. Values pulled from your
user database can be added to the authorization cookie and also extracted from it
after the cookie has been verified. See the C<get_cookie_value()> method.

=cut

sub authenticate_user
{
	warn "Using AuthTicket::authenticate_user() - this should not be used.",
		"AuthTicket should be sub-classed and authenticate_user() should be overridden by a customized method.";

	my ($self, $user, $pass) = @_;

	my ($success, $msg);

	if ($user eq 'test' && $pass eq 'test')
	{
		$success = TRUE;
		$self->add_cookie_value('userid' => 1);
	}
	else
	{
		$success = FALSE;
		$msg = "Invalid username or password";
	}

	return($success, $msg);
}

=pod

=item add_cookie_value()

Use this method to add name/value pairs you want included in the authorization cookie.
This method is useful for inclusion in your own C<authenticate_user()> method that you
create when you sub-class the AuthTicket class. Use it to save user-specific info that you
pull back from your user database so that you don't have to look it up in the database
for every request the user sends.

my $num_added = $self->add_cookie_value('userid' => $uid, 'authlevel' => $authlevel, ...);

It can return the number of values added for checking, but that is optional.
You could just call it in a void context.

These values can then be retreived from the cookie using the C<get_cookie_value()> method.

=cut

sub add_cookie_value
{
	my $self = shift;
	my %cookies = @_;

	my $count = 0;

	foreach my $key (keys %cookies)
	{
		$self->{'cookie_values'}->{$key}  = $cookies{$key};
		$count++;
	}

	return $count if defined wantarray;
}

=pod

=item get_cookie_value()

Returns the value from the specified part of the authorization cookie -
C<verify_auth_cookie()> method must be called first.

my $userid = $auth->get_cookie_value('userid'); # example

=cut

sub get_cookie_value
{
	my ($self, $value_name) = @_;
	warn "AuthTicket::get_cookie_value() - '$value_name' does not exist" unless exists $self->{'cookie_values'}->{$value_name};
	return $self->{'cookie_values'}->{$value_name};
}

=pod

=item issue_auth_cookie()

Returns a C<CGI::Cookie>-formatted cookie. Use after C<authenticate_user()> returns successful.

print "Set-Cookie: " . $auth->issue_auth_cookie() . "\n";

=cut

sub issue_auth_cookie
{
	my $self = shift;

	my %cookie_values = %{$self->{'cookie_values'}};

	$cookie_values{'ip'}      = $self->{'ip_truncated'};
	$cookie_values{'time'}    = time();
	$cookie_values{'expires'} = $self->{'auth_expires'};

	my @hash_these;
	push @hash_these, $cookie_values{$_} for (sort keys %cookie_values);

	my $hash = sha1_hex($self->{'secret_key'} . sha1_hex(join(':', $self->{'secret_key'}, @hash_these)));
	$cookie_values{'hash'} = $hash;

	return CGI::Cookie->new(
		-name   => $self->{'cookie_name'},
		-path   => '/',
		-domain => $self->{'cookie_domain'},
		-value  => \%cookie_values,
		);
}

=pod

=item void_auth_cookie()

Returns a C<CGI::Cookie>-formatted cookie that deletes the auth cookie. Use for logging a user out.

print "Set-Cookie: " . $auth->void_auth_cookie() . "\n";

=cut

sub void_auth_cookie
{
	my $self = shift;
	return CGI::Cookie->new(
		-name    => $self->{'cookie_name'},
		-path    => '/',
		-domain  => $self->{'cookie_domain'},
		-value   => '',
		-expires => '-1M',
		);
}

=pod

=item verify_auth_cookie()

Parses and verifies the authorization cookie. Returns a boolean for whether or not the
verification was successful and a message explaining any failure that might have occurred.

my ($auth_ok, $msg) = $auth->verify_auth_cookie();

=cut

sub verify_auth_cookie
{
	my $self = shift;

	return(FALSE, 'no cookie') unless exists $self->{'cookies'}->{$self->{'cookie_name'}};

	my %auth_cookie = $self->{'cookies'}->{$self->{'cookie_name'}}->value;

	return(FALSE, 'malformed cookie')
		unless $auth_cookie{'hash'} && $auth_cookie{'ip'}
		&& $auth_cookie{'time'} && length($auth_cookie{'expires'});

	return(FALSE, 'IP address mismatch') if $auth_cookie{'ip'} ne $self->{'ip_truncated'};

	return(FALSE, 'authorization has expired') if _auth_expired(\%auth_cookie);

	my $hash = delete $auth_cookie{'hash'};

	my @hash_these;
	push @hash_these, $auth_cookie{$_} for (sort keys %auth_cookie);

	my $new_hash = sha1_hex($self->{'secret_key'} . sha1_hex(join(':', $self->{'secret_key'}, @hash_these)));

	return(FALSE, 'hash mismatch - cookie value possibly tampered with') if $new_hash ne $hash;

	$self->{'auth_expires'} = $auth_cookie{'expires'};

	while (my ($k, $v) = each %auth_cookie)
	{
		$self->{'cookie_values'}->{$k} = $v;
	}

	return(TRUE, '');
}

=pod

=item make_return_address()

Returns a C<CGI::Cookie>-formatted cookie that contains the URI the user is trying to access.
Here's how to use this: say a user is trying to access a URI that requires them to be logged
in, but they are either not logged in or their login has expired. Use this to save the URI for
the page they were trying to access so that after they log in you can send them where they
were trying to go before they were interrupted with the log-in process.

print "Set-Cookie: " . $auth->make_return_address() . "\n";

=cut

sub make_return_address
{
	my $self = shift;

	my $uri = 'http://' . $self->{'env'}->{'SERVER_NAME'}
		. ($self->{'env'}->{'SERVER_PORT'} ne HTTP_DEFAULT_PORT ? ':'.$self->{'env'}->{'SERVER_PORT'} : "")
		. $self->{'env'}->{'REQUEST_URI'};

	return CGI::Cookie->new(
		-name   => RET_ADDR_COOKIE_NAME,
		-value  => $uri,
		-domain => $self->{'cookie_domain'},
		-path   => '/'
		);
}

=pod

=item get_return_address()

Returns the URI from the cookie set with C<make_return_address()>.

my $requested_uri = $auth->get_return_address();

=cut

sub get_return_address
{
	my $self = shift;
	return $self->{'cookies'}->{RET_ADDR_COOKIE_NAME()};
}

=pod

=item clear_return_address()

Returns a C<CGI::Cookie>-formatted cookie that deletes the return address
cookie that was set with C<make_return_address()>. Use after a successful log
in so that the user doesn't get redirected to the saved URI over and over again.

print "Set-Cookie: " . $auth->clear_return_address() . "\n";

=cut

sub clear_return_address
{
	my $self = shift;
	return CGI::Cookie->new(
		-name    => RET_ADDR_COOKIE_NAME,
		-value   => '',
		-domain  => $self->{'cookie_domain'},
		-path    => '/',
		-expires => '-1M',
		);
}

sub _auth_expired
{
	my $auth_cookie_href = shift;
	return FALSE if $auth_cookie_href->{'expires'} eq NEVER_EXPIRES;
	return FALSE if _to_minutes(time - $auth_cookie_href->{'time'}) < $auth_cookie_href->{'expires'};
	return TRUE;
}

sub _to_minutes
{
	my $seconds = shift;
	return $seconds / 60;
}

1;

__END__

=pod

=back

=head1 SUB-CLASSING EXAMPLE

package MyAuthTicket;

use strict;

use vars qw(@ISA);

use WWW::AuthTicket;

@ISA = ("WWW::AuthTicket");

## add or override methods here

sub authenticate_user {

...

}

1;

Then use MyAuthTicket instead of AuthTicket. All methods from AuthTicket are now available
in MyAuthTicket plus whatever you add to MyAuthTicket.

use MyAuthTicket;

my $auth = MyAuthTicket->new(-env => \%ENV, -secret_key => '*foobarbaz*');

...

=head1 DEPENDENCIES

=over

=item CGI::Cookie

=item Digest::SHA1

=head1 BUGS

None known.

=head1 ACKNOWLEDGEMENTS

This is kind of a hacked up version the TicketTool module in
_Writing_Apache_Modules_with_Perl_and_C_ by Lincoln Stein & Doug MacEachern (O'Reilly)

=head1 AUTHOR

John Winger (john 2 wingeronline. com)

=head1 COPYRIGHT

(c) 2007 John W. Winger III.

This program is free software. You may copy or redistribute it under the same terms as Perl itself.

=cut
