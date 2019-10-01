#!/usr/bin/perl -w
use strict;
use lib './inc';
use IO::Catch;
use Test::HTTP::LocalServer;

our ($_STDOUT_, $_STDERR_);
tie *STDOUT, 'IO::Catch', '_STDOUT_' or die $!;
tie *STDERR, 'IO::Catch', '_STDERR_' or die $!;

use Test::More tests => 6;

# Disable all ReadLine functionality
$ENV{PERL_RL} = 0;
delete @ENV{qw(HTTP_PROXY http_proxy CGI_HTTP_PROXY)};
delete $ENV{PAGER}
  if $ENV{PAGER};
$ENV{PERL_HTML_DISPLAY_CLASS}="HTML::Display::Dump";

use_ok('WWW::Mechanize::Shell');
my $s = WWW::Mechanize::Shell->new( 'test', rcfile => undef, warnings => undef );

# Now test
my $server = Test::HTTP::LocalServer->spawn();

{ no warnings 'redefine', 'once';
  local *WWW::Mechanize::Shell::status = sub {};

  $s->cmd( sprintf 'get "%s"', $server->url);
  isnt($s->agent->content,"","Retrieved content");
  $s->cmd("save");
  is($_STDOUT_,"No link given to save\n","save error message");
  is($_STDERR_,undef,"No warnings");

  $_STDOUT_ = undef;
  $_STDERR_ = undef;

  $s->cmd("save /does-not-exist/");
  like($_STDOUT_,'/No match for \/\(\?(-xism|\^):does-not-exist\)\/.\n/',"save RE error message");
  is($_STDERR_,undef,"No warnings");
};


