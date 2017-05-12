#!/usr/local/bin/perl -w

# $Id: advanced.t,v 1.3 2003/12/09 19:22:10 jonasbn Exp $

use strict;
use Test::More tests => 7;
use Data::Dumper;

my $debug = 0;
my $dump = 0;
my $verbose = 0;

#test 1-2
BEGIN { use_ok( 'XML::Conf' ); }
require_ok('XML::Conf');

#my $config = XML::Conf->new('t/populated.xml', case => \&ucfirst);
#my $config = XML::Conf->new('t/populated.xml', case => 'lcfirst');
my $config = XML::Conf->new('t/populated.xml');

print STDERR Dumper $config if $dump;

#test 3 (ReadConfig)
ok($config->ReadConfig(), 'Testing ReadConfig');

print STDERR Dumper $config if $dump;

#test 4 (RewriteConfig)
ok($config->RewriteConfig(), 'Testing RewriteConfig');

#test 5 (WriteConfig)
unlink('t/otherfile.xml');
ok($config->WriteConfig('t/otherfile.xml'), 'Testing WriteConfig');

#test 6 (Parameters)
my @Parameters;
ok(@Parameters = $config->Parameters('server'), 'Validating \@Parameters');
if ($verbose) {
	print @Parameters;
	print "\n";
}
#test 7 (Sections)
my @Sections;
ok(@Sections = $config->Sections('server'), 'Validating \@Sections');
if ($verbose) {
	print @Sections;
	print "\n";
}
