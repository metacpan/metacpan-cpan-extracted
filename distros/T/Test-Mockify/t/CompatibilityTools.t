package CompatibilityTools;
use strict;
use FindBin;
use lib ($FindBin::Bin);
use parent 'TestBase';
use Test::Mockify::CompatibilityTools qw (MigrateOldMatchers);
use Test::More;
use Test::Mockify::Matcher qw (
        String
        Number
        HashRef
        ArrayRef
        Object
        Function
        Undef
        Any
);
#------------------------------------------------------------------------
sub testPlan{
    my $self = shift;
    $self->migrateNumbersAnyValue();
    $self->migrateNumbersExpectedValue();
    $self->migrateOthersAnyValue();
    $self->migrateOthersExpectedValue();
    return;
}


#------------------------------------------------------------------------
sub migrateNumbersAnyValue {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $Result = MigrateOldMatchers(['int', 'float']);
    is_deeply($Result, [Number(),Number()] , 'proves int and float will be translated to number and will be also tranfered to the new matcher style. For any values.');

    return;
}
#------------------------------------------------------------------------
sub migrateNumbersExpectedValue {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $Result = MigrateOldMatchers([{'int'=>123}, {'float'=>1.23}]);
    is_deeply($Result, [Number(123),Number(1.23)] , 'proves int and float will be translated to number and will be also tranfered to the new matcher style. For expected Values.');

    return;
}
#------------------------------------------------------------------------
sub migrateOthersAnyValue {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $Result = MigrateOldMatchers(['string', 'hashref', 'arrayref', 'object', 'undef', 'sub', 'any']);
    is_deeply($Result, [String(),HashRef(),ArrayRef(),Object(),Undef(),Function(),Any()] , 'all the others will be also tranfered to the new matcher style. For any Values.');

    return;
}
#------------------------------------------------------------------------
sub migrateOthersExpectedValue {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $Result = MigrateOldMatchers([{'string'=>'a'}, {'hashref' => {'k'=>'v'}}, {'arrayref'=>['1', '2']}, {'object'=> 'Path::to::Object'}]);
    is_deeply($Result, [String('a'),HashRef({'k'=>'v'}),ArrayRef(['1', '2']), Object('Path::to::Object')] , 'all the others will be also tranfered to the new matcher style. For expected Values.');

    return;
}

__PACKAGE__->RunTest();
1;