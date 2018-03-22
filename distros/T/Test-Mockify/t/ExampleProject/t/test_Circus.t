package test_KidsShow_NewClown;
use strict;
use FindBin;

use lib ("$FindBin::Bin/../.."); #Path to test base
use lib ("$FindBin::Bin/../../.."); #Path to example project
use parent 'TestBase';
use Test::More;
use Test::Exception;
use Test::Mockify::Sut;
#----------------------------------------------------------------------------------------
sub testPlan{
    my $self = shift;

    $self->test_WithoutMock();
    $self->test_WithMock ();
    $self->test_ErrorShowCase();
}
#----------------------------------------------------------------------------------------
sub test_WithoutMock {
    my $self = shift;
    my $SubTestName = (caller(0))[3];
    my $Mockify = Test::Mockify::Sut->new('ExampleProject::Circus',[]);
    my $Sut = $Mockify->getMockObject();
    is_deeply($Sut->getLineUp(), [
        'Pulled bunny',
        'The historical lake chopper',
        'The mighty seesaw',
    ], "$SubTestName - Prove unmocked result");
}
#----------------------------------------------------------------------------------------
sub test_WithMock {
    my $self = shift;
    my $SubTestName = (caller(0))[3];
    my $Mockify = Test::Mockify::Sut->new('ExampleProject::Circus',[$self->_createMagican()]);
    $Mockify
        ->mockStatic('t::ExampleProject::KidsShow::TimberBeam::GetLineUpName')
        ->when()
        ->thenReturn('TimberBeam test show name');

    $Mockify->mockConstructor('t::ExampleProject::KidsShow::SeeSaw', $self->_createSeeSaw());

    my $Sut = $Mockify->getMockObject();
    is_deeply($Sut->getLineUp(), [
        'Magician test show name',
        'TimberBeam test show name',
        'Seesaw test show name',
    ], "$SubTestName - Prove mocked result");
}
#----------------------------------------------------------------------------------------
sub test_ErrorShowCase {
    my $self = shift;
    my $SubTestName = (caller(0))[3];
    my $Mockify = Test::Mockify::Sut->new('ExampleProject::Circus',[$self->_createMagican()]);
    throws_ok( sub { $Mockify->mock('getLineUp') },
                   qr/Don't mock the code you like to test/sm,
                   "$SubTestName - Show case why to use Mockify::Sut"
         );
    ;
}
#----------------------------------------------------------------------------------------
sub _createMagican {
    my $self = shift;

    my $aParameterList = [];
    my $Mockify = Test::Mockify->new(
       't::ExampleProject::MagicShow::Magician',
       $aParameterList
    );
    $Mockify->mock('getLineUpName')->when()->thenReturn('Magician test show name');
    return $Mockify->getMockObject();
}
#----------------------------------------------------------------------------------------
sub _createSeeSaw {
    my $self = shift;

    my $aParameterList = [];
    my $Mockify = Test::Mockify->new(
       't::ExampleProject::KidsShow::SeeSaw',
       $aParameterList
    );
    $Mockify->mock('getLineUpName')->when()->thenReturn('Seesaw test show name');
    return $Mockify->getMockObject();
}

__PACKAGE__->RunTest();
1;