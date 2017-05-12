#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin;
BEGIN {
  if (-d (my $dir = "$FindBin::RealBin/../../../../t")) {
    local (@_, $@) = $dir;
    do "$dir/t_lib.pl";
    die $@ if $@;
  }
}

use Cwd ();
my ($app_root);
BEGIN {
  if (-r __FILE__) {
    # detect where app.psgi is placed.
    $app_root = dirname(dirname(File::Spec->rel2abs(__FILE__)));
  } else {
    # older uwsgi do not set __FILE__ correctly, so use cwd instead.
    $app_root = Cwd::cwd();
  }
}
#----------------------------------------
# To peek FCGI raw_result & raw_error, run with env DEBUG_FCGI=1

use 5.010;

use YATT::Lite::Breakpoint;
use YATT::Lite::Test::XHFTest2;
use YATT::t::t_preload; # To make Devel::Cover happy.

use base qw(YATT::Lite::Test::XHFTest2);
use YATT::Lite::Util qw(lexpand);

use YATT::Lite::Test::TestFCGI;

my $CLASS = YATT::Lite::Test::TestFCGI::Auto->class
  or YATT::Lite::Test::TestFCGI::Auto->skip_all
  ('None of FCGI::Client and /usr/bin/cgi-fcgi is available');

unless (-d "$app_root/html/cgi-bin"
	and grep {-x "$app_root/html/cgi-bin/runyatt.$_"} qw(cgi fcgi)) {
  $CLASS->skip_all("Can't find cgi-bin/runyatt.cgi");
}

my $mech = $CLASS->new
  (map {
    (rootdir => $_
     , fcgiscript => "$_/cgi-bin/runyatt.fcgi"
     , debug_fcgi => $ENV{DEBUG_FCGI}
    )
  } "$app_root/html");

if (my $reason = $mech->check_skip_reason) {
  $mech->skip_all($reason);
}

my MY $tests = MY->load_tests([dir => "$FindBin::Bin/../html"]
			      , @ARGV ? @ARGV : $FindBin::Bin);
$tests->enter;

my @plan = $tests->test_plan;
# skip_all should be called before fork.
if (@plan and $plan[0] eq 'skip_all') {
  $mech->plan(@plan);
}

$mech->fork_server;

# test plan should be configured after fork.
$mech->plan(@plan);

$tests->mechanized($mech);

sub base_url { shift; '/'; }

sub ntests_per_item {
  (my MY $tests, my Item $item) = @_;
  lexpand($item->{cf_HEADER})/2
    + (($item->{cf_BODY} || $item->{cf_ERROR}) ? 1 : 0);
}

sub mech_request {
  (my MY $tests, my $mech, my Item $item) = @_;
  my $method = $tests->item_method($item);
  my $url = $tests->item_url_file($item);
  $mech->request($method, $url, $item->{cf_PARAM}, $item->{cf_ERROR});
}

# Local Variables: #
# coding: utf-8 #
# End: #
