#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw(../lib lib);
use WWW::Pastebin::PastebinCom::API;

@ARGV or die "Usage: $0 file_to_paste\n";

my $bin = WWW::Pastebin::PastebinCom::API->new(
    api_key => 'a3767061e0e64fef6c266126f7e588f3',
);

open my $fh, '<', shift or die "Failed to open paste file. $!";

$bin->paste( do{undef $/; <$fh>;} )
    or die "$bin";

print "Your paste is at $bin\n";
