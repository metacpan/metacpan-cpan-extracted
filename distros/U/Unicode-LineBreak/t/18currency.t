use strict;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/..";
require 't/lb.pl';

BEGIN { plan tests => 96 }

my @opts = (Context => 'EASTASIAN');

foreach my $c (0x20A0..0x20CF) {
    my $gc = Unicode::GCString->new(sprintf('%c', $c), @opts);
    if ($c == 0x20A9) {
	is($gc->columns, 1, 'U+20A9 WON SIGN eaw:H');
    } elsif ($c == 0x20AC) {
	is($gc->columns, 2, 'U+20AC EURO SIGN eaw:A');
    } else {
	is($gc->columns, 1,
	    sprintf 'U+%04X eaw:N', $c);
    }
    if ($c == 0x20A7) {
	is($gc->lbc, Unicode::LineBreak::LB_PO(),
	    'U+20A7 PESETA SIGN lbc:PO');
    } elsif ($c == 0x20B6) {
	is($gc->lbc, Unicode::LineBreak::LB_PO(),
	    'U+20B6 LIVRE TOURNOIS SIGN lbc:PO');
    } elsif ($c == 0x20BB) {
	is($gc->lbc, Unicode::LineBreak::LB_PO(),
	    'U+20BB NORDIC MARK SIGN lbc:PO');
    } elsif ($c == 0x20BE) {
	is($gc->lbc, Unicode::LineBreak::LB_PO(),
	    'U+20BE LARI SIGN lbc:PO');
    } else {
	is($gc->lbc, Unicode::LineBreak::LB_PR(),
	    sprintf 'U+%04X lbc:PR', $c);
    }
}

