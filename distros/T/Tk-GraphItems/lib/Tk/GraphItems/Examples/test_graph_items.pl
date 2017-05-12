#!/usr/bin/perl
use strict;
use warnings;
use Tk;
use Data::Dumper;
require Tk::GraphItems::TextBox;
require Tk::GraphItems::Connector;

my $mw = tkinit();
my$text;
$mw->Label(-textvariable=>\$text)->pack;
my $s_can = $mw -> Scrolled('Canvas',
			    -scrollregion=>[0,0,200,700],
			   )->pack(-side  =>'right',
				   -fill  =>'both',
				   -expand=>1);
my $can = $s_can->Subwidget('scrolled');

my @node;
my @conn;
my ($tx,$ty) = (100,100);
my %command;
$command{build_items}=sub{ 
    my ($x,$y) = (50,20);
    for my $n(0..4){
	$node[$n] =Tk::GraphItems::TextBox->new(canvas => $can,
						text   => "object $n",
						'x'    => $x=($x%200)+40,
						'y'    => $y+=100);
    }
    ($tx,$ty)=(50,200);
    $node[5] =  Tk::GraphItems::TextBox->new(canvas=>$can,
					     text  =>"object\ntied x_y",
					     'x'=>\$tx,
					     'y'=>\$ty);
    for my $n(0..4){
	$conn[$n] = Tk::GraphItems::Connector->new(
						   source  =>$node[$n],
						   target  =>$node[($n+1)%5],
						   colour  =>'black',
					       );
		}

    weaken $_ for(@conn) ;

    Tk::GraphItems::Connector->new(
				   source=>$node[5],
				   target=>$node[3],
			       );
    $conn[0]->bind_class('<3>',sub{my $col = $_[0]->colour;
				   $col = $col eq 'red' ? 'black':'red';
				   $_[0]->colour($col);
			       }
		     );

};

$command{nodes_move}= sub{
  for (1..2){$node[$_]->move(20,5)};
  $_ += 10 for ($tx,$ty);
};
$command{undef_last}=sub {
  my $item = pop(@node);
  undef ($item);
};
$command{node_set_coord}=sub {
  $node[1]->set_coords(40,20);
};
$command{node_set_text}=sub {
  for my $n(2..4){
    my $node = $node[$n];
    $node->text($node->text . "\nand more");
  }
};
$command{node_set_colour}=sub {
  for my $n(1..3){
    my $node = $node[$n];
    $node->colour($node->colour eq 'red'? 'white':'red');
  }
};
$command{conn_directed} = sub {
  foreach(@conn){$_->arrow('target')}
};
$command{conn_undirected} = sub {
  foreach(@conn){$_->arrow('both')}
};
$command{conn_width} = sub {
  foreach(@conn){$_->width($_->width >2?1:$_->width +1)}
};
$command{conn_colour} = sub {
  foreach(@conn){$_->colour($_->colour eq'red'?'black':'red')}
};

my $frame = $mw->Frame()->pack(-side=>'left');
my $prev;
for (sort keys %command){
   $frame->Button(-text   =>$_,
		  -command=>$command{$_},
		  -width  =>20)->pack;
}

MainLoop; 
