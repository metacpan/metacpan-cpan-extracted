package BadSuitesTest;

use strict;
use warnings;

package BadSuitesTest::Null::Tie;

sub TIEHANDLE {
    bless {}, shift;
}

sub PRINT {
}

package BadSuitesTest;

use base 'Test::Unit::TestCase';

use Test::Unit::Lite;

use Test::Unit::TestCase;
use Test::Unit::TestRunner;

sub test_suite_with_syntax_error {
    my $self = shift;
    select select my $fh_null;
    tie *$fh_null, 'BadSuitesTest::Null::Tie';
    my $runner = Test::Unit::TestRunner->new($fh_null, $fh_null);
    eval {
        $runner->start('BadSuite::SyntaxError');
    };
    $self->assert(qr/(Unknown test|Compilation failed)/, "$@");
}

sub test_suite_with_bad_use {
    my $self = shift;
    select select my $fh_null;
    tie *$fh_null, 'BadSuitesTest::Null::Tie';
    my $runner = Test::Unit::TestRunner->new($fh_null, $fh_null);
    eval {
        $runner->start('BadSuite::BadUse');
    };
    $self->assert(qr/(Unknown test|Can\'t locate)/, "$@");
}

1;
