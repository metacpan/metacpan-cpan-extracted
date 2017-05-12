#!/usr/bin/env perl

use warnings;
use strict;

use lib 'lib';
use Test::More tests => 13;

# The versions of the following packages are reported to help understanding
# the environment in which the tests are run.  This is certainly not a
# full list of all installed modules.
my @show_versions =
 qw/Test::More
    Test::Deep
    Log::Report
    Math::BigInt
    String::Print
    XML::LibXML
    XML::Compile
    XML::Compile::SOAP
    XML::Compile::Tester
    XML::Compile::Dumper
    XML::Compile::Cache
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

my ($major,$minor,$rev) = split /\./, $xml2_version;
if(  $major < 2
 || ($major==2 && $minor < 6)
 || ($major==2 && $minor==6 && $rev < 23))
{   warn <<__WARN;

*
* WARNING:
* Your libxml2 version ($xml2_version) is quite old: you may
* have failing tests and poor functionality.
*
* Please install a new version of the library AND reinstall the
* XML::LibXML module.  Otherwise, you may need to install this
* module with force.
*

__WARN

    warn "Press enter to continue with the tests: \n";
    <STDIN>;
}

require_ok('XML::Compile');
require_ok('XML::Compile::Iterator');
require_ok('XML::Compile::Schema');
require_ok('XML::Compile::Schema::BuiltInFacets');
require_ok('XML::Compile::Schema::BuiltInTypes');
require_ok('XML::Compile::Schema::Instance');
require_ok('XML::Compile::Schema::NameSpaces');
require_ok('XML::Compile::Schema::Specs');
require_ok('XML::Compile::Translate');
require_ok('XML::Compile::Translate::Reader');
require_ok('XML::Compile::Translate::Writer');
require_ok('XML::Compile::Translate::Template');
require_ok('XML::Compile::Util');
