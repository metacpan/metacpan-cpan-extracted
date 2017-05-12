# Object-oriented Canvas.
#!/usr/local/bin/perl -w
use strict;
use Tk qw(Ev);
use Tk::Cloth;

my $mw = Tk::MainWindow->new;

my $cloth = $mw->Cloth();


my $r = $cloth->Rectangle(
	-coords => [0,0,100,100],
	-fill => 'green'
);

{
    my($x,$y);
    $r->bind("<ButtonPress-1>", [
	sub {
	    shift;
	    ($x,$y) = @_
	}, Ev('x'),Ev('y')]
    );
    $r->bind("<B1-Motion>", [
	sub {
	    my($r,$X,$Y) = @_;
	    $r->move($X-$x,$Y-$y);
	    ($x,$y) = ($X,$Y)  
	}, Ev('x'),Ev('y')]
    );
}

my $tag = $cloth->Tag;

$tag->Oval(
	-coords => [100,0,200,100],
	-fill => 'blue'
);

$tag->Oval(
	-coords => [0,200,100,100],
	-fill => 'red'
);

{
    my($x,$y);
    $tag->bind("<ButtonPress-1>", [
	sub {
	    shift;
	    ($x,$y) = @_
	}, Ev('x'),Ev('y')]
    );
    $tag->bind("<B1-Motion>", [
	sub {
	    my($r,$X,$Y) = @_;
	    $r->move($X-$x,$Y-$y);
	    ($x,$y) = ($X,$Y)  
	}, Ev('x'),Ev('y')]
    );
}

$cloth->pack(-fill => 'both', -expand => 1);

Tk::MainLoop;
