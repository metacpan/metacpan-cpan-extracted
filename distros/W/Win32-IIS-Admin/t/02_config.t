
# $Id: 02_config.t,v 1.12 2008/11/07 00:48:36 Martin Exp $

use strict;
use warnings;

use Data::Dumper;
use ExtUtils::testlib;
use Test::More 'no_plan';
use IO::Capture::Stderr;

BEGIN
 {
 use_ok( 'Win32::IIS::Admin' );
 } # end of BEGIN block

my $oICS = new IO::Capture::Stderr;
$oICS->start;
my $o = Win32::IIS::Admin->new ();
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
  skip 'IIS is not installed on this machine?', 11 if $iNoIIS;
  isa_ok($o, 'Win32::IIS::Admin');

  my $sVersion = $o->iis_version;
  ok($sVersion);
  diag(qq{reported to be IIS version $sVersion});

  my $iTO = $o->get_timeout();
  diag("Your CGITimeout is $iTO seconds (in IIS 6.0 it is 300 by default)");
  like($iTO, qr(\A\d+\z), 'timeout is an integer');

  my $s = $o->_config_get_value('/Logging', 'KeyType');
  diag("Your Logging KeyType is '$s' (it should be 'IIsLogModules' in IIS 6.0)");

  my $i = $o->_config_get_value('/W3SVC/AppPools', 'PingingEnabled');
  my $sNot = $i ? '' : ' not';
  diag("Pinging is$sNot enabled in your AppPools (in IIS 6.0 it is enabled by default)");

  $i = $o->_config_get_value('/W3SVC/AppPools', 'SMPAffinitized');
  $sNot = $i ? '' : ' not';
  diag("SMP is$sNot affinitized in your AppPools (in IIS 6.0 it is not affinitized by default)");

  my $raCED = $o->_config_get_value('/W3SVC/Info', 'CustomErrorDescriptions');
  isa_ok($raCED, 'ARRAY', 'CED list');
  my $iCED = $#{$raCED} + 1;
  diag("Your server has $iCED custom error messages defined (IIS 6.0 installs 47 by default)");

  if ($ENV{RUN_DESTRUCTIVE_TESTS})
    {
    my $sTestPath = '/W3SVC/Filters/Compression/deflate';
    my $sTestKey = 'HcFileExtensions';
    my $raOrig = $o->_config_get_value($sTestPath, $sTestKey);
    # Test for set/get a list value:
    my @a = qw( ABC def GHI xyz );
    $o->_config_set_value($sTestPath, $sTestKey, @a);
    my $ra = $o->_config_get_value($sTestPath, $sTestKey);
    isa_ok($ra, 'ARRAY', 'result list');
    is(scalar(@a), scalar(@$ra), 'lists are same length');
    foreach my $i (0..$#a)
      {
      is($a[$i], $ra->[$i], qq"element $i matches");
      } # foreach
    # Put back the original values:
    $o->_config_set_value($sTestPath, $sTestKey, @$raOrig);

    # Test the extension_restriction methods:
    my $sPath = 'C:\\inetpub\\_perl_wia_test_.exe';
    my $sGroup = 'PERLWIATESTGROUP';
    my $sDesc = 'Test Description';
    $raOrig = $o->_config_get_value('/W3SVC', 'WebSvcExtRestrictionList');
    isa_ok($raOrig, 'ARRAY', 'result list');
    # print STDERR Dumper($ra);
    diag(sprintf("Before adding one extension restriction, there are %d", scalar(@$raOrig)));
    $o->add_extension_restriction(
                                  -allow => 0,
                                  -path => $sPath,
                                  -groupid => $sGroup,
                                  -description => $sDesc,
                                 );
    $ra = $o->_config_get_value('/W3SVC', 'WebSvcExtRestrictionList');
    isa_ok($ra, 'ARRAY', 'result list');
    # print STDERR Dumper($ra);
    diag(sprintf("After adding one extension restriction, there are %d", scalar(@$ra)));
    $o->remove_extension_restriction($sPath);
    $ra = $o->_config_get_value('/W3SVC', 'WebSvcExtRestrictionList');
    isa_ok($ra, 'ARRAY', 'result list');
    # print STDERR Dumper($ra);
    diag(sprintf("After removing extension restriction (by path), there are %d", scalar(@$ra)));
    for (1..3)
      {
      $o->add_extension_restriction(
                                    -allow => 0,
                                    -path => $sPath,
                                    -groupid => $sGroup,
                                    -description => "$sDesc $_",
                                   );
      } # for
    $ra = $o->_config_get_value('/W3SVC', 'WebSvcExtRestrictionList');
    isa_ok($ra, 'ARRAY', 'result list');
    # print STDERR Dumper($ra);
    diag(sprintf("After adding three extension restrictions, there are %d", scalar(@$ra)));
    $o->remove_extension_restriction_group($sGroup);
    $ra = $o->_config_get_value('/W3SVC', 'WebSvcExtRestrictionList');
    isa_ok($ra, 'ARRAY', 'result list');
    # print STDERR Dumper($ra);
    diag(sprintf("After removing extension restrictions (by group), there are %d", scalar(@$ra)));
    # Put back the original values:
    $o->_config_set_value('/W3SVC', 'WebSvcExtRestrictionList', @{$raOrig});
    } # if RUN_DESTRUCTIVE_TESTS
  pass;
  } # end of SKIP block
pass;

__END__
