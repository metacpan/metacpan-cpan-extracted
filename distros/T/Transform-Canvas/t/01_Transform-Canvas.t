# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Transform-Canvas.t'

#########################

use Test::More tests => 32;
BEGIN { 
	use_ok('Transform::Canvas'); 
	use_ok('SVG'); 
	use_ok('Data::Dumper'); 

};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(my $t = Transform::Canvas->new(canvas=>[0,0,10,10],data=>[0,0,10,10]),'constructor');


my $r_x = [0,1,2,3,4,5,6,7,8,9,10];
my $r_y = [0,1,2,3,4,5,6,7,8,9,10];

ok(my ($pr_x,$pr_y) = $t->map($r_x,$r_y),'transform a line');
my @px = @$pr_x;
my @py = @$pr_y;
while (@$r_x) {
	my $p_x = shift @$pr_x;
	my $p_y = shift @$pr_y;
	#20 test inside while loop
	my $d_x = shift @$r_x;
	my $d_y = shift @$r_y;
	ok(($d_x + $p_x) == 2*$d_x,'x xform line check');
	ok(($d_y + $p_y) == 10,'y xform line check');
}

ok(my $a = SVG->new(),'load svg module');
my $points = $a->get_path(x=>\@px, y=>\@py, -type=>'polygon');
my $c = $a->polygon(
	%$points,
	id=>'polygon one',
	fill=>'red',
	stroke=>'yellow',
);

open OUT,"> t/data/out.svg" || die("Unable to open file t/data/out.svg : $!");
ok($t->Max([0,1,2,3,4,5,6,7,8,9,10]) == 10, 'Max: Find max of an array');
ok($t->Min([0,1,2,3,4,5]) == 0, 'Min: Find min of an array');
ok(print OUT $a->xmlify(),'serialize to disk');
ok(close OUT,'close output file');

