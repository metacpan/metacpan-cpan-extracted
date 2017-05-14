package ReturnValue;
use strict;
use FindBin;
use lib ($FindBin::Bin);
use parent 'TestBase';
use Test::Mockify::ReturnValue;
use Test::More;
use Test::Exception;
#------------------------------------------------------------------------
sub testPlan{
    my $self = shift;
    $self->testScalarReturnValue();
    $self->test_thenReturnUndef();
    $self->test_thenThrowError();
    $self->test_thenReturnArray();
    $self->test_thenReturnHash();
    $self->test_thenCall();
    $self->test_NoReturnValueError();
    return;
}
#------------------------------------------------------------------------
sub testScalarReturnValue {
    my $self = shift;

    my $ReturnValue = Test::Mockify::ReturnValue->new();
    $ReturnValue->thenReturn('AString');
    is($ReturnValue->call(),'AString','ReturnValue scalar - is stored and transfered to call');

    $ReturnValue->thenReturn(['AArray']);
    is_deeply($ReturnValue->call(),['AArray'],'ReturnValue - array pointer is stored and transfered to call');

    $ReturnValue->thenReturn({'A'=>'Array'});
    is_deeply($ReturnValue->call(),{'A'=>'Array'},'ReturnValue - Hash pointer is stored and transfered to call');

    $ReturnValue->thenReturn(sub{return 'innerValue';});
    is_deeply($ReturnValue->call()->(),'innerValue','ReturnValue - function pointer is stored and transfered to call');

    return;
}

#------------------------------------------------------------------------
sub test_thenReturnUndef{
    my $self = shift;

    my $ReturnValue = Test::Mockify::ReturnValue->new();
    $ReturnValue->thenReturnUndef();
    is($ReturnValue->call(),undef,'ReturnValue undef - undef is stored and transfered to call.');
}
#------------------------------------------------------------------------
sub test_thenThrowError{
    my $self = shift;

    my $ReturnValue = Test::Mockify::ReturnValue->new();
    $ReturnValue->thenThrowError('ErrorCode');
    throws_ok( sub { $ReturnValue->call() },
       qr/ErrorCode/,
       "proves that the stored error code is transferred to call"
    );
    throws_ok( sub { $ReturnValue->thenThrowError() },
       qr/NoErrorCode/,
       "proves that the error code is valid"
    );
}
#------------------------------------------------------------------------
sub test_thenReturnArray{
    my $self = shift;

    my $ReturnValue = Test::Mockify::ReturnValue->new();
    $ReturnValue->thenReturnArray(['hello','world']);
    my @Result = $ReturnValue->call();
    my @ExpectedResult = ('hello','world');
    is_deeply(\@Result, \@ExpectedResult, 'proves if the Array is transferred to call');

    throws_ok( sub { $ReturnValue->thenReturnArray({'hello' => 'world'}) },
       qr/NoAnArrayRef/,
       "proves that the parameter is an array, not hash"
    );

    throws_ok( sub { $ReturnValue->thenReturnArray('helloworld') },
       qr/NoAnArrayRef/,
       "proves that the parameter is an array, not scalar"
    );
}
#------------------------------------------------------------------------
sub test_thenReturnHash{
    my $self = shift;

    my $ReturnValue = Test::Mockify::ReturnValue->new();
    $ReturnValue->thenReturnHash({'hello' => 'world'});
    my %Result = $ReturnValue->call();
    my %ExpectedResult = ('hello' => 'world');
    is_deeply(\%Result, \%ExpectedResult, 'proves if the Hash is transferred to call');

    throws_ok( sub { $ReturnValue->thenReturnHash(['hello','world']) },
       qr/NoAHashRef/,
       "proves that the parameter is an hash, not array"
    );

    throws_ok( sub { $ReturnValue->thenReturnHash('helloworld') },
       qr/NoAHashRef/,
       "proves that the parameter is an hash, not scalar"
    );
}
#------------------------------------------------------------------------
sub test_thenCall{
    my $self = shift;

    my $ReturnValue = Test::Mockify::ReturnValue->new();
    $ReturnValue->thenCall(sub{return join('-', @_);});
    my $Result = $ReturnValue->call('hello','world');
    is($Result, 'hello-world', 'proves if the function was called when triggering call and the parameters where passed.');

    throws_ok( sub { $ReturnValue->thenCall([]) },
       qr/NoAnCodeRef/,
       "proves that the parameter is an code, not array"
    );

    throws_ok( sub { $ReturnValue->thenCall({}) },
       qr/NoAnCodeRef/,
       "proves that the parameter is an code, not hash"
    );

    throws_ok( sub { $ReturnValue->thenCall('helloworld') },
       qr/NoAnCodeRef/,
       "proves that the parameter is an code, not scalar"
    );
}
#------------------------------------------------------------------------
sub test_NoReturnValueError{
    my $self = shift;
    
    my $ReturnValue = Test::Mockify::ReturnValue->new();
    
    throws_ok( sub { $ReturnValue->call() },
       qr/NoReturnValue/,
       "proves that an error will be thrown if there is no returnvalue provided"
    );
}
__PACKAGE__->RunTest();
1;