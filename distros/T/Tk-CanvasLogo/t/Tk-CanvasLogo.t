# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Tk-CanvasLogo.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';


use Test::More tests => 1;
BEGIN { use_ok('Tk') };
BEGIN { use_ok('Tk::CanvasLogo') };

#########################


my $top = MainWindow->new();

my $logo = $top->CanvasLogo->pack();

my $turtle1 = $logo -> NewTurtle('me') ;
$turtle1->LOGO_FD(50);


$turtle1->LOGO_RT(90);
$turtle1->LOGO_FD(20);

$turtle1->LOGO_PU;
$turtle1->LOGO_FD(20);

$turtle1->LOGO_PD;
$turtle1->LOGO_FD(20);

MainLoop();


