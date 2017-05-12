#!/usr/bin/perl

use strict;
use warnings;

use XML::Toolkit::Loader;
use Cwd qw(getcwd);
use lib getcwd();

my $loader = XML::Toolkit::Loader->new(
 filter_class => 'XML::Toolkit::Loader::ParserNS',
 namespace_map => {
   'http://www.imsglobal.org/xsd/imsmd_v1p2' => 'IMS::LOM',
   'http://www.imsglobal.org/xsd/imscp_v1p1' => 'IMS::CP',
 }
);
$loader->parse_uri( $ARGV[0] );
print join("",@{ $loader->render });

