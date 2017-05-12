#!/usr/bin/perl -w

# assume these two lines are in all subsequent examples
use strict;
use warnings;

use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {

    plan( skip_all => "Author tests not required for installation" );

} else {

    plan tests => 32;

}

use XAS::Lib::Lockmgr::Filesystem;
use Badger::Filesystem 'cwd Dir File';

my $lockfile;
my ($host, $pid, $time);
my $key = Dir(cwd, 'locked');
my $locker = XAS::Lib::Lockmgr::Filesystem->new(
    -key => $key
);

# basic tests

ok( defined $locker );                                 # check that we got something
ok( $locker->isa('XAS::Lib::Lockmgr::Filesystem') );   # and it's the right class
ok( $locker->key eq $key );

# lock testing

ok( $locker->lock );

ok( ($host, $pid, $time) = $locker->_whose_lock );
ok( $host eq $locker->env->host );
ok( $pid == $$ );
ok( $time->isa('DateTime') );
ok( $locker->try_lock );
ok( $locker->unlock );

# orphaned lock directory

mkdir $key;

ok( ($host, $pid, $time) = $locker->_whose_lock );
ok( ! defined($host) );
ok( ! defined($pid) );
ok( ! defined($time) );

ok( $locker->try_lock );
ok( $locker->lock );
ok( $locker->unlock );

ok( ! -d $key);

# clear a lock with break_lock()

ok( $locker->lock );
ok( $lockfile = $locker->_lockfile );
ok( $lockfile->exists );
ok( $locker->unlock );
ok( ! $lockfile->exists );
ok( $locker->unlock );

# clear a remote lock

mkdir $key;
my $remotelock = File($key, 'remote.1234');
$remotelock->create;

ok( $remotelock->exists );
ok( ($host, $pid, $time) = $locker->_whose_lock );
ok( $host eq 'remote' );
ok( $pid == 1234 );
ok( $time->isa('DateTime') );
ok( $locker->unlock($remotelock) );
ok( ! $remotelock->exists );
ok( ! $key->exists );

