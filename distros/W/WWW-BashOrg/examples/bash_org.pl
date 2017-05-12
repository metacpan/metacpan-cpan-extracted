#!/usr/bin/env perl

use strict;
use warnings;
use lib qw(lib ../lib);
use WWW::BashOrg;

# VERSION

die "Usage: perl $0 quote_number\n"
    unless @ARGV;

my $b = WWW::BashOrg->new;

$b->get_quote(shift)
    or die $b->error . "\n";

use Acme::Dump::And::Dumper;
$Data::Dumper::Useqq=1;
die DnD "$b";

print "$b\n";