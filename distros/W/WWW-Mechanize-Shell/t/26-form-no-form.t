#!/usr/bin/perl -w
use strict;
use lib './inc';
use IO::Catch;

use vars qw($_STDOUT_ $_STDERR_);
tie *STDOUT, 'IO::Catch', '_STDOUT_' or die $!;
tie *STDERR, 'IO::Catch', '_STDERR_' or die $!;

use Test::More tests => 4;

# Disable all ReadLine functionality
$ENV{PERL_RL} = 0;
delete $ENV{PAGER}
  if $ENV{PAGER};
$ENV{PERL_HTML_DISPLAY_CLASS}="HTML::Display::Dump";

my @warnings;

use_ok('WWW::Mechanize::Shell');
my $s = WWW::Mechanize::Shell->new( 'test', rcfile => undef, warnings => undef );

{ no warnings qw'redefine once';
*WWW::Mechanize::Shell::status = sub {};
};

$s->agent->{base} = 'http://www.google.com/';
$s->agent->update_html("<html><body>No form here</body></html>\n");

eval {
  $s->cmd("form foo");
};
is($@, '', "Can execute 'form' for a page without forms");
is($_STDOUT_,"There is no form on this page.\n","Message was printed");
is($_STDERR_,undef,"No warnings printed");

  #$_STDOUT_ = undef;
  #$_STDERR_ = undef;

  #$s->cmd("save /does-not-exist/");
  #is($_STDOUT_,"No match for /(?-xism:does-not-exist)/.\n","save RE error message");
  #is($_STDERR_,undef,"No warnings");


