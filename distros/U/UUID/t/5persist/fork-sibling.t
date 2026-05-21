#
# make sure persist set in child visible in sibling
#
use strict;
use warnings;
use MyTest;
use Try::Tiny;
use File::Temp;

use vars qw($tmpdir $fn0 $fn1);

BEGIN {
    $tmpdir = File::Temp->newdir('UUID-test-XXXXXXXX', TMPDIR => 1, CLEANUP => 0);
    $fn0 = File::Temp::tempnam($tmpdir, 'UUID.test.');
    $fn1 = File::Temp::tempnam($tmpdir, 'UUID.test.');
    ok 1, 'began';
}

use UUID;

ok 1, 'loaded';

ok -d $tmpdir, 'tmpdir exists';
ok !-e $fn0,   'fn0 missing';
ok !-e $fn1,   'fn1 missing';

sub cleanup {
    # close state so Win32 can cleanup
    UUID::_persist(undef);
    1 while unlink $fn0;
    1 while unlink $fn1;
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

    my $kid0 = fork;
    err "fork: $!" unless defined $kid0;

    if (!$kid0) {  # child
        my ($rv,$er) = t{ UUID::_persist($fpath) };
        open my $fh, '>', $fn0 or err "open: $!";
        print $fh (defined($er) ? $er : $rv)."\n";
        close $fh;
        exit 0;
    }

    waitpid $kid0, 0;
    my $status0 = $?;

    my $kid1 = fork;
    err "fork: $!" unless defined $kid1;

    if (!$kid1) {  # child
        my ($rv,$er) = t{ UUID::_persist() };
        open my $fh, '>', $fn1 or err "open: $!";
        print $fh (defined($er) ? $er : $rv)."\n";
        close $fh;
        exit 0;
    }

    waitpid $kid1, 0;
    my $status1 = $?;

    UUID::_persist( $fpath );

    open my $fh0, '<', $fn0 or err "open: $!";
    my $str0 = join '', <$fh0>;
    chomp $str0;

    open my $fh1, '<', $fn1 or err "open: $!";
    my $str1 = join '', <$fh1>;
    chomp $str1;

    is $status0, 0,      'status0 correct';
    is $status1, 0,      'status1 correct';
    is $str0,    1,      'path0 correct';
    is $str1,    $fpath, 'path1 correct';
}

cleanup;
done_testing;
