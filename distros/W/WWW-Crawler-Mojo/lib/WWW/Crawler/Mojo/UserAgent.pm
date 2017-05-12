package WWW::Crawler::Mojo::UserAgent;
use strict;
use warnings;
use Mojo::Base 'Mojo::UserAgent';
use Mojo::URL;
use 5.010;

has active_conn => 0;
has active_conn_per_host => sub { {} };
has '_creds';
has keep_credentials => 1;

sub new {
  my $class = shift;
  my $self  = $class->SUPER::new(@_);

  if ($self->keep_credentials) {
    $self->_creds({});
    $self->on(
      start => sub {
        my ($self, $tx) = @_;
        my $url = $tx->req->url;
        my $host_key = _host_key($url) or return;
        if ($url->userinfo) {
          $self->{_creds}->{$host_key} = $url->userinfo;
        }
        else {
          $url->userinfo($self->{_creds}->{$host_key});
        }
      }
    );
  }

  $self->on(
    start => sub {
      my ($self, $tx) = @_;
      my $url = $tx->req->url;
      $self->active_host($url, 1);
      $tx->on(finish => sub { $self->active_host($url, -1) });
    }
  );

  return $self;
}

sub active_host {
  my ($self, $url, $inc) = @_;
  my $key   = _host_key($url);
  my $hosts = $self->active_conn_per_host;
  if ($inc) {
    $self->{active_conn} += $inc;
    $hosts->{$key} += $inc;
    delete($hosts->{$key}) unless ($hosts->{$key});
  }
  return $hosts->{$key} || 0;
}

sub credentials {
  my ($self, %credentials) = @_;
  while (my ($url, $cred) = each(%credentials)) {
    $self->{_creds}->{_host_key($url)} = $cred;
  }
}

sub _host_key {
  state $well_known_ports = {http => 80, https => 443};
  my $url = shift;
  $url = Mojo::URL->new($url) unless ref $url;
  return unless $url->is_abs && (my $wkp = $well_known_ports->{$url->scheme});
  my $key = $url->scheme . '://' . $url->ihost;
  return $key unless (my $port = $url->port);
  $key .= ':' . $port if $port != $wkp;
  return $key;
}

1;

=head1 NAME

WWW::Crawler::Mojo::UserAgent - Crawler specific featured user agent

=head1 SYNOPSIS

    my $ua = WWW::Crawler::Mojo::UserAgent->new;
    $ua->keep_credentials(1);
    $ua->credentials(
        'http://example.com:8080' => 'jamadam:password1',
        'http://example2.com:8080' => 'jamadam:password2',
    );
    my $tx = $ua->get('http://example.com/');
    say $tx->req->url # http://jamadam:passowrd@example.com/
    
    if ($ua->active_conn < $max_conn) {
        $ua->get(...);
    }
    
    if ($ua->active_host($url) < $max_conn_per_host) {
        $ua->get(...);
    }

=head1 DESCRIPTION

This class inherits L<Mojo::UserAgent> and adds credential storage and
active connection counter.

=head1 ATTRIBUTES

WWW::Crawler::Mojo::UserAgent inherits all attributes from Mojo::UserAgent.

=head2 active_conn

A number of current connections.

    $bot->active_conn($bot->active_conn + 1);
    say $bot->active_conn;

=head2 active_conn_per_host

A number of current connections per host.

    $bot->active_conn_per_host($bot->active_conn_per_host + 1);
    say $bot->active_conn_per_host;

=head2 keep_credentials

Sets true to activate the feature. Defaults to 1.

    $ua->keep_credentials(1);

=head1 METHODS

WWW::Crawler::Mojo::UserAgent inherits all methods from L<Mojo::UserAgent>.

=head2 active_host

Maintenances the numbers of active connections.

    $ua->active_host($url, 1);
    $ua->active_host($url, -1);
    my $amount = $ua->active_host($url);

=head2 credentials

Stores credentials.

    $ua->credentials(
        'http://example.com:8080' => 'jamadam:password1',
        'http://example2.com:8080' => 'jamadam:password2',
    );

=head2 new

Constructer.

    $ua = WWW::Crawler::Mojo::UserAgent->new;

=head1 AUTHOR

Keita Sugama, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) Keita Sugama.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
