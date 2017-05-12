package BadUnitsTest;

use strict;
use warnings;

package BadUnitsTest::Buffer::Tie;

sub TIEHANDLE {
    my $buffer = '';
    bless \$buffer, shift;
}

sub PRINT {
    my $self = shift;
    $$self .= join '', @_;
}

sub PRINTF {
    my $self = shift;
    my $fmt = shift;
    $$self .= sprintf $fmt, @_;
}

sub READLINE {
    my $self = shift;
    return $$self;
}

package BadUnitsTest;

use base 'Test::Unit::TestCase';

use Test::Unit::Lite;

use Test::Unit::TestCase;
use Test::Unit::TestRunner;

sub test_suite_with_error_on_set_up {
    my $self = shift;
    select select my $fh_null;
    tie *$fh_null, 'BadUnitsTest::Buffer::Tie';
    my $runner = Test::Unit::TestRunner->new($fh_null, $fh_null);
    $runner->start('BadUnits::WithErrorOnSetUp');
    my $output = <$fh_null>;
    $self->assert(qr/^E.*Problem with set_up/s, $output);
}

sub test_suite_with_error_on_tear_down {
    my $self = shift;
    select select my $fh_null;
    tie *$fh_null, 'BadUnitsTest::Buffer::Tie';
    my $runner = Test::Unit::TestRunner->new($fh_null, $fh_null);
    $runner->start('BadUnits::WithErrorOnTearDown');
    my $output = <$fh_null>;
    $self->assert(qr/^E.*Problem with tear_down/s, $output);
}

sub test_suite_with_failure {
    my $self = shift;
    select select my $fh_null;
    tie *$fh_null, 'BadUnitsTest::Buffer::Tie';
    my $runner = Test::Unit::TestRunner->new($fh_null, $fh_null);
    $runner->start('BadUnits::WithFailure');
    my $output = <$fh_null>;
    $self->assert(qr/^F.*String/s, $output);
}

1;
