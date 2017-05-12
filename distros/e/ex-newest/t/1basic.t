#!perl -w
BEGIN {
    chdir 't' if -d 't';
    unshift @INC, '../lib';
}
use Test::Simple tests => 8;
use ex::newest;
use lib 'a';
use lib 'b';
use Foo;
use Bar;
ok( ref $INC[0] eq 'ex::newest', 'ex::newest object is in @INC' );
ok( $INC[1] eq 'b', 'b/ directory is in @INC' );
ok( $INC[2] eq 'a', 'a/ directory is in @INC' );
ok( $INC{'lib.pm'} eq $INC{'ex/newest.pm'}, 'lib.pm overriden' );
ok( $INC{'Foo.pm'} =~ m!\bb/Foo\.pm\z!, "b/Foo.pm in %INC ($INC{'Foo.pm'})" );
ok( $Foo::VERSION == 2, 'Foo VERSION is 2' );
ok( $INC{'Bar.pm'} =~ m!\ba/Bar\.pm\z!, "a/Bar.pm in %INC ($INC{'Bar.pm'})" );
ok( $Bar::VERSION == 2, 'Bar VERSION is 2' );
