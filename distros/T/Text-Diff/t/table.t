#!/usr/bin/perl

use strict ;
use Test ;
use Text::Diff ;

sub t($$$$) {
    my ( $a, $b, $exp_a, $exp_b ) = @_;
    my $d = diff \$a, \$b, { STYLE => "Table" };
    my $re = qr/^\*.*\|\Q$exp_a\E\s*\|\Q$exp_b\E\s*\*$/m;

    ## Older Test.pms don't support ok( $foo, qr// );
    $d =~ $re
        ? ok 1
        : ok "\n" . $d, "a match for " . $re;
}

sub slurp { open SLURP, "<" . shift or die $! ; return join "", <SLURP> }

my @tests = (
sub { t " ",  "\t",  "\\s", "\\t" },
sub { t " a", "\ta", " a", "\\ta" },
sub { t "a ", "a\t", "a\\s", "a\\t" },
sub { t "\t", "\\t", "\\t", "\\\\t" },
sub { t "\ta", "\tb", "        a", "        b" },
sub { t "-\ta", "-\tb", "-       a", "-       b" },
sub { t "\\ta", "\\tb", "\\ta", "\\tb" },
) ;

plan tests => scalar @tests ;

$_->() for @tests ;
