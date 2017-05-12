use strict;
local $^W = 1;

our $jobname;
require './t/defs.pm';

use Combine::selurl;
require Combine::Config;
use Cwd;
Combine::Config::Init($jobname,getcwd . '/blib/conf');

my %urls = 
  (
   'http://nopath.dtu.dk' => 'valid',
   'http://www.ku.dk/ok/where/home.html' => 'valid',
   'http://www.ku.dk/cgi-bin/ok.cgi?bar=baz' => 'invalid',
   'http://www.ku.dk/somedoc.html#wherever' => 'valid',
   'http://www.ku.dk:80/default/port/test.html' => 'valid',
   'mailto:mailname@somehost.com' => 'invalid',
   'javascript:jstest.bla' => 'invalid',
   'ftp://ftp.ku.dk/ftp/without/port' => 'valid',
   'ftp://www.ku.dk:21/ftp/withexplicitport.txt' => 'valid',
   'http://kbs3w.adm.dtu.dk/aliastest' => 'valid',
   'www.dtu.dk/noschemetest.html' => 'valid',
   '//path/without/a/server' => 'valid',
   'http:///' => 'invalid',
   'http://www.ku.dk/forbidden.jpg' => 'invalid',
   'http://www.diku.dk/path/url with 99% spaces and a %66 sign.html' => 'valid',
   'http://www.diku.dk/Ãrl-with-UTF.html' => 'valid',
   'http://www.diku.dk/pleuris.php?lang=en&lang=da&lang=en&lang=da&lang=en&lang=da' => 'invalid',
   'http://www.diku.dk/keypleuris.php?lang=1&lang=2&lang=3&lang=4&lang=5&lang=6' => 'invalid',
   'http://www.diku.dk/echtpleuris.php?en&dk&en&dk&en&dk&en&dk&dk&en&dk&en&dk&en&dk' => 'invalid',
   'http://www.diku.dk/muchtoolong/' . 'x' x 260 => 'invalid'
  );

my $i=0;
foreach my $k (keys(%urls)) { $i++; }
print "1..$i\n";

$i=0;
foreach my $rawurl (keys(%urls))
{
  $i++;
  my $u = new Combine::selurl($rawurl, undef, 'sloppy' => 1);
  if(!$u)
  {
#    print "wrong  $rawurl\n";
    if ($urls{$rawurl} eq 'invalid') { print "ok $i\n"; }
    else { print "not ok $i\n"; }
    next;
  }
#  print 'raw    ' . "$rawurl\n";
#  print 'norm   ' . $u->normalise(); print "\n";
  if ( $u->validate() ) {
#      print 'valid  ' . $u->{'invalidreason'}; print "\n";
    if ($urls{$rawurl} eq 'valid') { print "ok $i\n"; }
    else { print "not ok $i\n"; }
       
  } else {
#      print 'invalid  ' . $u->{'invalidreason'}; print "\n";
    if ($urls{$rawurl} eq 'invalid') { print "ok $i\n"; }
    else { print "not ok $i\n"; }
  }
}


