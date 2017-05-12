#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw(../lib lib);
use WWW::Pastebin::PastebinCom::API;

@ARGV or die "Usage: $0 [paste URL or ID]\n";

my $bin = WWW::Pastebin::PastebinCom::API->new;

my $paste = $bin->get_paste( shift )
    or die "$bin";

print "$paste\n";