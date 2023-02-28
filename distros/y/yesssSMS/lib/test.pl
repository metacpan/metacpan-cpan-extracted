#!/usr/bin/perl

use strict;
require "./yesssSMS.pm";

my $sms = yesssSMS->new();
$sms->login('06769510102','x16802');

if ($sms->getLastResult!=0)
{
	print STDERR "Error during login: ".$sms->getLastError()."\n";
	exit;
}

$sms->sendmessage('00436769510102','Testnachricht');
if ($sms->getLastResult!=0)
{
	print STDERR "Error during sendmessage: ".$sms->getLastError()."\n";
	exit;
}

$sms->logout();
if ($sms->getLastResult!=0)
{
	print STDERR "Error during logout: ".$sms->getLastError()."\n";
	exit;
}
