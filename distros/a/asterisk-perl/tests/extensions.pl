#!/usr/bin/perl

use lib './lib','../lib';

use Asterisk::Extension;
use Data::Dumper;


$ext = new Asterisk::Extension;

$ext->readconfig('/etc/asterisk/extensions.conf');

my @arr= $ext->getextensionarr('demo','1234');
for (@arr) {

	$x++;
#	print "$x $_\n" if ($_);
}

#$ext->getcontextarr();

print "\n";

#print Dumper $ext;

print Dumper $ext->matchextension('local', '559');

$ext->writeconfig('/tmp/test.config');
