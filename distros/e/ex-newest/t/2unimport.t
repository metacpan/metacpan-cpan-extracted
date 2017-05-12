#!perl -w
BEGIN {
    chdir 't' if -d 't';
    unshift @INC, '../lib';
}
use Test::Simple tests => 8;
use ex::newest;
use lib 'a';
use lib 'b';
no ex::newest;
use Bar;
ok( !grep ref, @INC, 'no hook left in @INC' );
ok( $INC[0] eq 'b', 'b/ directory is in @INC' );
ok( $INC[1] eq 'a', 'a/ directory is in @INC' );
ok( $INC{'lib.pm'} =~ m/\blib\.pm\z/, 'lib.pm no longer overriden' );
ok( $INC{'Bar.pm'} =~ m!\bb/Bar\.pm\z!, "b/Bar.pm in %INC ($INC{'Bar.pm'})" );
ok( $Bar::VERSION == 1, 'Bar VERSION is 1' );
ok( $INC[0] eq 'b', 'b/ directory is in @INC' );
ok( $INC[1] eq 'a', 'a/ directory is in @INC' );
