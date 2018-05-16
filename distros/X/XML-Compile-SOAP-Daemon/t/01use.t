#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 3;

# The versions of the following packages are reported to help understanding
# the environment in which the tests are run.  This is certainly not a
# full list of all installed modules.
my @show_versions =
 qw/Test::More
    XML::Compile
    XML::Compile::SOAP
    XML::Compile::Cache
    XML::Compile::Tester
    XML::Compile::SOAP::WSA
    XML::LibXML
    Net::Server
	Log::Report
    LWP
   /;

foreach my $package (@show_versions)
{   eval "require $package";

    no strict 'refs';
    my $report
      = !$@    ? "version ". (${"$package\::VERSION"} || 'unknown')
      : $@ =~ m/^Can't locate/ ? "not installed"
      : "reports error";

    warn "$package $report\n";
}

warn "libxml2 ".XML::LibXML::LIBXML_DOTTED_VERSION()."\n";

require_ok('XML::Compile::SOAP::Daemon');

eval "require Net::Server";
my $has_net_server = $@ ? 0 : 1;

eval "require LWP";
my $has_lwp = $@ ? 0 : 1;

eval "require CGI";
my $has_cgi = $@ ? 0 : 1;

if($has_net_server && $has_lwp)
{   require_ok('XML::Compile::SOAP::Daemon::NetServer');
}
else
{   ok(1, 'Net::Server not installed');
}

if($has_cgi)
{   require_ok('XML::Compile::SOAP::Daemon::CGI');
}
else
{   ok(1, 'CGI not installed');
}
