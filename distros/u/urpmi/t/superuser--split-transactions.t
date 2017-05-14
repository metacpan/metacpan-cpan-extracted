#!/usr/bin/perl

# packages "a" and "b" require each other, and so must installed in same transaction
# package "c" requires "a" and can be installed later on
# package "d" has no deps and can be installed alone in its transaction, with no particular timing
use strict;
use lib '.', 't';
use helper;
use urpm::util;
use Test::More 'no_plan';

need_root_and_prepare();

my $name = 'split-transactions';
urpmi_addmedia("$name $::pwd/media/$name");    

test_urpmi("--auto --split-length 1 c d",
	acceptable_trans_orders(4,
				[ [ qw(a b) ], ['c'], ['d'] ],
				[ [ qw(a b) ], ['d'], ['c'] ],
				[ [ qw(b a) ], ['c'], ['d'] ],
				[ [ qw(b a) ], ['d'], ['c'] ],
				[ ['d'], [ qw(b a) ], ['c'] ],
				[ ['d'], [ qw(a b) ], ['c'] ],
	));
check_installed_names('a', 'b', 'c', 'd');

sub test_urpmi {
    my ($para, @wanted) = @_;
    my $s = run_urpm_cmd("urpmi $para");
    print $s;

    $s =~ s/\s*#{40}#*//g;
    $s =~ s/^installing .*//gm;
    $s =~ s/^SECURITY.*//gm;
    $s =~ s/^\n//gm;

    ok(member($s, @wanted), "$wanted[0] in $s");
}

sub acceptable_trans_orders {
    my ($total, @solutions) = @_;
    my @res;
    foreach (@solutions) {
        my $count = 0;
	    push @res, join("\n", map {
		    ("Preparing...", map { $count++; "      $count/$total: $_" } @$_) } @$_) . "\n";
    }
    @res;
}
