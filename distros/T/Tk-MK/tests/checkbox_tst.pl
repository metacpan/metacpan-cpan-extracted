#!/home/opcdev/local/bin/perl -w
use Tk;
use Tk::Checkbox;

my $var = 'Down';
my $mw = MainWindow->new();

my $cb1 = $mw->Checkbox (
    -variable => \$var,
    -command  => \&test_cb,
    -onvalue  => 'Up',
    -offvalue => 'Down',
	#-noinitialcallback => '1',
)->pack;

$cb1->configure( '-onvalue'  => 'rauf' );
$cb1->configure( '-offvalue'  => 'runter' );

Tk::MainLoop;

sub test_cb
{
    print "test_cb called with [@_], \$var = >$var<\n";
}
