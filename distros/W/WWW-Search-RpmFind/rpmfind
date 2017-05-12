#!/usr/bin/perl
# script rpmfind : Query rpm database available via rpmfind.net
# Copyright 2002 A.Barbet alian@alianwebserver.com.  All rights reserved

use WWW::Search;
use WWW::Search::RpmFind;
use strict;
use Getopt::Long;

my $version = ('$Revision: 1.1 $ ' =~ /(\d+\.\d+)/)[0];

my ($only_url,$debug,$distribution,$archi,$max);

if (!$ARGV[0] || ($ARGV[0] && ($ARGV[0] eq '-h' or $ARGV[0] eq '--help')))  { 
  &help(); 
}

# Parsing des options ligne de commande
GetOptions
  (
   "debug"              => \$debug,
   "distribution=s"     => \$distribution,
   "architecture=s"     => \$archi,
   "only_rpm"           => \$only_url,
   "max=s"              => \$max
  ) || &help();

my %param =
  (
#   'search_debug'=> 1,'search_parse_debug' => 1,
#   'search_to_file'     => "/tmp/rpmfind",
#   'search_from_file'  => "/tmp/rpmfind",
#   'proxy'=>'http://indy.alianet:3128',
   );
if ($debug) {
  $param{'debug'} = 3;
  $param{'_debug'} = 3;
}

my $oSearch = new WWW::Search('RpmFind', %param);

$max = 50 if (!$max);
$oSearch->maximum_to_retrieve($max);

# Create request
$oSearch->native_query(WWW::Search::escape_query($ARGV[0]));

print "-- I find ", $oSearch->approximate_result_count(),
  " results for $ARGV[0]\n";
if ($oSearch->approximate_result_count()>$max) {
  print "-- I only parse $max results (Change it with +max=no option)\n";
}
my $n=1;
while (my $oResult = $oSearch->next_result())  {
  if ($distribution) {
    next if ($oResult->description!~m!$distribution!i);
  }
  if ($archi) {
    next if ($oResult->source!~m!$archi!i);
  }

    print $n++,"\t", $oResult->source,"\n";
    if (!$only_url) {
      print
	"\tPackage: ", $oResult->url,"\n",
	"\tTitle: ", $oResult->title,"\n",
	"\tDistribution: ", $oResult->description,"\n\n";
    }
  }

sub help {
print "
Usage: $0 [options] \"request\"

rpmfind $version - Query rpm database available via rpmfind.net
Using WWW::Search::RpmFind version ",$WWW::Search::RpmFind::VERSION,"

Options:
   +debug: Be verbose
   +distribution=regexp: Match on distribution cols 
     (Ex: +distribution=mandrake)
   +archi=regexp: Match on rpm link
     (Ex: +archi=i\\d86)
   +only_rpm: Only print links of rpm found
   +max=no: number of item to retrieve & display

Examples:
  $0 libmpeg3 : Search rpm with libmpeg3
  $0 +only_rpm libmpeg3 : Search rpm with libmpeg3 but only print links of rpm
  $0 +distribution=mandrake libmpeg3 : Search rpm with libmpeg3 but only print links of rpm

";
    exit(0);
}

=head1 NAME

rpmfind - Query rpm database available via rpmfind.net

=head1 SYNOPSIS

Search rpm with libmpeg3:

  rpmfind libmpeg3

Search rpm with libmpeg3 but only print links of rpm:

  rpmfind +only_rpm libmpeg3

Search rpm with libmpeg3 but only on distribution mandrake:

  rpmfind +distribution=mandrake libmpeg3

=head1 DESCRIPTION

This script is an example of using WWW::Search::RpmFind, 
a specialization of WWW::Search.
It handles making and interpreting RpmFind searches
F<http://RpmFind.net>, a database search engine on RPM packages..

=head1 SEE ALSO

The WWW::Search::RpmFind man pages

=head1 AUTHOR

C<WWW::Search::RpmFind> is written by Alain BARBET,
alian@alianwebserver.com

=cut
