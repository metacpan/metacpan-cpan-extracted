package MyTestClass;

use strict;
use warnings;

use Test::More;
use Test::Subtest::Attribute qw( subtests );

sub new {
    my ( $class, @args ) = @_;

    my $self = bless { @args }, $class;

    $self->{subtests} ||= subtests();

    return $self;
}

sub run {
    my ( $self, @args ) = @_;

    if ( $self->{module_name} ) {
        $self->{subtests}->prepend( name => 'require_ok', coderef => \&subtest_require_ok );
    }

    $self->{subtests}->run( invocant => $self, @args );
    done_testing();

    return;
}

sub subtest_require_ok {
    my ( $self ) = @_;

    return  require_ok( $self->{module_name} );
}

1;
