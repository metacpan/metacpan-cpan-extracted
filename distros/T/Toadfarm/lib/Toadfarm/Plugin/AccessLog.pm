package Toadfarm::Plugin::AccessLog;
use Mojo::Base 'Mojolicious::Plugin';
use Time::HiRes qw(gettimeofday tv_interval);

sub register {
  my ($self, $app, $config) = @_;
  my $log = $app->log;

  $app->hook(
    before_dispatch => sub {
      my $tx = $_[0]->tx;
      my ($req, $timeout, $url);

      $tx->req->env->{t0} = [gettimeofday];

      if (my $stream = Mojo::IOLoop->stream($tx->connection)) {
        $stream->on(timeout => sub { $timeout = 1 });
      }

      $tx->on(
        finish => sub {
          my $tx   = shift;
          my $code = $tx->res->code;

          $code ||= 504 if $timeout;
          $code or return;
          $req = $tx->req;
          $url = $req->url->clone->to_abs->userinfo(undef);

          unshift @{$url->path->parts}, @{$url->base->path->parts};

          $log->info(
            sprintf '%s %s %s %s %.4fs',
            $req->env->{identity} || $tx->remote_address,
            $req->method, $url, $code, tv_interval($req->env->{t0}),
          );
        }
      );
    }
  );
}

1;

=encoding utf8

=head1 NAME

Toadfarm::Plugin::AccessLog - Log requests

=head1 SYNOPSIS

  #!/usr/bin/env perl
  use Toadfarm -init;
  # mount applications, set up logging, ...
  plugin "Toadfarm::Plugin::AccessLog";
  start;

=head1 DESCRIPTION

This module will log the request with "info" log level. The log format
is subject for change. For now it is:

  $remote_address $http_method $url $status_code
  1.2.3.4 GET http://localhost/favicon.ico 200

See also L<Mojolicious::Plugin::AccessLog> if you think this plugin is too
limiting.

=head1 METHODS

=head2 register

Register an "around_dispatch" hook which will log the request.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut
