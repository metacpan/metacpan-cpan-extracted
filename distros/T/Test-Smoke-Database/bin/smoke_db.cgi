#!/usr/bin/perl
#
# cgi interface for database build with module Test::Smoke::Database
# Copyright 200x A.Barbet alian@alianwebserver.com.  All rights reserved.
# $Date: 2003/08/19 10:37:24 $
# $Revision: 1.6 $
#

use CGI qw/:standard -no_xhtml/;
use CGI::Carp qw/fatalsToBrowser/;
use lib "/home/alian/cgi-bin/site_perl";
use strict;
use Benchmark qw(timeit timestr);
use Test::Smoke::Database;
$|=1;

my %opts =
  ( 'dir'         => '$ENV{HOME}/.perl.daily-build.reports',
    'nntp_server' => 'nntp.perl.org',
    'debug'       => 0,
    'mysql'       => 'mysql',
    'user'        => 'root',
    'password'    => '',
    'database'    => 'smoke',
    'limit'       => param('last_smoke_fil') || cookie('last_smoke') || 18188
  );

# for bench
if (!$ENV{SERVER_NAME}) {
  $ENV{SCRIPT_NAME}="/cgi-bin/smoke_db" if (!$ENV{SCRIPT_NAME});
  $ENV{SERVER_NAME}="saturne.alianet" if (!$ENV{SERVER_NAME});
  open (TRASH, ">>/dev/null"); select TRASH;
  my $res = timeit(1,'main()');
  select STDOUT; print timestr($res),"\n";
} else { &main(); }

sub main {
  my @lc; # list of cookies
  my %v;
  my $cgi = new CGI;
  foreach ('os','osver','cc','ccver','smoke','last_smoke','archi','date','version') {
    $v{$_} = $cgi->param($_) || $cgi->param($_.'_fil') || $cgi->cookie($_) || undef;
    next if (!$cgi->param($_.'_fil'));
    push(@lc,$cgi->cookie(-name=>$_,
		    -value=>param($_.'_fil'),
		    -expires=>'+3M'));
  }
  # Create a Test::Smoke::Database instance
  $opts{cgi}=$cgi;
  my $d = new Test::Smoke::Database(\%opts);
  print $cgi->header(-cookie=>\@lc),
	$d->HTML->header_html;
  if (param('filter')) { print $d->HTML->filter; }
  elsif (param('smokers')) {
    print $d->HTML->smokers;
  }
  else {
    my ($summary,$last_smoke,$fail)= $d->HTML->display($v{'os'}, $v{'osver'},
					  	       $v{'archi'}, $v{'cc'},
						       $v{'ccver'}, $v{'smoke'});
    if (param("last")) { print h2("Last smoke"),$$last_smoke,"\n"; }
    elsif (param("failure")) { print h2("Failures"),$$fail,"\n"; }
    else { print $$summary,"\n";}
  }
  print end_html;
}
