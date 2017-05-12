#!/usr/bin/perl -w
use Transform::Canvas;
use SVG; 

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $t = Transform::Canvas->new(canvas=>[20,100,20,100],data=>[-1,10,-1,10]);


my $r_x = [0,1,1,3,4,5,6,7,8,8,10];
my $r_y = [0,1,2,3,4,4,4,7,8,9,10];

my ($pr_x,$pr_y) = $t->map($r_x,$r_y);
my @px = @$pr_x;
my @py = @$pr_y;

my $a = SVG->new(width=>120,height=>120);
my $points = $a->get_path(x=>\@px, y=>\@py, -type=>'polygon');
my $c = $a->polygon(
	%$points,
	id=>'polygon one',
	fill=>'red',
	stroke=>'yellow',
);

print $a->xmlify();
