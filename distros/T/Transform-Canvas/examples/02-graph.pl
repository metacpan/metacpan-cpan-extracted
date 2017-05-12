#!/usr/bin/perl -w
use Transform::Canvas;
use SVG; 
use Carp;
use Data::Dumper;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $t = Transform::Canvas->new(canvas=>[0,0,100,100],data=>[0,0,100,100]);

my $r_x = [0,20,40,60,80,100];
my $r_y = [0,20,40,60,80,100];

my ($pr_x,$pr_y) = $t->map($r_x,$r_y);
my @px = @$pr_x;
my @py = @$pr_y;

my $a = SVG->new(width=>'100%',height=>'100%',viewBox=>"[-120 -120 120 120]");


my $points = $a->get_path(x=>\@px, y=>\@py, -type=>'path');

my $c = $a->path( %$points, id=>'polygon one', fill=>'none', stroke=>'blue',);

#draw the labels
my $g = $a->group(id=>'gridlines','stroke-size'=>'1',stroke=>'grey');
my $l = $a->group(id=>'labels','font-size'=>6, fill=>'black','text-anchor'=>'middle',stroke=>'none','font-face'=>'Arial');
while (scalar @px) {
	my $cx = shift @px;
	my $cy = shift @py;
	$a->ellipse(cx=>$cx,cy=>$cy,rx=>'1%',ry=>'1%',fill=>'red',stroke=>'cyan');
}
	
foreach my $i (0..10) {

	#x-value of the constant-x grid line
	my $x_line =  ($t->dx1 - $t->dx0)*$i/10;

	#y-value of the constant-y grid line
	my $y_line =  ($t->dy1 - $t->dy0)*$i/10;
	
	#convert to canvas values
	my $cx_line = $t->mapX($x_line);
	my $cy_line = $t->mapY($y_line);

	print STDERR "x_line, y_line = $x_line,$y_line -- cx_line, cy_line = $cx_line,$cy_line\n";
	#draw the 1/10 x gridline in the canvas space
	$g->line( x1=> $cx_line, y1=>$t->cy0, x2=> $cx_line, y2=>$t->cy1, );
	#draw the 1/10 y gridline in the canvas space
	$g->line( y1=> $cy_line, x1=>$t->cx0, y2=> $cy_line, x2=>$t->cx1,);
	#write the 1/10 x text
	$l->text( x=>$cx_line, y=>$t->cy1 + 10,
		'text-anchor'=>'middle',)
			->cdata($x_line);
	#write the 1/10 y text
	$l->text( y=>$cy_line,x=>$t->cx0 - 10,
		'text-anchor'=>'middle',)
			->cdata("$y_line");
}

$a->rect(x=>$t->cx0,y=>$t->cy0,
	width=>$t->cx1-$t->cx0,
	height=>$t->cy1-$t->cy0,
	fill=>'none',stroke=>'red');

print $a->xmlify();
