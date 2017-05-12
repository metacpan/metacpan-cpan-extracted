#!/usr/bin/perl

use strict;
use warnings;
use WWW::Lovefilm::API;
use XML::Simple;

my $lovefilm = WWW::Lovefilm::API->new({
	do('vars.inc'),
	content_filter => sub { XMLin(@_) },
});

$lovefilm->REST->Users;
$lovefilm->Get;
if ($lovefilm->content) {
    printf "%s %s\n", @{ $lovefilm->content }{qw/ first_name last_name /};
}
else {
    print "no content\n";
}
