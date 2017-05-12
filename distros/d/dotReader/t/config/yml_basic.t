#!/usr/bin/perl

use strict;
use warnings;

use inc::testplan(1, 21);

BEGIN {use_ok('dtRdr::Config::YAMLConfig')};

use File::Basename qw(dirname);

my $dbfile = dirname($0) . '/' . 'testconfig.yml';
(-e $dbfile) and unlink($dbfile);

{ # just a standalone CD::Server object
  my $server = dtRdr::ConfigData::Server->new(
    id  => 'the server',
    uri => 'http://example.com/',
    type => 'Standard',
  );

  # make sure we can set without config
  is($server->config, undef, 'yay');
  $server->set_username('bob');
  is($server->username, 'bob', 'hooray');
}

{ # create, populate
  my $conf = dtRdr::Config::YAMLConfig->new($dbfile);

  isa_ok($conf, 'dtRdr::Config');
  my $L = sub {dtRdr::ConfigData::LibraryInfo->new(@_)};
  is($conf->add_library($L->(uri => 'foo1', type => 'bar2')), 0);
  is($conf->add_library($L->(uri => 'bar1', type => 'bar2')), 1);
  is($conf->add_library($L->(uri => 'baz1', type => 'bar2')), 2);
  my $server = dtRdr::ConfigData::Server->new(
    id  => 'the server',
    uri => 'http://example.com/',
    type => 'Standard',
    books => [],
  );
  is($conf->add_server($server), 0);
  is($server->intid, 0);
}
{ # that should disconnect, see if it lived
  my $conf = dtRdr::Config::YAMLConfig->new($dbfile);
  my @libraries = $conf->libraries;
  ok(3 == @libraries, 'count');
  foreach my $l (@libraries) {
    is($l->type, 'bar2', 'type') or warn join("|", %$l);
  }
  my ($server) = $conf->servers;
  is($server->id, 'the server');
  $server->set_username('bob'); # auto-update
  is($server->username, 'bob', 'go bob');
  is_deeply([$server->books], [], 'no books');
  $server->add_books('book_about_a_duck', 'something_in_blue');
  is_deeply([$server->books], [qw(book_about_a_duck something_in_blue)],
    'nice books');
}
{ # try the server again
  my $conf = dtRdr::Config::YAMLConfig->new($dbfile);
  my ($server, @else) = $conf->servers;
  is(scalar(@else), 0, 'no strays');
  is($server->id, 'the server');
  is($server->username, 'bob', 'hooray bob');
  is_deeply([$server->books], [qw(book_about_a_duck something_in_blue)],
    'nice books');
}

done;
# vim:ts=2:sw=2:et:sta
