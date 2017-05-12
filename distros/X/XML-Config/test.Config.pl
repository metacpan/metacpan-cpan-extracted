#!/usr/bin/perl -w
# $Id: test.Config.pl,v 1.1 2000/05/01 21:53:40 matt Exp $
use lib qw(.);
use Config;
my $cfg = new GoXML::Config;

print "1) Load one file:\n\n";

my %chash = $cfg->load_conf("test.xml") or die $cfg->err_str;

for (sort keys(%chash)) {
	print "* $_ = $chash{$_}\n";
}

print "2) Load a couple files:\n\n";
print "\t- NOT IMPLEMENTED.\n\n";


print "If you see no error, it worked :)\n";