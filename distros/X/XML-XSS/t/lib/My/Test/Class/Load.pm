package My::Test::Class::Load;

use strict;
use warnings;

use base qw( Test::Class::Load );

sub is_test_class {
    my ( $class, $file, $dir ) = @_;

    # return unless it's a .pm (the default)
    return unless $class->SUPER::is_test_class( $file, $dir );

    # and we don't want the infrastructure stuff
    return $file !~ m{My.*Test.*Class};
}

1;

