#!/usr/bin/perl

use lib './lib', '../lib';

use Asterisk::Astman;

use Data::Dumper;

my $astman = new Asterisk::Astman;

$astman->readconfig();

print "PORT: " . $astman->port() . "\n";


$astman->user('test');
$astman->secret('test');
$astman->host('localhost');

$astman->connect();
$astman->authenticate();

$astman->setevent( "testcb()");
$astman->managerloop();
#print Dumper $astman;

sub testcb  {
	my ($test) = @_;
	print "TESTCALLBACK $test\n";
}
