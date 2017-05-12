#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw(../lib lib);
use WWW::Pastebin::PastebinCom::API;

@ARGV or die "Usage: $0  pastebin.com_login  pastebin.com_password\n";

my $bin = WWW::Pastebin::PastebinCom::API->new(
    api_key => 'a3767061e0e64fef6c266126f7e588f3',
);

$bin->get_user_key( @ARGV[0,1] )
    or die "$bin";

my %info = $bin->get_user_info
    or die "$bin";
use Data::Dumper;
die Dumper \%info;
for ( sort keys %info ) {
    printf "%15s: %s\n", $_, $info{$_};
}

