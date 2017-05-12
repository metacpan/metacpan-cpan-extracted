BEGIN { print "1..22\n"; }
use XSTEST::XS1;
#use Devel::Peek 'Dump';


&ok3;
&ok4;

{
	my $a;
	$a = XSTEST::XS1->new1(5);
	#Dump $a;
}
&ok6;
{
	my $a;
	{
		my $x = 7;
		$a = XSTEST::XS1->new2($x);
	}
	#Dump $a;
}
twoface(8);
twoface_main(9);
print "ok 10\n";
print "ok ", &okx(11), "\n";
print "ok ", &ok12, "\n";

print "ok ", &froxbox(1,6,6), "\n";   # 13
$a = bless [2];
print "ok ", &froxbox($a,6,6), "\n";  # 14
$b = [0];
print "ok ", (15 + &froxbox($b,6,6)), "\n"; # 15
print "ok ", &ok16, "\n";
print "ok ", &okzz(17), "\n";
print "ok ", &okzzz(18), "\n";
print "ok ", &oky(19), "\n";

print "ok ", &froybox(19,1), "\n"; # 20
print "ok ", &main::froobox(22,1), "\n"; # 21
print "ok ", &frozbox(22,0), "\n"; # 22
