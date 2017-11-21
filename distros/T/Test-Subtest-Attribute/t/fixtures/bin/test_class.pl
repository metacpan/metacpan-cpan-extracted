use strict;
use warnings;

use Test::More;

use lib qw( ./t/fixtures/lib );
use base qw( MyTestClass );

 __PACKAGE__->new(
    module_name => 'Test::Subtest::Attribute'
)->run();

sub subtest_foo :Subtest {
    my ( $self ) = @_;

    ok( 1, 'Dummy subtest foo' );

    return 1;
}

sub subtest_bar :Subtest( 'name for bar' ) {
    my ( $self ) = @_;

    ok( 1, 'Dummy subtest bar' );

    return 1;
}
