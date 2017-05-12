package OurTester;

use strict;
use warnings;
use Carp 'croak';

BEGIN {
    unless ( $INC{'Test/Most.pm'} ) {
        croak ("Test::Most must be loaded before ".__PACKAGE__);
    }
}

use Exporter;
our @ISA = 'Exporter';
our ( $DIED, $BAILED );
our @EXPORT_OK = qw($DIED $BAILED dies bails);

use Test::Builder;
my $BUILDER = Test::Builder->new;

sub _set_die {
    _set_test_failure_handler( sub { $DIED = 1 } );
}

sub _set_bail {
    _set_test_failure_handler( sub { $BAILED = 1 } );
}

#
# This is like the normal override for Test::More::ok, but we need to check
# the actual value of of the test status, regardless of whether or not it's a
# TODO test.
#

sub _set_test_failure_handler {
    my $action = shift;
    my $ok     = \&Test::Builder::ok;
    no warnings 'redefine';
    *Test::Builder::ok = sub {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        my $builder = $_[0];
        if ( $builder->{TEST_MOST_test_failed} ) {
            $builder->{TEST_MOST_test_failed} = 0;
            $action->($builder);
        }
        $builder->{TEST_MOST_test_failed} = 0;
        my $result = $ok->(@_);

        # Not a fun interface
        $builder->{TEST_MOST_test_failed} = !( $builder->details )[-1]->{actual_ok};
        return $result;
    };
}

sub dies(&;$) {
    my ( $sub, $message ) = @_;
    _die_or_bail($sub, \&_set_die, $message, \$DIED);
}

sub bails(&;$) {
    my ( $sub, $message ) = @_;
    _die_or_bail($sub, \&_set_bail, $message, \$BAILED);
}

sub _die_or_bail {
    my ($sub, $internal_sub, $message, $die_or_bail) = @_;
    $internal_sub->();
    $BUILDER->todo_start('Planned failure');

    # ignore the error messages as they will be confusing.
    $BUILDER->no_diag(1);
    $sub->();
    $BUILDER->no_diag(0);
    $BUILDER->todo_end;
    Test::More::ok 1, 'arguments are evaluated *before* ok()';
    Test::More::ok $$die_or_bail, $message;
    $$die_or_bail = 0;
}

1;
