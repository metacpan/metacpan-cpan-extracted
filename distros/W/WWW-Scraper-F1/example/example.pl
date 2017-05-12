use v5.14;
use strict;
use warnings;
use warnings   qw(FATAL utf8);
use open       qw(:std :utf8);
use charnames  qw(:full :short);

use FindBin;
use lib "$FindBin::Bin/../lib";
use WWW::Scraper::F1;
use Getopt::Long;
use Unicode::Normalize;
use Carp;

my $upcoming    = 1;
my $top         = -1;
my $points      = '';
my $cache       = 1;

GetOptions(
    'upcoming!' => \$upcoming,
    'cache!'     => \$cache,
    'top:i'     => \$top,
    'points=s'  => \$points,
);

if ($upcoming){
   my $race_info = get_upcoming_race( {cache => $cache}  ) ;
   print "$race_info->{city}, $race_info->{country}\n$race_info->{countdown}\n";
}

my $champ_info = get_top_championship( {length => $top, cache => $cache} );

foreach my $t (@$champ_info){
   if($points eq "no"){
       print "$t->{pos}. $t->{driver}\n";
   }elsif($points eq "just"){
       print "$t->{points}\n";
   }else{
       print "$t->{pos}. $t->{driver}\t $t->{points}\n";
   }
}
