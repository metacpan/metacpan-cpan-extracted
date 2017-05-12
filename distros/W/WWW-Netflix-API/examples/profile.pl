#!/usr/bin/perl

use strict;
use warnings;
use WWW::Netflix::API;
use XML::Simple;

my $netflix = WWW::Netflix::API->new({
	do('./vars.inc'),
	content_filter => sub { XMLin(@_) },
});

$netflix->REST->Users;
$netflix->Get;
printf "%s %s\n", @{ $netflix->content }{qw/ first_name last_name /};

