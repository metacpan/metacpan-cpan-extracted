#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use File::Find ();

# Installed size: what the dist puts in blib, as it would install it.
sub du {
    my $n = 0;
    File::Find::find({ no_chdir => 1, wanted => sub { $n += -s $_ if -f $_ } }, grep { -e } @_);
    return $n;
}
my $mine = du('blib/lib', 'blib/arch');
printf "info installed: %.2f MB\n", $mine / 1e6;
mark_less('installed size', sprintf('%.2f', $mine / 1e6), 1, 1, 'the mark', 'MB');
done();
