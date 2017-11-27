use strict;
use warnings;

use Test::More;
use Test::Subtest::Attribute qw( subtests );


sub subtest_foo :Subtest {
    ok( 1, 'Dummy subtest foo' );
    return 1;
}

sub subtest_bar :Subtest( 'name for bar' ) {
    ok( 1, 'Dummy subtest bar' );
    return 1;
}

sub subtest_prepended :Subtest( 'prepended', 'prepend' ) {
    ok( 1, 'Dummy subtest prepended' );
    return 1;
}

subtest 'test_names' => sub {
    my @expected_subtests = (
        { name => 'prepended' , where => 'prepend' },
        { name => 'foo' },
        { name => 'name for bar', sub_name => 'subtest_bar' },
    );

    my @actual_subtests = subtests()->get_all();
    foreach my $expected ( @expected_subtests ) {
        my $actual = shift @actual_subtests;
        $expected->{package}  ||= 'main';
        $expected->{sub_name} ||= 'subtest_' . $expected->{name};
        $expected->{where}    ||= 'append';

        foreach my $field ( qw( name package sub_name where ) ) {
            next if ! defined $expected->{ $field };
            is( $actual->{ $field }, $expected->{ $field },
                sprintf 'For subtest %s, saw expected %s: %s', $expected->{name}, $field, $expected->{ $field } );

        }
    }

    return;
};

done_testing();
