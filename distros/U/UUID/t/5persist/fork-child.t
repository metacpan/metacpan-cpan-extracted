#
# make sure persist set in child visible in parent
#
use strict;
use warnings;
use MyTest;
use Try::Tiny;
use File::Temp;

use vars qw($tmpdir $fn0);

BEGIN {
    $tmpdir = File::Temp->newdir('UUID-test-XXXXXXXX', TMPDIR => 1, CLEANUP => 0);
    $fn0 = File::Temp::tempnam($tmpdir, 'UUID.test.');
    ok 1, 'began';
}

use UUID;

ok 1, 'loaded';

ok -d $tmpdir, 'tmpdir exists';
ok !-e $fn0,   'fn0 missing';

sub cleanup {
    # close state so Win32 can cleanup
    UUID::_persist(undef);
    1 while unlink $fn0;
    rmdir $tmpdir;
}

sub err ($) {
    my $msg = shift;
    cleanup();
    die $msg;
}

sub t (&) {
    my $t = shift;
    my ($rv, $err);
    $rv = try { $t->() }
        catch { $err = $_; undef };
    return $rv, $err;
}

{
    my $fpath = '/some/random/path';

    my $kid = fork;
    err "fork: $!" unless defined $kid;

    if (!$kid) {  # child
        my ($rv,$er) = t{ UUID::_persist($fpath) };
        open my $fh, '>', $fn0 or err "open: $!";
        print $fh (defined($er) ? $er : $rv)."\n";
        close $fh;
        exit 0;
    }

    waitpid $kid, 0;

    my $status = $?;
    open my $fh, '<', $fn0 or err "open: $!";
    my $str = join '', <$fh>;
    chomp $str;

    my $got = UUID::_persist();

    is $status, 0,      'status correct';
    is $str,    1,      'path set';
    is $got,    $fpath, 'path correct';
}

cleanup;
done_testing;
