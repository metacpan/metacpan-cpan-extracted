use strict;
use Benchmark qw/ timethese cmpthese /;
use Win32::MMF;
use Win32::MMF::Shareable;

# -------------------------------------------------------------

# initialization - OO
my $ns = new Win32::MMF( -namespace => "shareable" )
    or die "Can not create shared memory";

# initialization - TIE
tie my $shvar1, "Win32::MMF::Shareable", 'Var1';
tie my $shvar2, "Win32::MMF::Shareable", 'Var2';
tie my $shvar3, "Win32::MMF::Shareable", 'Var3';

# -------------------------------------------------------------

# test data set
my $var1 = "Hello world!";
my $dirvar1;


# -------------------------------------------------------------

# benchmark

sub STORE_setvar
{
    $ns->setvar('Var1', $var1);
}

sub STORE_tiedvar
{
    $shvar1 = $var1;
}

sub STORE_direct
{
    $dirvar1 = $var1;
}

cmpthese( timethese (
     1000000,
     {
        'setvar' => '&STORE_setvar',
        'tiedvar' => '&STORE_tiedvar',
        'direct' => '&STORE_direct',
     } ) );

