#!/usr/bin/env perl
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN {do "$FindBin::RealBin/libdir.pl"}
#----------------------------------------
use YATT::Lite::Util::FindMethods;

use YATT::Lite::Factory;
use YATT::Lite::Entities qw(*YATT);
use YATT::Lite::Util qw(rootname);
use YATT::Lite::Breakpoint;

require YATT::Lite::Util::CmdLine;

use Cwd;

use Getopt::Long;

GetOptions("if_can" => \ my $if_can
	  , "d=s" => \ my $o_dir)
  or exit 1;

my $dispatcher = YATT::Lite::Factory->load_factory_offline || do {
    require YATT::Lite::WebMVC0::SiteApp;
    YATT::Lite::WebMVC0::SiteApp->new
	(app_ns => 'MyApp'
	 , namespace => ['yatt', 'perl', 'js']
	 , header_charset => 'utf-8'
	 , tmpldirs => [grep {-d} "ytmpl"]
	 , debug_cgen => $ENV{DEBUG}
	 , debug_cgi  => $ENV{DEBUG_CGI}
	 # , is_gateway => $ENV{GATEWAY_INTERFACE} # Too early for FastCGI.
	 # , tmpl_encoding => 'utf-8'
	);
};

local $YATT = my $dirhandler = $dispatcher->get_dirhandler($o_dir // getcwd());

unless (@ARGV) {
  die <<END, join("\n", map {"  $_"} FindMethods($YATT, sub {s/^cmd_//}))."\n";
Usage: @{[basename($0)]} COMMAND args...

Available commands are:
END
}

my $command = $ARGV[0];
if ($YATT->can("cmd_$command") || $YATT->can($command)) {
  YATT::Lite::Util::CmdLine::run($YATT, \@ARGV);
} elsif ($if_can) {
  exit
} else {
  die "No such command: $command\n";
}
