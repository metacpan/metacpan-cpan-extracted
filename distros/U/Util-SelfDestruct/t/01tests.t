
chdir('t') if -d 't';

use Config;
use Test::More;

if ($^O =~ /win32/i) {
	plan skip_all => "01test.t unit tests will not work under MSWin32";
} else {
	plan tests => 12;
}

use File::Spec::Functions qw(catdir);

my $perl = '#!/bin/env perl';
if ($Config{scriptdir} && -f catdir($Config{scriptdir},'perl')) {
	$perl = catdir($Config{scriptdir},'perl');
}

my $filename = write_script('use Util::SelfDestruct;');
ok(`./$filename 2>&1` =~ /I executed okay/ms);
ok(`./$filename 2>&1` !~ /I executed okay/ms);
ok(`./$filename 2>&1` =~ /die on subsequent execution/ms);
unlink $filename;

$filename = write_script('use Util::SelfDestruct("unlink");');
ok(`./$filename 2>&1` =~ /unlink after execution.+I executed okay/ms);
ok(!-f $filename);
unlink $filename if -f $filename;

my $tomorrow = isodate(time()+(3600*24));
$filename = write_script("use Util::SelfDestruct(after => '$tomorrow');");
ok(`./$filename 2>&1` =~ /I executed okay/ms);
ok(`./$filename 2>&1` !~ /die on subsequent execution/ms);
ok(-f $filename);
unlink $filename;

my $earlier = isodatetime(time()-3600);
$filename = write_script("use Util::SelfDestruct(before => '$earlier');");
ok(`./$filename 2>&1` =~ /I executed okay/ms);
ok(`./$filename 2>&1` =~ /I executed okay/ms);
unlink $filename;

$filename = write_script("use Util::SelfDestruct(after => '$earlier');");
ok(`./$filename 2>&1` !~ /I executed okay/ms);
$earlier =~ s/\D+//g;
ok(`./$filename 2>&1` =~ /Util::SelfDestruct:.+>\s+$earlier/ms);
unlink $filename;

sub isotime {
	return (split(/\s+/,isodatetime(@_)))[1];
}

sub isodate {
	return (split(/\s+/,isodatetime(@_)))[0];
}

sub isodatetime {
	my $time = shift || time();
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)
		= localtime($time);
	$year += 1900;
	$mon++;
	my $datetime = sprintf('%04d%02d%02d %02d%02d%02d',
				$year,$mon,$mday, $hour,$min,$sec);
	return $datetime;
}

sub write_script {
	my $str = shift;
	my $filename = '01tests_'.time().$$.int(rand(999)).'.pl';
	open(T,">$filename") || die $!;
	print T <<FOO;
#!$perl -w
use strict;
use lib qw(../lib);
$str
print "I executed okay\n";
FOO
	close(T) || warn $!;
	chmod(0700,$filename);
	return $filename;
}







