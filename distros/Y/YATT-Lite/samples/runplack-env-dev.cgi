#!/usr/bin/perl -w
use strict;
use warnings FATAL => qw/all/;
use File::Spec;

my $app_root;

use File::Basename ();
use Umask::Local;
BEGIN {
 ($app_root = File::Spec->rel2abs(__FILE__)) =~ s,/cgi-bin/[^/]+$,,;
  my $error_log = "$app_root/var/log/error_log";
  if (-e $error_log) {
    my $umask_local = Umask::Local->new(0007);
    open STDERR, '>>', $error_log or die $!;
  }
}

use Plack::Runner;
Plack::Runner->new(env => 'development', app => "$app_root/app.psgi")->run();
