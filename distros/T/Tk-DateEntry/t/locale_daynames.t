#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;
use Test::More;
use Tk;
use Tk::DateEntry;

my $mw = eval { MainWindow->new };
if (!$mw) {
    print "1..0 # skip: cannot create MainWindow: $@";
    exit;
}

plan tests => 2;

my $w = $mw->DateEntry;
my @daynames = $w->_get_locale_daynames;
is scalar(@daynames), 7;
SKIP: {
    skip 'accurate check only with de, en, or C locale', 1
	if $ENV{LC_ALL} !~ m{^(de|en|C)};
    if      ($ENV{LC_ALL} =~ m{^de}) {
	is_deeply \@daynames, [qw(So Mo Di Mi Do Fr Sa)];
    } else {
	is_deeply \@daynames, [qw(Sun Mon Tue Wed Thu Fri Sat)];
    }
}

__END__
