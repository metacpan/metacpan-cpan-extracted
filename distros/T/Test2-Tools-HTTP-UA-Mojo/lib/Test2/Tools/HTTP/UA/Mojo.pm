package Test2::Tools::HTTP::UA::Mojo;

use strict;
use warnings;
use 5.016;
use parent 'Test2::Tools::HTTP::UA';

# ABSTRACT: Mojo user agent wrapper for Test2::Tools::HTTP
our $VERSION = '0.05'; # VERSION


sub new
{
  my $class = shift;

  # we want to require tese on demand here when the wrapper gets
  # created rather than use them up at the top, because this .pm
  # gets used every time Test2::Tool::HTTP::UA gets used, even
  # if we aren't using Mojolicious in the .t file.
  require Mojolicious;
  require Mojo::URL;
  require IO::Socket::INET;
  require HTTP::Request;
  require HTTP::Response;
  require HTTP::Message::PSGI;
  require Test2::Tools::HTTP::UA::Mojo::Proxy;

  $class->SUPER::new(@_);
}

sub instrument
{
  my($self) = @_;

  if($self->ua->server->app)
  {
    $self->apps->base_url($self->ua->server->url->to_string);
  }

  my $proxy_psgi_app = sub {
    my $env = shift;

    my $app = $self->apps->uri_to_app($env->{REQUEST_URI});
    $app
      ? $app->($env)
      : [ 404, [ 'Content-Type' => 'text/plain' ], [ '404 Not Found' ] ];
  };

  my $proxy_mojo_app = Mojolicious->new;
  $proxy_mojo_app->plugin('Mojolicious::Plugin::MountPSGI' => { '/' => $proxy_psgi_app });

  my $proxy_url = Mojo::URL->new("http://127.0.0.1");
  $proxy_url->port(do {
    IO::Socket::INET->new(
      Listen    => 5,
      LocalAddr => '127.0.0.1',
    )->sockport;
  });

  my $proxy_mojo_server = $self->{proxy_mojo_server} = Mojo::Server::Daemon->new(
    ioloop => $self->ua->ioloop,
    silent => 1,
    app    => $proxy_mojo_app,
    listen => ["$proxy_url"],
  );
  $proxy_mojo_server->start;

  my $old_proxy = $self->ua->proxy;
  my $new_proxy = Test2::Tools::HTTP::UA::Mojo::Proxy->new(
    apps           => $self->apps,
    http           => $old_proxy->http,
    https          => $old_proxy->https,
    not            => $old_proxy->not,
    apps_proxy_url => $proxy_url,
  );

  $self->ua->proxy($new_proxy);
}

sub request
{
  my($self, $req, %options) = @_;

  require Mojo::Transaction::HTTP;
  require Mojo::Message::Request;

  # Add the User-Agent header to the HTTP::Request
  # so that T2::T::HTTP can see it in diagnostics
  $req->header('User-Agent' => $self->ua->transactor->name)
    unless $req->header('User-Agent');

  my $mojo_req = Mojo::Message::Request->new;
  $mojo_req->parse($req->to_psgi);
  $mojo_req->url(Mojo::URL->new($req->uri.''))
    if $req->uri !~ /^\//;

  my $tx = Mojo::Transaction::HTTP->new(req => $mojo_req);

  my $res;

  if($options{follow_redirects})
  {
    my $error;
    $self->ua->start_p($tx)->then(sub {
      my $tx = shift;
      $res = HTTP::Response->parse($tx->res->to_string);
      $res->request(HTTP::Request->parse($tx->req->to_string));
    })->catch(sub {
      $error = shift;
    })->wait;
    $self->error("connection error: $error") if $error;
  }
  else
  {
    $self->ua->start($tx);
    my $err = $tx->error;
    if($err && !$err->{code})
    {
      $self->error("connection error: " . $err->{message});
    }
    $res = HTTP::Response->parse($tx->res->to_string);
    $res->request($req);
  }

  # trim weird trailing stuff
  my $message = $res->message;
  $message =~ s/\s*$//;
  $res->message($message);

  $res;
}

__PACKAGE__->register('Mojo::UserAgent', 'instance');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Tools::HTTP::UA::Mojo - Mojo user agent wrapper for Test2::Tools::HTTP

=head1 VERSION

version 0.05

=head1 SYNOPSIS

 use Test2::Tools::HTTP;
 use Mojo::UserAgent;
 
 http_ua( Mojo::UserAgent->new )
 
 http_request(
   GET('http://example.test'),
   http_response {
     http_code 200;
     http_response match qr/something/;
     ...
   }
 );;
 
 done_testing;

=head1 DESCRIPTION

This module is a user agent wrapper for L<Test2::Tools::HTTP> that allows you
to use L<Mojo::UserAgent> as a user agent for testing.

=head1 SEE ALSO

=over 4

=item L<Test2::Tools::HTTP>

=item L<Mojo::UserAgent>

=item L<Test::Mojo>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
