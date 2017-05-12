#!perl -T

use 5.008;
use strict;
use warnings 'all';

##############################################################################
# TEST MODULES
use Test::More;

##############################################################################
# MODULES
use URI;

##############################################################################
# TEST PLAN
plan tests => 3;

##############################################################################
# Local Assembly Resource File


##############################################################################
# Referenced Assembly Resource File
{
	my $uri = URI->new('pack://application:,,,/ReferencedAssembly;v1.0.0.1;component/ResourceFile.xaml');

	isa_ok($uri, 'URI::pack', 'Referenced assembly is URI::pack');

	is $uri->package_uri        , 'application:///', 'Referenced assembly has package application:///';
	is $uri->package_uri->scheme, 'application'    , 'Referenced assembly has package scheme application';
}

exit 0;
