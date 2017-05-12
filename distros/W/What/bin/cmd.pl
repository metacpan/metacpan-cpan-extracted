#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use lib qw(../lib lib);
use What;
#my $banner = "localhost ESMTP Exim 4.60 Mon, 20 Feb 2006 22:38:53 +0000";
#my $banner = "mast MasqMail 0.2.21 ESMTP";
#$banner =~ m/^.+MasqMail (.+) ESMTP?.+/;
#print Dumper $1;
#exit;
#my $what = What->new( Banner => $banner );
my $what = What->new( Host => $ARGV[0], Port => $ARGV[1] );
print $what->mta  . "\n";
print $what->mta_version . "\n";
print $what->mta_banner  . "\n";
