# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as
# `perl Tk-GraphItems-TextBox.t'.


use Test::More tests => 34;

BEGIN {use_ok ('Tk')};
require_ok ('Tk::GraphItems::TextBox');
require_ok ('Tk::GraphItems::Connector');


use strict;
use warnings;


SKIP:{

my $mw = eval{ tkinit()};
skip 'Tk::MainWindow instantiation failed - skipping Tk-GraphItems-TextBox.t',
      31 if $@;

my $s_can = $mw -> Scrolled('Canvas',
			    -scrollregion=>[0,0,200,700],
			)->pack(-fill  =>'both',
				-expand=>1);
my $can = $s_can->Subwidget('scrolled');

my @node;
my $conn;
my $conn_weak;
sub create{ 
    my ($x,$y) = (50,20);
    for my $n (0..1) {
	$node[$n] = Tk::GraphItems::TextBox->new(canvas=>$can,
						text=>"object $n",
						'x'=>$x+=20,
						'y'=>$y+=20);
    }



    $conn= Tk::GraphItems::Connector->new(
					  source=>$node[0],
					  target=>$node[1],
				      );
    $conn_weak = Tk::GraphItems::Connector->new(
					  source      => $node[1],
					  target      => $node[0],
                                          autodestroy => 1,
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


sub set_text{
    my $text = shift;
    my $node = $node[0];
    if (defined $text){
        $node->text($text);
    }
    $mw->update;
    return $node->text;
}

sub set_color{
    my $color = shift;
    $node[0]->colour($color);
    return $node[0]->colour;
}



sub conn_arrow{
    my $arrow = shift;
    if ($arrow){
        $conn->arrow($arrow);
    }
    return $conn->arrow;
}

sub conn_color{
    my $color = shift;
    $conn->colour($color);
    return $conn->colour;
}

sub conn_width{
    my $width = shift;
    $conn->width($width);
    return $conn->width;
}

$mw->update;

eval{create()};
ok( !$@,"instantiation $@");
ok($node[0]->isa('Tk::GraphItems::TextBox'), 'node 1');
ok($node[1]->isa('Tk::GraphItems::TextBox'), 'node 2');
ok($conn->isa('Tk::GraphItems::Connector'), 'connector');
$mw->update;


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
    eval{$ret = set_color($color)};
    ok( !$@, "method color $@");
    is($ret, $color, 'color set correctly');
    $color = 'foo';
    eval{$ret = set_color($color)};
    ok( $@, "invalid args to TextBox->colour $@");
    $mw->update;
}
$mw->update;
{
    my $text = 'new text';
    my $ret;
    eval{$ret = set_text($text)};
    ok( !$@, "method set_text $@");
    is($ret, $text, 'text set correctly');
    $mw->update;
}

{
    my $color = 'red';
    my $ret;
    eval{$ret = conn_color($color)};
    ok( !$@, "method Connector->color $@");
    is($ret, $color, 'color set correctly');
    $color = 'foo';
    eval{$ret = conn_color($color)};
    ok( $@, "invalid args to Connector->color $@");
    $mw->update;
}



{
    my $arrow = 'last';
    my $ret;
    eval{$ret = conn_arrow($arrow)};
    ok( !$@,"connector arrow $@");
    is($ret, $arrow, 'arrow set correctly');
    $arrow = 'zzz';
    eval{$ret = conn_arrow($arrow)};
    ok( $@,"invalid args to connector->arrow $@");
}
    $mw->update;


{
    my $width = 3;
    my $ret;
    eval{$ret = conn_width($width)};
    ok(!$@, 'connector width');
    is($ret, $width, 'connector->width set correctly');
    $width = 'foo';
    eval{$ret = conn_width($width)};
    ok($@, "invalid args to connector->width(): $@");

}

$mw->update;

$node[0]->bind_class('<<TestEvent>>', sub{});
my $ret = $can->bind('TextBoxBind','<<TestEvent>>');
is (substr("$ret",0,12),'Tk::Callback','TextBox binding created');
$node[0]->bind_class('<<TestEvent>>', '');
$ret = $can->bind('TextBoxBind','<<TestEvent>>');
is ($ret,undef,'TextBox binding deleted');


$conn->bind_class('<<TestEvent>>', sub{});
$ret = $can->bind('ConnectorBind','<<TestEvent>>');
is (substr("$ret",0,12),'Tk::Callback','Connector binding created');
$conn->bind_class('<<TestEvent>>', '');
$ret = $can->bind('ConnectorBind','<<TestEvent>>');
is ($ret,undef,'Connector binding deleted');

my $canvas_item = $conn_weak->canvas_items;
my $found = $can->find('withtag',$canvas_item);
is ($found->[0], $canvas_item, 'Connector CanvasItem exists');
undef $conn_weak;
$found = $can->find('withtag',$canvas_item);
isnt ($found, $canvas_item, 'Connector CanvasItem destroyed');




$node[0] = $node[1] = $conn=  undef;

my @items = $can->find('all');
is( @items, 3, 'Canvas items destroyed');

} #end SKIP

__END__
