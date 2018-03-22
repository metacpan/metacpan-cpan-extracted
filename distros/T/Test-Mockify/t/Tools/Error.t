package Error;
use strict;

use FindBin;
use lib ($FindBin::Bin.'/..');

use parent 'TestBase';
use Test::Exception;
use Test::Mockify::Tools qw (Error);
use Test::More;
#------------------------------------------------------------------------
sub testPlan{
    my $self = shift;
    $self->test_ErrorWithoutMessage();
    $self->test_ErrorWithoutMockedMethod();
    $self->test_ErrorWithoutMockedMethodAndDataBlock();
    $self->test_ErrorWithMockedMethod();
    return;
}
#------------------------------------------------------------------------
sub test_ErrorWithoutMessage {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $RegEx = $self->_getErrorRegEx_ErrorWithoutMockedMethod();
    throws_ok( sub{Error()},
        qr/^Message is needed at .*Tools.pm line \d+.$/sm,
        "$SubTestName - tests if Error works well"
    );
    return;
}
#------------------------------------------------------------------------
sub test_ErrorWithoutMockedMethod {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $RegEx = $self->_getErrorRegEx_ErrorWithoutMockedMethod();
    throws_ok( sub{Error('AnErrorMessage')},
        qr/^$RegEx/sm,
        "$SubTestName - tests if Error works well"
    );
    return;
}
#------------------------------------------------------------------------
sub test_ErrorWithMockedMethod {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $RegEx = $self->_getErrorRegEx_ErrorWithMockedMethod();
    throws_ok( sub{Error('AnErrorMessage',{'Method'=>'aMockedMethod'})},
        qr/^$RegEx$/sm,
        "$SubTestName - tests if Error works well"
    );
    return;
}
#------------------------------------------------------------------------
sub test_ErrorWithoutMockedMethodAndDataBlock {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $RegEx = $self->_getErrorRegEx_ErrorWithoutMockedMethodAndDataBlock();
    throws_ok( sub{Error('AnErrorMessage',{'key'=>'value'})},
        qr/^$RegEx$/sm,
        "$SubTestName - tests if Error works well"
    );
    return;
}

#------------------------------------------------------------------------
# helpers
#------------------------------------------------------------------------
sub _getErrorRegEx_ErrorWithoutMockedMethod {
    return <<'END_REGEX';
AnErrorMessage:
MockedMethod: -no method set-
Data:\{\}
Test::Exception::throws_ok,.*t\/.*Error.t\(line \d+\)
Error::test_ErrorWithoutMockedMethod,.*t\/.*Error.t\(line \d+\)
Error::testPlan,.*t\/.*TestBase.pm\(line \d+\)
TestBase::RunTest,.*t.*\/Error.t\(line \d+\)
END_REGEX
END;
}
#------------------------------------------------------------------------
sub _getErrorRegEx_ErrorWithMockedMethod {
    return <<'END_REGEX';
AnErrorMessage:
MockedMethod: aMockedMethod
Data:\{\}
Test::Exception::throws_ok,.*t\/.*Error.t\(line \d+\)
Error::test_ErrorWithMockedMethod,.*t\/.*Error.t\(line \d+\)
Error::testPlan,.*t\/.*../TestBase.pm\(line \d+\)
TestBase::RunTest,.*t\/.*Error.t\(line \d+\)
END_REGEX
END;
}
#------------------------------------------------------------------------
sub _getErrorRegEx_ErrorWithoutMockedMethodAndDataBlock {
    return <<'END_REGEX';
AnErrorMessage:
MockedMethod: -no method set-
Data:\{key='value'\}
Test::Exception::throws_ok,.*t\/.*Error.t\(line \d+\)
Error::test_ErrorWithoutMockedMethodAndDataBlock,.*t\/.*Error.t\(line \d+\)
Error::testPlan,.*t\/.*TestBase.pm\(line \d+\)
TestBase::RunTest,.*t\/.*Error.t\(line \d+\)
END_REGEX
END;
}
__PACKAGE__->RunTest();
1;