#!/usr/bin/perl -w
use strict;
use lib './inc';
use IO::Catch;

our ($_STDOUT_, $_STDERR_);
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

my @status;
{ no warnings qw'once redefine';
*WWW::Mechanize::Shell::status = sub {};
};

$s->cmd('get file:t/27-index.html');
$s->option('warnings',1);
eval {
  $s->cmd("form 2");
};
is($@, '', "Can execute 'form 2' for a page with two forms");
is($_STDOUT_,undef,"Nothing was printed");
is($_STDERR_,undef,"No warnings printed");

