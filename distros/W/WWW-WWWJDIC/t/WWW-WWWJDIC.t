#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Test::More;
use WWW::WWWJDIC 'get_mirrors';
my %mirrors = get_mirrors ();
like ($mirrors{usa}, qr/edrdg/);
done_testing ();
