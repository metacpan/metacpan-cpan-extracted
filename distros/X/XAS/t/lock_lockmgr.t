#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    
    plan( skip_all => "Author tests not required for installation" );
    
} else {
        
    plan(tests => 10);

}

use Data::Dumper;
use XAS::Lib::Lockmgr;
use Badger::Filesystem 'cwd Dir File';

my $locker = XAS::Lib::Lockmgr->new(
    -breaklock  => 1,
    -deadlocked => 1,    # minutes
    -timeout    => 30,   # seconds
    -attempts   => 5,
);

my $lock;
my ($host, $pid, $time);
my $key = Dir(cwd, 'locked')->path;
my $chost = $locker->env->host;
my $p = ($^O eq 'MSWin32') ? 0 : 1; # windows null process vs unix init

#
# basic tests
#

ok( defined $locker );                     # check that we got something
ok( $locker->isa('XAS::Lib::Lockmgr') );   # and it's the right class

#
# loading and unloading lock module
#

ok( $locker->add(-key => $key, -driver => 'Nolock') );
ok( defined($locker->lockers->{$key}) );
ok( $locker->remove($key) );
ok( ! defined($locker->lockers->{$key}) );
ok( $locker->add(-key => $key, -driver => 'Nolock') );

#
# basic locking
#

ok( $locker->try_lock($key) );
ok( $locker->lock($key) );
ok( $locker->unlock($key) );

