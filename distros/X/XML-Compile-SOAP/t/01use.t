#!/usr/bin/env perl

use warnings;
use strict;

use lib 'lib', 't';
use Test::More tests => 16;
use TestTools;

# The versions of the following packages are reported to help understanding
# the environment in which the tests are run.  This is certainly not a
# full list of all installed modules.
my @show_versions =
 qw/Test::More
    Test::Deep
    XML::Compile
    XML::Compile::Tester
    XML::Compile::Cache
    XML::Compile::SOAP::WSA
    XML::LibXML
    Math::BigInt
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

use_ok('XML::Compile::SOAP::Util');
use_ok('XML::Compile::SOAP');
use_ok('XML::Compile::SOAP::Server');
use_ok('XML::Compile::SOAP::Trace');
use_ok('XML::Compile::SOAP::Operation');
use_ok('XML::Compile::SOAP::Client');
use_ok('XML::Compile::SOAP::Extension');

use_ok('XML::Compile::SOAP11');
use_ok('XML::Compile::SOAP11::Client');
use_ok('XML::Compile::SOAP11::Encoding');
use_ok('XML::Compile::SOAP11::Operation');
use_ok('XML::Compile::SOAP11::Server');

use_ok('XML::Compile::Transport');
use_ok('XML::Compile::Transport::SOAPHTTP');
use_ok('XML::Compile::XOP');
use_ok('XML::Compile::XOP::Include');
