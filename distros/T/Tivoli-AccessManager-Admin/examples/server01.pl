#!/usr/bin/perl
use strict;
use warnings;
use Term::ReadKey;

use TAMeb::Admin;
use Data::Dumper;

my ($resp,$serv,$pswd,$name);

ReadMode 2;
print "sec_master password: ";
$pswd = <STDIN>;
ReadMode 0;
chomp $pswd;

my $pd  = TAMeb::Admin::Context->new(password => $pswd );
my $rsp = TAMeb::Admin::Response->new;

$resp = TAMeb::Admin::Server->list($pd);
die $resp->messages unless $resp->isok;

$name = '';
for ( $resp->value ) {
    if ( /webseal/ ) {
	$name = $_;
	last;
    }
}

die "Couldn't find a webseal\n" unless $name;
$serv = TAMeb::Admin::Server->new($pd, name => $name);

$resp = $serv->tasklist;
print Dumper($resp);

$resp = $serv->task("show /test");
print Dumper($resp);


END {
    ReadMode 0;
}
