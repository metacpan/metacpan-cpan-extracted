use strict;
local $^W = 1;
#warn('Ignore mkdir and chmod errors');
our $jobname;
require './t/defs.pm';
system("perl  \"-Iblib/lib\" blib/script/combineINIT --baseconfig ./blib/conf/ --jobname $jobname > /dev/null 2> /dev/null");

require Combine::Config;
use Cwd;
Combine::Config::Init($jobname,getcwd . '/blib/conf');
my $wait=Combine::Config::Get('WaitIntervalHost');
Combine::Config::Set('WaitIntervalHost',1);

require Combine::SD_SQL;
require Combine::selurl;

my $sd = new  Combine::SD_SQL;
my @urls=(
  'http://www.it.lth.se',  'http://www.it.lth.se/',
  'http://www.it.lth.se:80/',  'http://www.it.lth.se:80',
  'http://www.lth.se/dark',
  'http://www.it.lth.se/anders/',
  'http://www.lth.se/anders/CV.html',
  'http://www.it.lth.se:88/anders/',
	  );
my %normURLs;

foreach my $url (@urls) {
    my $res = $sd->putNorm($url);
    my $u = new  Combine::selurl($url, undef, 'sloppy' => 1);
    my $nurl = $u->normalise();
    $normURLs{$nurl}=1;
}

use Test::More tests => 3;
isnt($wait,Combine::Config::Get('WaitIntervalHost'),'new value WaitIntervalHost');
my $t=4;
my $i=0;
while (1) {
   my ($netlocid, $urlid, $url_str, $netlocStr, $urlPath, $checkedDate) = $sd->get_url;
   delete($normURLs{$url_str});
#   $i=0; foreach my $u (keys(%normURLs)) { $i++; }
   $i = scalar(keys %normURLs);
   if ($i == 0) { last; } elsif ($url_str eq '') {
       if ($t-- == 0) { last; }
       diag ("Sleep 1 s -- $i URLs to go\n"); sleep(1);
   }
}
is($i,0,'Scheduling');
cmp_ok($t,'>=',2,'Timing');
