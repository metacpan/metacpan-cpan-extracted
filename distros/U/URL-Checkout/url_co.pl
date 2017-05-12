#! /usr/bin/perl -w
#
# url_checkout.pl -- demo script for URL::Checkout
#
# 2010, jnw@cpan.org
# This script is in the public domain.

use FindBin;
BEGIN { unshift @INC, "$1/blib/lib" if $FindBin::Bin =~ m{(.*)} };
use URL::Checkout;
use Data::Dumper;

my $f = URL::Checkout->new(verbose => 1);
my $url = shift or die "Usage: $0 [meth:]URL [destdir]\n\n".$f->describe;

$f->method($1) if $url =~ s{^(\w+):(.*?://)}{$2};
die Dumper $f->find_method($url) if $ENV{URL_CO_DUMP};

$f->dest(shift);
$f->get($url) or die "get failed.\n";
print $f->dest() . "\n";

