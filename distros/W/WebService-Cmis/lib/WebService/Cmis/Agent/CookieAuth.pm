package WebService::Cmis::Agent::CookieAuth;

=head1 NAME

WebService::Cmis::Agent::CookieAuth - cookie-based authentication handler

=head1 DESCRIPTION

This user agent allows to remain logged in based on cookie information returned by the server.

  my $client = WebService::Cmis::getClient(
    url => "http://localhost:8080/nuxeo/atom/cmis",
    useragent => new WebService::Cmis::Agent::CookieAuth(
      user => "user",
      password => "password",
      loginUrl => "http://localhost:8080/nuxeo/nxstartup.faces",
      cookieDir => "/tmp",
    )
  );
  
  my $cookie = $client->login;
  my $repo = $client->getRepository;

Parent class: L<WebService::Cmis::Agent>

=cut

use strict;
use warnings;

use WebService::Cmis::Agent ();
use URI ();
our @ISA = qw(WebService::Cmis::Agent);

use Error qw(:try);

=head1 METHODS

=over 4

=item new(%params)

Create a new WebService::Cmis::Agent::CookieAuth. 

Parameters:

=over 4

=item * user

=item * password

=item * loginUrl (defaults to the cmis client's atom endpoint)

=item * cookieDir (defaults to /tmp)

=back

See L<LWP::UserAgent> for more options.

=cut 

sub new {
  my ($class, %params) = @_;

  my $user = delete $params{user};
  my $password = delete $params{password};
  my $loginUrl = delete $params{loginUrl};
  my $cookieDir = delete $params{cookieDir} || "/tmp";

  my $this = $class->SUPER::new(%params);

  $this->{user} = $user;
  $this->{password} = $password;
  $this->{loginUrl} = $loginUrl;
  $this->{cookieDir} = $cookieDir;

  return $this;
}

=item login(%params) -> $cookie

logs in to the web service 

Parameters:

=over 4

=item * user 

=item * password

=item * cookie

=back

Login using basic auth or based on a cookie previously collected.

  my $cookie = $client->login({
    user => "user", 
    password => "pasword"
  });

  $client->login({
    cookie => $cookie
  });

=cut

sub login {
  my $this = shift;
  my %params = @_;

  $this->{cookie} = $params{cookie} if defined $params{cookie};
  $this->{user} = $params{user} if defined $params{user};
  $this->{password} = $params{password} if defined $params{password};

  $this->{loginUrl} = $this->{client}{repositoryUrl}
    unless defined $this->{loginUrl};

  throw Error::Simple("loginUrl undefined ... where do I get my cookies from")
    unless defined $this->{loginUrl};

  $this->_createCookieJar if defined $this->{user};

  if (defined $this->{cookie}) {
    #print STDERR "setting cookie\n";

    $this->cookie_jar->set_cookie(@{$this->{cookie}});

  } else {
    my @sig = $this->_getCookieSignarure;

    if ($this->_readCookie(@sig)) {
      #print STDERR "found cookie in jar\n";
      $this->{password} = undef;
    } else {
      #print STDERR "getting a new cookie\n";
      $this->{client}->request("GET", $this->{loginUrl});
      $this->_readCookie(@sig);

      # another request against the real endpoint
      $this->{client}->get;
    }

    #print STDERR "cookie=".join(", ", map {defined($_)?$_:'undef'} @{$this->{cookie}})."\n" if defined $this->{cookie};

    throw("No cookie found in response") unless defined $this->{cookie};
  }

  return $this->{cookie};
}

sub _getCookieSignarure {
  my $this = shift;

  my $uri = URI->new($this->{loginUrl});
  my $path = $uri->path;
  my $host = $uri->host;
  my $port = $uri->port;
  $path =~ s,/[^/]*$,,;
  $host .= ".local" unless $host =~ /\./;

  #print STDERR "path=$path, host=$host, path=$path\n";

  return ($host, $port, $path);
}

sub _createCookieJar {
  my $this = shift;

  my $cookieFile = $this->{cookieDir}."/cmiscookies-$this->{user}";
#   $cookieFile =~ /^(.*)/;
#   $cookieFile = $1; #untaint

  #print STDERR "using a cookie jar at $cookieFile\n";
  $this->cookie_jar({
    file => $cookieFile,
    autosave => 1,
    ignore_discard => 1,
  });
}

sub _readCookie {
  my ($this, $loginHost, $loginPort, $loginPath) = @_;

  #print STDERR "searching cookie for loginPath=$loginPath, loginHost=$loginHost, loginPort=".($loginPort||'undef')."\n";
  $this->{cookie} = undef;

  $this->cookie_jar->scan(
    sub {
      my ($version, $key, $val, $path, $domain, $port, $path_spec, $secure, $expires, $discard, $hash) = @_;
      #print STDERR "version=$version, key=$key, val=$val, path=$path, domain=$domain, port=".($port||'undef')."\n";
      if ($path eq $loginPath && $domain eq $loginHost && (!$port || $port eq $loginPort)) {
        #print STDERR "yep, found it\n";
        $this->{cookie} = [
          $version, $key, $val, $path, $domain, $port, $path_spec, $secure, $expires, $discard
        ];
      }
    }
  );

  return $this->{cookie};
}


=item logout() 

logs out of the web service deleting a cookie previously aquired

=cut

sub logout {
  my $this = shift;

  $this->{user} = undef;
  $this->{password} = undef;
  $this->{cookie} = undef;
  
  my $cookieJar = $this->cookie_jar;
  if ($cookieJar) {
    my ($host, $port, $path) = $this->_getCookieSignarure;
  
    #print STDERR "clearing cookie for $host, $path\n"; 
    $cookieJar->clear($host, $path);
  }
}

=item get_basic_credentials()

overrides the method in LWP::UserAgent to implement the given authentication mechanism.

=cut

sub get_basic_credentials {
  my $this = shift;

  #print STDERR "called get_basic_credentials\n";

  return ($this->{user}, $this->{password});
}

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2012-2013 Michael Daum

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  See F<http://dev.perl.org/licenses/artistic.html>.

=cut

1;

