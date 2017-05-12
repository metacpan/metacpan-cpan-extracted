#!/usr/bin/env perl
use warnings;
use strict;

use lib 'lib';
use Test::More tests => 2;

# The versions of the following packages are reported to help understanding
# the environment in which the tests are run.  This is certainly not a
# full list of all installed modules.
my @show_versions =
 qw/Test::More
    XML::Compile
    XML::Compile::Cache
    XML::LibXML
    Log::Report
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

my $xml2_version = XML::LibXML::LIBXML_DOTTED_VERSION();
warn "libxml2 $xml2_version\n";

require_ok('XML::Compile::C14N');
require_ok('XML::Compile::C14N::Util');
