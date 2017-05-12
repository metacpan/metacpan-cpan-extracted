
# $Id: 88_execfail.t,v 1.6 2007/05/15 00:35:03 Daddy Exp $

use strict;
use warnings;

use ExtUtils::testlib;
use Test::More 'no_plan';
use IO::Capture::Stderr;

BEGIN
 {
 use_ok( 'Win32::IIS::Admin' );
 use_ok( 'IO::Capture::Stderr' );
 } # end of BEGIN block

my $oICS = new IO::Capture::Stderr;
$oICS->start;
my $object = Win32::IIS::Admin->new ();
if ($^O !~ m!win32!i)
  {
  diag(q'this is not Windows');
  exit 0;
  } # if
$oICS->stop;
my $sMsg = join(';', $oICS->read) || '';
my $iNoIIS = ($sMsg =~ m!can not find adsutil!i);
SKIP:
  {
  skip 'IIS is not installed on this machine?', 4 if $iNoIIS;
  isa_ok($object, 'Win32::IIS::Admin');
  $oICS->start;
  print STDERR $object->_execute_script('adsutil', 'totally wrong args');
  $oICS->stop;
  like($oICS->read, qr(Command not recognized), 'expected error description');
  $oICS->start;
  print STDERR $object->_execute_script('adsutil', 'ENUM', '/W3SVC/1/QQQ_no_such_path_QQQ');
  $oICS->stop;
  my $sMsg = $oICS->read;
  like($sMsg, qr(80005000|80070003), 'expected error number');
  like($sMsg, qr(Unable to open specified node|The path requested could not be found),
      'expected error description');
  } # end of SKIP block

__END__
