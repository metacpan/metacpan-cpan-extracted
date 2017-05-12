#!/usr/local/bin/perl -w
# CGI script for the X10 console web application.
# 
# Requires the x10.tmpl file to be installed in the 
# same directory as x10.cgi. 
# x10.js is expected in the server's document root (htdocs).
# Also, please install YUI on your
# webserver under htdocs/yui: http://developer.yahoo.com/yui
use strict;
use CGI qw(:all);
use Log::Log4perl qw(:easy);
use Template;
use X10::Home;

print header();

my $action = param("action");
my $device = param("device");

my $x10 = X10::Home->new();

if(!defined $device) {
  my $tpl = Template->new();
  $tpl->process("x10.tmpl", { 
    devices => $x10->{conf}->{receivers}, 
  } ) or die $tpl->error();
  exit 0;
}

if(!defined $action or
   $action !~ /^(on|off|status)$/) {
  print "Error: No/Invalid action\n";
  exit 0;
}

if(!defined $device or $device =~ /\W/) {
  print "Error: use a proper 'device'\n";
  exit 0;
}

system "/home/mschilli/PERL/bin/x10", $device, param("action");
