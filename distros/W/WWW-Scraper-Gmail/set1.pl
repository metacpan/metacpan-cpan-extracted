#!/usr/bin/perl -w

use strict;

use WWW::Scraper::Gmail;
use Getopt::Long;

my $signature;
my $getinbox='';
my $getcount='';
my $maxpage=100;

GetOptions( "get_count"         => \$getcount,
            "signature=s"       => \$signature,
            "get_inbox"         => \$getinbox,
            "max_per_page=i"    => \$maxpage);


my $woah = WWW::Scraper::Gmail::setPrefs({ Signature => $signature, MaxPer => $maxpage }) if ($signature or $maxpage != 100);
print "Settings changed\n" if ($woah);
print "Failure in changing\n" if (!$woah);
print WWW::Scraper::Gmail::countMail, "\n" if ($getcount);
print WWW::Scraper::Gmail::outputMail, "\n" if ($getinbox);
