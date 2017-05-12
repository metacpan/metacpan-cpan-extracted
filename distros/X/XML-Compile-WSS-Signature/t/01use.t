#!/usr/bin/env perl
use warnings;
use strict;

use lib '../XMLWSS/lib', 'lib';

use Test::More tests => 5;

# The versions of the following packages are reported to help understanding
# the environment in which the tests are run.  This is certainly not a
# full list of all installed modules.
my @show_versions =
 qw/Test::More
    XML::Compile
    XML::Compile::Cache
    XML::Compile::SOAP
    XML::Compile::WSS
    XML::Compile::C14N

    Digest
    Crypt::OpenSSL::RSA
    Crypt::OpenSSL::CA
    Crypt::OpenSSL::X509
    Crypt::DSA
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

require_ok('XML::Compile::WSS::SecToken');
require_ok('XML::Compile::WSS::SecToken::X509v3');
require_ok('XML::Compile::WSS::Signature');
require_ok('XML::Compile::WSS::Sign');
require_ok('XML::Compile::WSS::Sign::RSA');
