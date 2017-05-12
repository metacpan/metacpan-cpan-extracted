
require 5;
use strict;
use Test;

BEGIN { plan tests => 10 }
print "# Hi, I'm ", __FILE__, "\n";

use XML::RSS::TimingBot;
my $class = $XML::RSS::TimingBot::ISA[0];
use HTTP::Request::Common;

my $ua;
sub new_ua {
  print "# New ua... at ", join(' ', caller), "\n";
  $ua = $class->new;
  require File::Spec;
  $ua->{'_dbpath'} = File::Spec->curdir;
}

new_ua();
print "# $class version ", $ua->VERSION, "\n";
ok 1;


my $cgi_et  = $ENV{'TESTCGIET' } || "http://interglacial.com/d/only_et.cgi" ;
my $cgi_mod = $ENV{'TESTCGIMOD'} || "http://interglacial.com/d/only_mod.cgi";

for($cgi_et, $cgi_mod) { $_ .= reverse sprintf "%x-%x?",
  (defined &Win32::GetTickCount) ? Win32::GetTickCount() : $$, time(),
}

my $good_et  = q{"0-de-3d06d040"};
my $bad_et   = q{"1-kx-12312313"};
my $good_mod = q{Wed, 21 Apr 2004 00:43:11 GMT};
my $bad_mod  = q{Thu, 20 Apr 2000 00:00:01 GMT};


sub statfrom { $ua->request(GET(@_))->code }
sub r_etag   { statfrom($cgi_et , 'If-None-Match'    , @_) }
sub r_mod    { statfrom($cgi_mod, 'If-Modified-Since', @_) }

print "# Making sure we can see the Internet...\n";
#if( ($ENV{HOME} || '') eq 'c:\s') { ok ok 1 } else
{
  new_ua(); ok statfrom('http://www.perl.org/'),     200;
  new_ua(); ok statfrom('http://interglacial.com/'), 200;
}

print "# Looking for the test CGIs...\n";
print "#  Hitting $cgi_mod\n";
ok statfrom($cgi_mod), 200;
print "#  Hitting $cgi_et\n";
ok statfrom($cgi_et ), 200;

print "# Etagulation...\n";
ok r_etag($good_et), 304;
ok r_etag($bad_et ), 200;

print "# Mod-time...\n";
ok r_mod($good_mod), 304;
ok r_mod($bad_mod ), 200;

print "# That's all!  Bye from ", __FILE__, "\n";
ok 1;

