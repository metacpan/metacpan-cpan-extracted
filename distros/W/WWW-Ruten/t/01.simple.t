#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 1;
use WWW::Ruten;
use Encode qw(encode_utf8);

my $ruten = WWW::Ruten->new;

$ruten->search("iPod");
$ruten->each(
    sub {
        my ($self) = @_;

        diag encode_utf8 $self->{title};
        diag encode_utf8 $self->{url};
    }
);

ok("Program finished without problem.");

