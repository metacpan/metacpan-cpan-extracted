#!/usr/bin/perl

use strict;
use warnings;

use inc::testplan(1,
  + 3 # use
  + 8
);

########################################################################
BEGIN {
  use_ok('dtRdr::Annotation::IO');
  use_ok('dtRdr::Annotation::Sync::Standard');
  use_ok('dtRdr::Config');
}

{ # with user/pass
  my ($u, $p) = ('bob', 'a');
  my $uri = '9';
  my $server = dtRdr::ConfigData::Server->new(
    id       => 'the server',
    username => $u,
    password => $p,
    uri      => $uri,
  );

  my $did = 0;
  my $sync = dtRdr::Annotation::Sync::Standard->new($server->uri,
    server   => $server,
    auth_sub => sub {
      $did++;
    },
  );
  is_deeply([$sync->authenticate('foo', 'bar')], [$u,$p]);
  is($did, 0, 'no run');
}
{ # without is an error
  my ($u, $p) = (undef, undef);
  my $uri = '9';
  my $server = dtRdr::ConfigData::Server->new(
    id       => 'the server',
    username => $u,
    password => $p,
    uri      => $uri,
  );

  my $did = 0;
  my $sync = dtRdr::Annotation::Sync::Standard->new($server->uri,
    server   => $server,
  );
  eval {$sync->authenticate('foo', 'bar')};
  my $err = $@;
  ok($err, 'slap');
  like($err, qr/no auth_sub/);
}
{ # without user/pass
  my ($u, $p) = ('bob', 'a');
  my $uri = '9';
  my $server = dtRdr::ConfigData::Server->new(
    id       => 'the server',
    uri      => $uri,
  );

  my $did = 0;
  my $sync = dtRdr::Annotation::Sync::Standard->new($server->uri,
    server   => $server,
    auth_sub => sub {
      my ($S, $U, $R) = @_;
      is("$S", "$server", 'server');
      is($U, 'foo', 'uri');
      is($R, 'bar', 'realm');
      $did++;
      return($u, $p);
    },
  );
  is_deeply([$sync->authenticate('foo', 'bar')], [$u,$p]);
}

done;
# vim:ts=2:sw=2:et:sta:syntax=perl
