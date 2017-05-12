#!/usr/bin/perl
#
# cache refresh cron job
# version 1.02	6-14-13	michael@bizsystems.com
#
require URBL::Prepare;

my $whitefile =
  'http://spamassasin.googlecode.com/svn-history/r6/trunk/share/spamassassin/25_uribl.cf';

my $tldfile2 = 'http://george.surbl.org/two-level-tlds';
my $tldfile3 = 'http://george.surbl.org/three-level-tlds';

my $cachedir  = $ARGV[0];
my $level2    = $cachedir .'/level2';
my $level3    = $cachedir .'/level3';
my $white     = $cachedir .'/white'; 

mkdir $cachedir unless $cachedir && -d $cachedir;

my($code,$msg) = URBL::Prepare->loadcache($whitefile,$white);
print $0,' ',$msg,"\n" unless $code == 200 || $code == 304;
($code,$msg) = URBL::Prepare->loadcache($tldfile2,$level2);
print $0,' ',$msg,"\n" unless $code == 200 || $code == 304;
($code,$msg) = URBL::Prepare->loadcache($tldfile3,$level3);
print $0,' ',$msg,"\n" unless $code == 200 || $code == 304;
