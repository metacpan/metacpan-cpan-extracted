package MethodSpy;
use strict;
use FindBin;
use lib ($FindBin::Bin);
use parent 'TestBase';
use Test::More;
use Test::Mockify::MethodSpy;
use Test::Exception;
use Test::Mockify::Matcher qw (String Number);
#------------------------------------------------------------------------
sub testPlan{
    test_whenAny();
    test_when();
    return;
}
#------------------------------------------------------------------------
sub test_whenAny {
    my $self = shift;
    my $OriginalMethod = sub {
#        shift;
        my ($Parameter) = @_;
        return 'aReturnValue_'.$Parameter;
    };
    my $MethodSpy = Test::Mockify::MethodSpy->new($OriginalMethod);
    $MethodSpy->whenAny();
    my $ReturnValueOriginalMethod = $MethodSpy->call('something');
    is($ReturnValueOriginalMethod,'aReturnValue_something' , 'proves that the original method was called with parameter.');
 }
#------------------------------------------------------------------------
sub test_when {
    my $self = shift;
    my $OriginalMethod = sub {
#        shift;
        my ($String, $Number) = @_;
        return 'aReturnValue_'.$String.'_'.$Number;
    };
    my $MethodSpy = Test::Mockify::MethodSpy->new($OriginalMethod);
    $MethodSpy->when(String('abc'),Number(123));
    my $ReturnValueOriginalMethod = $MethodSpy->call('abc',123);
    is($ReturnValueOriginalMethod,'aReturnValue_abc_123' , 'proves that the original method was called with parameters.');
 }
__PACKAGE__->RunTest();
1;