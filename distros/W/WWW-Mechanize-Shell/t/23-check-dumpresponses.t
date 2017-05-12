#!/usr/bin/perl -w
use strict;
use lib './inc';
use IO::Catch;
use Test::HTTP::LocalServer;

use vars qw($_STDOUT_ $_STDERR_);
tie *STDOUT, 'IO::Catch', '_STDOUT_' or die $!;
tie *STDERR, 'IO::Catch', '_STDERR_' or die $!;

use Test::More tests => 5;

# Disable all ReadLine functionality
$ENV{PERL_RL} = 0;
delete @ENV{qw(HTTP_PROXY http_proxy CGI_HTTP_PROXY)};

use_ok('WWW::Mechanize::Shell');
my $s = WWW::Mechanize::Shell->new( 'test', rcfile => undef, warnings => undef );

# Now test
my $server = Test::HTTP::LocalServer->spawn();

{ no warnings 'redefine','once';
  local *WWW::Mechanize::Shell::status = sub {};

  #$s->cmd("set dumprequests 1");
  $s->cmd("set dumpresponses 1");
  eval { $s->cmd( sprintf 'get "%s"', $server->url); };
  is($@, "", "Get url worked");
  isnt($_STDOUT_,undef,"Response was not undef");
  isnt($_STDOUT_,"","Response was output");
  isnt($s->agent->content,"","Retrieved content");
};


