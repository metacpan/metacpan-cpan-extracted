
# $Id: 22_create_virdir.t,v 1.8 2007/05/15 00:35:03 Daddy Exp $

use strict;
use warnings;

use ExtUtils::testlib;
use File::Path;
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
if ($^O !~ m!win32!i)
  {
  diag(q'this is not Windows');
  exit 0;
  } # if
my $sMsg = join(';', $oICS->read) || '';
my $iNoIIS = ($sMsg =~ m!can not find adsutil!i);
SKIP:
  {
  skip 'IIS is not installed on this machine?', 6 if $iNoIIS;
  isa_ok($object, 'Win32::IIS::Admin');
  my $sDir = 'QQQperl_WIA_testQQQ';
  my $sRes = $object->path_of_virtual_dir($sDir);
  is($sRes, '', 'IIS does not already contain the path we want to add');
  my $sPath = "C:\\$sDir";
  $sRes = $object->create_virtual_dir(
                                      -dir_name => $sDir,
                                      -path => $sPath,
                                      -executable => 1,
                                     );
  like($sRes, qr'Done\.', 'virtual dir created');
  $sRes = $object->path_of_virtual_dir($sDir);
  is($sRes, $sPath, 'created dir has the correct path');
  # exit 88;  # For testing
  $oICS->start;
  $sRes = $object->create_virtual_dir(
                                      -dir_name => $sDir,
                                      -path => "$sPath/DIFFERENT",
                                      -executable => 1,
                                     );
  $oICS->stop;
  $sMsg = join(';', $oICS->read) || '';
  like($sMsg, qr'already a virtual dir', 'can not create same dir twice');
  ok($object->_config_get_value("/W3SVC/1/Root/$sDir", 'AccessExecute'),
     'new virtual directory has execute access');
  ok($object->_config_get_value("/W3SVC/1/Root/$sDir", 'AccessRead'),
     'new virtual directory has read access');
  ok($object->_config_get_value("/W3SVC/1/Root/$sDir", 'AccessScript'),
     'new virtual directory has script access');
  $sRes = $object->_execute_script('adsutil', 'delete', "/W3SVC/1/Root/$sDir");
  like($sRes, qr'deleted path', 'virtual dir deleted');
  like($sRes, qr"$sDir");
  $sRes = $object->path_of_virtual_dir($sDir);
  is($sRes, '', 'IIS does not contain the path we just deleted');

  # Final cleanup:
  rmtree $sPath;
  } # end of SKIP block

pass;

__END__
