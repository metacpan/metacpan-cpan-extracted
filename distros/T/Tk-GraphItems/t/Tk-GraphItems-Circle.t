# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as
# `perl Tk-GraphItems-Circle.t'.


use Test::More tests => 26;
BEGIN {use_ok ('Tk')};
require_ok ('Tk::GraphItems::Circle');
require_ok ('Tk::GraphItems::Connector');


use strict;
use warnings;

SKIP:{

my $mw = eval{ tkinit()};
skip 'Tk::MainWindow instantiation failed - skipping Tk-GraphItems-Circle.t',
      23 if $@;


my $can = $mw -> Canvas()->pack(-fill  =>'both',
				-expand=>1);

my @node;
my $conn;
sub create{
    for my $n (0,1) {
	$node[$n] = Tk::GraphItems::Circle->new(canvas => $can,
					       size   => 20,
					       colour => 'green',
					       'x'    => 50,
					       'y'    => 50);
    }

    $conn= Tk::GraphItems::Connector->new(
					  source=>$node[0],
					  target=>$node[1],
				      );
}


sub get_set_c{
    my($x,$y) = @_;
    if (@_){
        $node[1]->set_coords($x,$y);
    }
    return $node[1]->get_coords;
}
sub move{
    my @delta = @_;
    $node[1]->move(@delta);
    return $node[1]->get_coords;
}


sub set_size{
    my $size = shift;
    $node[0]->size($size);
    return $node[0]->size;;
}

sub set_colour{
    my $color = shift;
    $node[0]->colour($color);
    return $node[0]->colour;
}



$mw->update;
eval{create()};
ok( !$@,"instantiation $@");
ok( $node[0]->isa('Tk::GraphItems::Circle'), 'first node ');
ok( $node[1]->isa('Tk::GraphItems::Circle'), 'second node ');
ok( $conn->isa('Tk::GraphItems::Connector'),'connector ');
eval{$node[0]->new()};
ok( $@, "new called on instance: $@");

$mw->update;
{
    my @coords = (42,42);
    my $ret;
    eval{$ret = get_set_c(@coords)};
    ok( !$@,"method get_set_coords $@");
    is_deeply($ret, \@coords, 'get_set_coords result_ok');
    eval{$ret = get_set_c(1,'foo')};
    ok( $@," invalid args to set_coords(): $@");
}


$mw->update;

{
    my @delta = (10,10);
    my $ret ;
    eval{
        get_set_c(90,90);
        move(@delta);
        $ret = get_set_c();
    };
    ok( !$@,"method move $@");
    is_deeply($ret,[100,100], 'move result_ok');
    eval{
        move('foo','bar');
    };
    ok($@, " invalid args to move(): $@");
}
$mw->update;
{
    my $color = 'red';
    my $ret;
    eval{$ret = set_colour($color)};
    ok( !$@, "method set_colour $@");
    is($ret, $color, 'color set correctly');
    $color = 'foo';
    eval{$ret = set_colour($color)};
    ok( $@, "invalid args to set_colour $@");
    $mw->update;
}
$mw->update;
{
    my $size = 50;
    my $ret;
    eval{$ret = set_size($size)};
    ok( !$@,"set_size $@");
    is($ret, $size, 'size set correctly');
    $mw->update;
    eval{set_size('foo')};
    ok( $@, "invalid args to size(): $@");
}
{
    my $test;
    $node[0]->set_coords(80,80);
    $node[0]->bind_class('<2>', sub{$test = 'foo'});
    $mw->update;
    my $ret = $can->bind('CircleBind','<2>');
    is (substr("$ret",0,12),'Tk::Callback','circle binding created');
    $can->eventGenerate('<2>', -x => 80, -y => 80);
    is($test,'foo','circle binding invoked');
    $node[0]->bind_class('<2>', '');
    $ret = $can->bind('CircleBind','<2>');
    is ($ret,undef,'circle binding deleted');
}

$node[0]->set_coords(80,80);
$can->eventGenerate('<ButtonPress-1>', -x => 80, -y => 80);
ok (!($node[0]->was_dragged),'node not dragged yet');
$can->eventGenerate('<B1-Motion>', -x => 100, -y => 100);
ok (($node[0]->was_dragged),'node was_dragged');
my $coords = $node[0]->get_coords;
is_deeply($coords,[100,100],'drag_binding coords ok');

} #end SKIP

__END__
