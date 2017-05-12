use strict;
local $^W = 1;
#warn('Ignore mkdir and chmod errors');
our $jobname;
require './t/defs.pm';
system("perl  \"-Iblib/lib\" blib/script/combineINIT --baseconfig ./blib/conf/ --jobname $jobname > /dev/null 2> /dev/null");

require Combine::Config;
use Cwd;
Combine::Config::Init($jobname,getcwd . '/blib/conf');

require Combine::SD_SQL;
require Combine::selurl;

my $sd = new  Combine::SD_SQL;
my @urls=(
  'http://www.eit.lth.se',  'http://www.eit.lth.se/',
  'http://www.eit.lth.se:80/',  'http://www.eit.lth.se:80',
  'http://www.lth.se/dark',
  'http://www.eit.lth.se/staff/anders.ardo',
  'http://www.lth.se/anders/CV.html',
  'http://www.eit.lth.se:88/anders/',
	  );
my %normURLs;

foreach my $url (@urls) {
    my $res = $sd->putNorm($url);
    my $u = new  Combine::selurl($url, undef, 'sloppy' => 1);
    my $nurl = $u->normalise();
    $normURLs{$nurl}=1;
}

use Test::More tests => 2;
diag('Be patient the test takes 1 min');

my $t=4;
my $i=0;
while (1) {
   my ($netlocid, $urlid, $url_str, $netlocStr, $urlPath, $checkedDate) = $sd->get_url;
   delete($normURLs{$url_str});
#   $i=0; foreach my $u (keys(%normURLs)) { $i++; }
   $i = scalar(keys %normURLs);
   if ($i == 0) { last; } elsif ($url_str eq '') {
       if ($t-- == 0) { last; }
       diag ("Sleep 30 s -- $i URLs to go (t=$t)\n"); sleep(31);
   }
}
is($i,0,'Scheduling');
is($t,2,'Timing');
