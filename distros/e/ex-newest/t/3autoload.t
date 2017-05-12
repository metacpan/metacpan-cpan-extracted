#!perl -w
BEGIN {
    chdir 't' if -d 't';
    unshift @INC, '../lib';
}
use Test::Simple tests => 2;
use ex::newest;
use lib 'a';
# Try to load a faked Storable (because Storable uses AutoLoader)
use Storable;
ok( $Storable::VERSION > 0.001, 'Newer Storable loaded' );
ok( (grep m!Storable/autosplit.ix!, keys %INC), 'autosplit index loaded' );
