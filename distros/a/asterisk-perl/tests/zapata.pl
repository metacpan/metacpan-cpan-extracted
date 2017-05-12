#!/usr/bin/perl

use lib './lib', '../lib';

use Asterisk::Conf::Zapata;

use Data::Dumper;

my $zt = new Asterisk::Conf::Zapata;
$zt->configfile('/etc/asterisk/zapata.conf');
$zt->readconfig();

$zt->setvariable('channels', '1-23', 'transfer', 'no');
$zt->setvariable('channels', '25', 'callerid', 'TESTINGINTEST');
$zt->setvariable('channels', '25', 'transfer', 'yes');
$zt->setvariable('channels', '25', 'mailbox', '9999');
$zt->setvariable('channels', '29', 'mailbox', '3333');
$zt->setvariable('channels', '29', 'callerid', 'TESTING');
#$zt->deletechannel('channels', '25');



#print STDERR $zt->cgiform('show', 'channels', ( 'channel' => '1-23' ) );
#print STDERR $zt->cgiform('delete', 'channels', ( 'channel' => '1-23' ) );
#print Dumper $zt;
print STDERR $zt->cgiform('modify', 'channels', ( 'channel' => '1-23', 'callerid' => 'New Callerid Test', 'OLDcallerid' => 'blah', 'OLDchannel' => '1-23' ) );
print STDERR $zt->cgiform('add', 'channels', ( 'channel' => '97', 'callerid' => 'Blah Blah Blah', 'OLDcallerid' => 'blah', 'OLDchannel' => '97') );

print STDERR $zt->cgiform('modify', 'channels', ( 'channel' => '97', 'transfer' => 'yes', 'OLDchannel' => '97' ) );
print STDERR $zt->cgiform('delete', 'channels', ( 'channel' => '1-23', 'doit' => '1') );



#$zt->writeconfig();
#print STDERR $zt->htmlheader('Channel list');
#print STDERR $zt->cgiform('show', 'channels', ( 'channel' => '1-23' ) );
#print STDERR $zt->cgiform('modifyform', 'channels', ( 'channel' => '1-23' ) );
#print STDERR $zt->cgiform('list', 'channels');
#print STDERR $zt->htmlfooter();
