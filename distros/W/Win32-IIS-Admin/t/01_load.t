
# $Id: 01_load.t,v 1.7 2007/05/01 00:35:56 Daddy Exp $

use strict;
use warnings;

use ExtUtils::testlib;
use Test::More 'no_plan';
use IO::Capture::Stderr;

BEGIN
 {
 use_ok( 'Win32::IIS::Admin' );
 } # end of BEGIN block

my $oICS = new IO::Capture::Stderr;
$oICS->start;
my $object = Win32::IIS::Admin->new ();
$oICS->stop;
my $o = $^O;
# diag(qq'dollarO is =$o=');
if ($^O !~ m!win32!i)
  {
  diag(q'this is not Windows');
  exit 0;
  } # if
my $sMsg = join(';', $oICS->read) || '';
# diag(qq'sMsg is =$sMsg=');
my $iNoIIS = ($sMsg =~ m!can not find adsutil!i);
SKIP:
  {
  skip 'IIS is not installed on this machine?', 1 if $iNoIIS;
  if (! isa_ok($object, 'Win32::IIS::Admin'))
    {
    diag($sMsg);
    diag($oICS->read);
    } # if
  } # end of SKIP block


__END__

