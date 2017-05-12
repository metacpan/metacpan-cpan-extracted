#!/usr/bin/perl -w
use Tk;
my $m = MainWindow->new;
my $c = $m -> Canvas(-height => 200, -width => 300,);
$c -> pack;
$c -> create('text', 40, 50, '-text' => "Hello World!");
$m -> bind('<Any-KeyPress>' => sub{exit});
$m -> bind('<Button-1>' => sub {
    $c -> create('text',$c->XEvent->x,$c->XEvent->y, -text => "Hi.") });
MainLoop;
