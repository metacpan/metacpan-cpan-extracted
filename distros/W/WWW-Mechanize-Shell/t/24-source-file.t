#!/usr/bin/perl -w
use strict;
use lib './inc';
use IO::Catch;
use Test::HTTP::LocalServer;

use vars qw($_STDOUT_ $_STDERR_);
tie *STDOUT, 'IO::Catch', '_STDOUT_' or die $!;
tie *STDERR, 'IO::Catch', '_STDERR_' or die $!;

use Test::More tests => 6;

# Disable all ReadLine functionality
$ENV{PERL_RL} = 0;
delete $ENV{PAGER}
  if $ENV{PAGER};
$ENV{PERL_HTML_DISPLAY_CLASS}="HTML::Display::Dump";

delete @ENV{qw(HTTP_PROXY http_proxy CGI_HTTP_PROXY)};

use_ok('WWW::Mechanize::Shell');
my $s = WWW::Mechanize::Shell->new( 'test', rcfile => undef, warnings => undef );

# Now test
my $server = Test::HTTP::LocalServer->spawn();

{ no warnings 'redefine','once';
  local *WWW::Mechanize::Shell::status = sub {};

  $s->cmd( sprintf 'get "%s"', $server->url);
  isnt($s->agent->content,"","Retrieved content");
  $s->cmd("source t/source.mech");
  isnt($_STDOUT_,"","Sourcing a file works");
  is($_STDERR_,undef,"No warnings");
};

{ no warnings 'redefine','once';
  my $warned;
  local *WWW::Mechanize::Shell::display_user_warning = sub { $warned++ };

  $s->cmd("source t/does-not-exist.mech");
  is($warned,1,"Warning for nonexistent files works");
  is($_STDERR_,undef,"No warnings");
};

