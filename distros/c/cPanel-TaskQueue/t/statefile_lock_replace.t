#!/usr/bin/perl

use Test::More tests => 1;

use strict;
use warnings;
use autodie;

use Fcntl         ();
use File::Temp    ();
use File::Slurper ();
use Time::HiRes   ();

use cPanel::StateFile ();

my $dir = File::Temp::tempdir( CLEANUP => 1 );

my $file_path = "$dir/the_file";

our $suffix = substr( rand, 2 );

#----------------------------------------------------------------------
# This is a deep test of object internals. For conciseness,
# it recreates objects directly rather than via constructors.
# This is generally bad practice, but the alternatives would be either
# an unwieldy, brittle test or a significant refactor, neither of which
# seems justified here. (Even these tests are more complicated than
# would be ideal.)
#
# Unfortunately, it means that any change to the implementation of
# cPanel::StateFile or cPanel::StateFile::Guard is not unlikely to
# cause a spurious failure here.
#----------------------------------------------------------------------

my $data_obj = bless( {}, 'MockDataObject' );

sub _create_hack_guard {
    my $hack_state = bless {
        data_object   => $data_obj,
        file_name     => $file_path,
        flock_timeout => 60,
      },
      'cPanel::StateFile';

    return bless {
        state_file => $hack_state,
        lock_file  => 'this_does_not_really_exist',
      },
      'cPanel::StateFile::Guard';
}

#----------------------------------------------------------------------

local $SIG{'CHLD'} = 'IGNORE';

my $subprocess_timeout = 60;    # 1 minute

my $renamer_pid = fork or do {
    my $end = time + $subprocess_timeout;

    while ( time < $end ) {
        open my $fh, '>>', $file_path;
        flock $fh, Fcntl::LOCK_EX();

        do { open my $fh, '>>', "$file_path.tmp" };

        Time::HiRes::sleep(0.01);

        rename "$file_path.tmp" => $file_path;
    }

    print "# $$: Renamer process has outlived its usefulness. Exiting …$/";

    exit;
};

for my $iteration ( 1 .. 10 ) {
    note "_open() iteration $iteration …";

    my $hguard = _create_hack_guard();
    $hguard->_open();

    my $fh_inode   = ( stat $hguard->{'state_file'}{'file_handle'} )[1];
    my $path_inode = ( stat $hguard->{'state_file'}{'file_name'} )[1];
    if ( $fh_inode != $path_inode ) {
        die "_open() did flock() a file handle that isn’t the path!";
    }

    note "\t… done.";
}

if ( CORE::kill 'KILL', $renamer_pid ) {
    note "Renamer process ($renamer_pid) sent SIGKILL";
}
else {
    diag "kill() of renamer process ($renamer_pid): $! (timed out?)";
}

#----------------------------------------------------------------------

_create_hack_guard()->update_file();

for my $iteration ( 1 .. 20 ) {
    $suffix = substr( rand, 2 );
    $suffix = substr( $suffix, 0, int rand length $suffix );

    note "Integrity test: running iteration $iteration …";

    my $expected_content = qr<\APID [0-9]+-$suffix\z>;

    my $check_content_cr = sub {
        my $content = File::Slurper::read_binary($file_path);

        if ( $content !~ $expected_content ) {
            die "FAIL: content “$content” doesn’t match expected “$expected_content”";
        }
    };

    my $pid = fork or do {
        alarm $subprocess_timeout;
        my $hack_guard = _create_hack_guard();
        $hack_guard->update_file();
        do { open my $fh, '>', "$dir/wrote-$iteration" };
        $hack_guard->update_file() while 1;
    };

    Time::HiRes::sleep(0.01) while !-e "$dir/wrote-$iteration";

    my $start = time;
    $check_content_cr->() while time < ( $start + 1 );

    if ( !CORE::kill 'KILL', $pid ) {
        diag "kill() of updater process ($pid): $! (timed out?)";
    }

    $check_content_cr->();
}

ok 1, 'Done';

#----------------------------------------------------------------------

package MockDataObject;

sub load_from_cache {
    my ( $self, $fh ) = @_;

    sysread( $fh, $self->{'_content'}, 32768 );

    return;
}

sub save_to_cache {
    my ( $self, $fh ) = @_;

    syswrite( $fh, "PID $$-$main::suffix" );

    return;
}

1;
