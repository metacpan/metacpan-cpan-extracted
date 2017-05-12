#!/usr/bin/perl -w
use strict;

use Test::More tests => 4;

BEGIN{
  # Disable all ReadLine functionality
  $ENV{PERL_RL} = 0;
  use_ok("WWW::Mechanize::Shell");
};

delete @ENV{qw(HTTP_PROXY http_proxy CGI_HTTP_PROXY)};

my $output= `$^X -I./lib -MWWW::Mechanize::Shell -e "WWW::Mechanize::Shell->new('t',rcfile=>undef,warnings=>undef)->cmd('restart');print'OK'" 2>&1`;
chomp $output;
is($@, "","'restart' on -e dosen't crash");
is($?, 0,"'restart' on -e dosen't crash");
is($output,"OK","'restart' on -e dosen't crash");
