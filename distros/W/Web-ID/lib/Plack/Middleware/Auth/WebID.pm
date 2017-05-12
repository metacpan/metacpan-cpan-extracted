package Plack::Middleware::Auth::WebID;

{
	$Plack::Middleware::Auth::WebID::AUTHORITY = 'cpan:TOBYINK';
	$Plack::Middleware::Auth::WebID::VERSION   = '1.927';
}

use strict;
use base qw(Plack::Middleware);
use Plack::Util;;
use Plack::Util::Accessor qw(
	webid_class
	certificate_env_key
	on_unauth
	no_object_please
	cache
);

my $default_unauth = sub
{
	my ($self, $env) = @_;
	$env->{WEBID}        = Plack::Util::FALSE;
	$env->{WEBID_OBJECT} = Plack::Util::FALSE;
	$self->app->($env);
};

sub prepare_app
{
	my ($self) = @_;
	
	$self->certificate_env_key('SSL_CLIENT_CERT')
		unless defined $self->certificate_env_key;
	
	$self->webid_class('Web::ID')
		unless defined $self->webid_class;
	
	$self->on_unauth($default_unauth)
		unless defined $self->on_unauth;
	
	Plack::Util::load_class('Web::ID');
}

sub call
{
	my ($self, $env) = @_;
	my $unauth = $self->on_unauth;
	
	my $cert  = $env->{ $self->certificate_env_key }
		or return $self->$unauth($env);
	
	my ($webid, $was_cached) = $self->_get_webid($cert, $env);
	
	if ($webid->valid)
	{
		$env->{WEBID}           = $webid->uri . '';
		$env->{WEBID_OBJECT}    = $webid unless $self->no_object_please;
		$env->{WEBID_CACHE_HIT} = $was_cached;
		
		return $self->_run_app($env);
	}
	
	return $self->$unauth($env);
}

sub _run_app
{
	my ($self, $env) = @_;
	my $app = $self->app;
	@_ = $env;
	goto $app;
}

sub _get_webid
{
	my ($self, $cert) = @_;
	
	my $webid = $self->webid_class->new(certificate => $cert);
	return ($webid, '') unless $self->cache;

	# I know what you're thinking... what's the point in caching these
	# objects, if we're already constructed it above?!
	#
	# Well, much of the heavy work for Web::ID is done in lazy builders.
	# If we return a cached copy of the object, then we avoid running
	# those builders again.
	#
	my $cached = $self->cache->get( $webid->certificate->fingerprint );
	return ($cached, '1') if $cached;
	
	$self->cache->set($webid->certificate->fingerprint, $webid);
	return ($webid, '0');
}

__PACKAGE__
__END__

=head1 NAME

Plack::Middleware::Auth::WebID - authentication middleware for WebID

=head1 SYNOPSIS

  use Plack::Builder;
  
  my $app   = sub { ... };
  my $cache = CHI->new( ... );
  
  sub unauthenticated
  {
    my ($self, $env) = @_;
    return [
      403,
      [ 'Content-Type' => 'text/plain' ],
      [ '403 Forbidden' ],
    ];
  }
  
  builder
  {
    enable "Auth::WebID",
        cache     => $cache,
        on_unauth => \&unauthenticated;
    $app;
  };

=head1 DESCRIPTION

Plack::Middleware::Auth::WebID is a WebID handler for Plack.

If authentication is successful, then the handler sets C<< $env->{WEBID} >>
to the user's WebID URI, and sets C<< $env->{WEBID_OBJECT} >> to a
L<Web::ID> object.

=begin private

=item call

=item prepare_app

=end private

=head1 CONFIGURATION

=over 4

=item cache

This may be set to an object that will act as a cache for Web::ID
objects. 

Plack::Middleware::Auth::WebID does not care what package you use for
your caching needs. L<CHI>, L<Cache::Cache> and L<Cache> should all
work. In fact, any package that provides a similar one-argument C<get>
and a two-argument C<set> ought to work. Which should you use? Well
CHI seems to be best, however it's Moose-based, so usually too slow
for CGI applications. Use Cache::Cache for CGI, and CHI otherwise.

You don't need to set a cache at all, but if there's no cache, then
reauthentication (which is computationally expensive) happens for
every request. Use of a cache with an expiration time of around 15
minutes should significantly speed up the responsiveness of a
WebID-secured site. (For forking servers you probably want a cache
that is shared between processes, such as a memcached cache.)

=item on_unauth

Coderef that will be called if authentication is not successful. You
can use this to return a "403 Forbidden" page for example, or try an
alternative authentication method.

The default coderef used will simply run the application as normal,
but setting C<< $env->{WEBID} >> to the empty string.

=item webid_class

Name of an alternative class to use for WebID authentication instead
of L<Web::ID>. Note that any such class would need to provide a compatible
C<new> constructor.

=item certificate_env_key

The key within C<< $env >> where Plack::Middleware::Auth::WebID can find
a PEM-encoded client SSL certificate.

Apache keeps this information in C<< $env->{'SSL_CLIENT_CERT'} >>, so
it should be no surprise that this setting defaults to 'SSL_CLIENT_CERT'.

=item no_object_please

Suppresses setting C<< $env->{WEBID_OBJECT} >>. C<< $env->{WEBID} >> will
still be set as usual.

=back

=head1 SERVER SUPPORT

WebID is an authentication system based on the Semantic Web and HTTPS.
It relies on client certificates (but not on certification authorities;
self-signed certificates are OK).

So for this authentication module to work...

=over

=item * You need to be using a server which supports HTTPS.

Many web PSGI web servers (e.g. HTTP::Server::Simple, Starman, etc) do
not support HTTPS natively. In some cases these are used with an HTTPS
proxy in front of them.

=item * Your HTTPS server needs to request a client certificate from the client.

=item * Your HTTPS server needs to expose the client certificate to Plack via C<< $env >>.

If you're using an HTTPS proxy in front of a non-HTTPS web server,
then you might need to be creative to find a way to forward this
information to your backend web server.

=item * The client browser needs to have a WebID-compatible certificate installed.

Nuff said.

=back

=head2 Apache2 (mod_perl and CGI)

The B<SSLVerifyClient> directive can be used to tell Apache that you want it
to request a certificate from the client.

Apache is able to deposit the certifcate in an environment variable called
SSL_CLIENT_CERT. However by default it might not. Check out the B<SSLOptions>
directive and enable the C<ExportCertData> option, or if you're using mod_perl
try L<Plack::Middleware::Apache2::ModSSL>.

=head2 Gepok

L<Gepok> is one of a very small number of PSGI-compatible web servers that
supports HTTPS natively. As of 0.20 it will request client certificates, but
you will need to use L<Plack::Middleware::GepokX::ModSSL> in order to make
the certificate available in the PSGI C<< $env >> hashref.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Web-ID>.

=head1 SEE ALSO

L<Plack>, L<Web::ID>, L<Web::ID::FAQ>.

General WebID information:
L<http://webid.info/>,
L<http://www.w3.org/wiki/WebID>,
L<http://www.w3.org/2005/Incubator/webid/spec/>,
L<http://lists.foaf-project.org/mailman/listinfo/foaf-protocols>.

Apache mod_ssl:
L<Plack::Middleware::Apache2::ModSSL>,
L<Apache2::ModSSL>,
L<http://httpd.apache.org/docs/2.0/mod/mod_ssl.html>.

Gepok:
L<Gepok>,
L<Plack::Middleware::GepokX::ModSSL>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

