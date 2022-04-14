#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/mocks";

use Test::More tests => 5;
use File::Path ();
use File::Temp;

use cPanel::StateFile;
use MockCacheable;

my $tmpdir   = File::Temp->newdir();
my $dir      = "$tmpdir/state_test";
my $file     = "$dir/state_dir/state_file";
my $lockname = "$file.lock";

my $mock_obj = MockCacheable->new;
my $state    = cPanel::StateFile->new( { state_file => $file, data_obj => $mock_obj } );

{
    my $guard = $state->synch();
    eval { $guard->call_unlocked(); };
    like( $@, qr/Missing coderef/, 'Correctly handle missing arg to call_unlocked' );

    eval { $guard->call_unlocked('fred'); };
    like( $@, qr/Missing coderef/, 'Correctly handle wrong argument to call_unlocked' );

    $guard->call_unlocked(
        sub {
            eval {
                $guard->call_unlocked( sub { } );
            };
            like( $@, qr/Cannot nest call_unlocked/, 'Correctly identify nested call_unlocked calls.' );
        }
    );

    $guard->call_unlocked(
        sub {
            eval { $guard->update_file() };
            like( $@, qr/Cannot update_file/, 'Cannot relock inside unlock call.' );
        }
    );

    eval {
        $guard->call_unlocked(
            sub {
                die 'test exception';
            }
        );
    };
    like( $@, qr/test exception/, 'Exceptions are passed out of call correctly.' );
}
