#!/usr/bin/perl
use strict;
use warnings;
use Tk;
use Data::Dumper;
use Scalar::Util qw/ weaken /;
#require Tk::GraphItems::TextBox;
#require Tk::GraphItems::Connector;
require Tk::GraphItems;
my $mw = tkinit();
my$text;
$mw->Label(-textvariable=>\$text)->pack;
my $s_can = $mw -> Scrolled('Canvas',
			    -scrollregion=>[0,0,600,400],
			   )->pack(-side  =>'right',
				   -fill  =>'both',
				   -expand=>1);
my $can = $s_can->Subwidget('scrolled');

my @node;
my @conn;
my @coords= map [(int rand 500)+50,(int rand 300) +50],(0..4);
my %command;
$command{build_items}=sub{
    for my $n(0..4){
	$node[$n] = Tk::GraphItems->TextBox(canvas => $can,
					    text   => "object $n",
					    'x'    => \$coords[$n][0],
					    'y'    => \$coords[$n][1]
					);
		}
  for my $n(0..4){
      $conn[$n] = Tk::GraphItems->Connector(
					    source => $node[$n],
					    target => $node[($n+1)%5],
					    colour => 'black'
					);
		} 
  weaken $_ for(@conn) ;
    
  $command{nodes_move}->();
}
;
my @step;
my $repeat;
my @borders = (25,25,575,375);
$command{nodes_move} = sub {
  for my $i(0..4){
    for (0,1){$step[$i][$_] = ( rand 2)-1}
  }
  if ($repeat){$repeat->cancel;
	       undef $repeat;return}
  $repeat = $mw->repeat(20,\&transform);
};

sub transform{
    for my $n (0..4) {
	for (0,1) {
	    $coords[$n][$_] += $step[$n][$_];
	    #print "$coords[$n][$_]\n";
	}
	if ($coords[$n][0]>$borders[2]) {
	    $step[$n][0]= - $step[$n][0];
	    $coords[$n][0] = $borders[2];
	}
	if ($coords[$n][0]<$borders[0]) {
	    $step[$n][0]= - $step[$n][0];
	    $coords[$n][0] = $borders[0];
	}
	if ($coords[$n][1]>$borders[3]) {
	    $step[$n][1]= - $step[$n][1];
	    $coords[$n][1] = $borders[3];
	}
	if ($coords[$n][1]<$borders[1]) {
	    $step[$n][1]= - $step[$n][1];
	    $coords[$n][1] = $borders[1];
	}
    }
}
$command{undef_last}=sub {
  my $item = pop(@node);
  undef ($item);
};
$command{node_set_coord}=sub {
  $node[1]->set_coords(40,20);
};
$command{node_set_text}=sub {

  for my $node (@node){
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
