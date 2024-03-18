#
# make sure many threads all get same default paths.
#
use strict;
use warnings;
use version 0.77;
use Config;

BEGIN {
    unless ($Config{useithreads}) {
        print "1..0 # SKIP no ithreads\n";
        exit 0;
    }
    my $v = version->parse($Config{version});
    if ($v >= '5.9.5' and $v < '5.10.1') {
        #
        # In perl-5.10.0, Perl_parser_dup() was called with a null pointer
        # to indicate (presumably) that there was no parser to dup. The
        # first thing it did was to check for the null then return null.
        # However, Perl_parser_dup was prototyped with a nonnull attribute
        # applied to both its' args, causing the null check to later be
        # optimized away with -O2 on gcc-like compilers.
        #
        # Perl_parser_dup along with the null test and the nonnull
        # attributes were introduced in perl-5.9.5.
        #
        # The nonnull attribute for parser arg was removed in
        # perl-5.10.1-RC1.
        #
        print "1..0 # SKIP threads broken in Perl_parser_dup\n";
        exit 0;
    }
    if ($Config{osname} eq 'openbsd' and $Config{osvers} eq '7.0') {
        print "1..0 # SKIP OpenBSD 7.0 threads broken?\n";
        exit 0;
    }
}

use threads;
use threads::shared;
use Test::More;
use MyNote;
use Try::Tiny;

use vars qw(@OPTS);

BEGIN {
    @OPTS = qw(:persist=foo);
    ok 1, 'began';
}

use UUID @OPTS;

ok 1, 'loaded';

my $cnt = 0;
share($cnt);

sub t (&) {
    my $t = shift;
    my ($rv, $err);
    $rv = try { $t->() } catch { $err = $_; undef };
    return $rv, $err;
}

sub doit {
    note 'in doit()';
    my $c; { lock $cnt; $c = ++$cnt }
    note "c: $c";
    my ($rv,$er) = t{ UUID::_statepath };
    is $rv, 'foo', "path seems correct $cnt";
    is $er, undef, "path correct $cnt";
}

note 'spawn 1'; my $thr1 = threads->create(\&doit); $thr1->join;
note 'spawn 2'; my $thr2 = threads->create(\&doit); $thr2->join;
note 'spawn 3'; my $thr3 = threads->create(\&doit); $thr3->join;

note 'spawn 4'; my $thr4 = threads->create(\&doit);
note 'spawn 5'; my $thr5 = threads->create(\&doit);
note 'spawn 6'; my $thr6 = threads->create(\&doit);
$thr4->join;
$thr6->join;
$thr5->join;

done_testing;
