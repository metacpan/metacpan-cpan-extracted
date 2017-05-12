#!/usr/bin/perl -w

use strict;
use warnings;

use lib qw(../lib  lib);

use WWW::DoingItWrongCom::RandImage;

my $wrong = WWW::DoingItWrongCom::RandImage->new;

my $wrong_pic = $wrong->fetch
    or die "Failed to get the picture: " . $wrong->err_msg . "\n";

print "You are doing it wrong: $wrong_pic\n";

=pod

Fetches a random image from www.doingitwrong.com

Usage: perl wrong.pl

=cut