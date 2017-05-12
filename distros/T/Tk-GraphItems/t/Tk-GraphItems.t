# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Tk-GraphItems-Tie.t'


use Test::More tests => 17;
BEGIN {use_ok ('Tk');
       use_ok ('Tk::GraphItems');
}

use strict;
use warnings;

SKIP:{

my $mw = eval{ tkinit()};
skip 'Tk::MainWindow instantiation failed - skipping Tk-GraphItems.t',
      15 if $@;

my $s_can = $mw -> Scrolled('Canvas',
			    -scrollregion=>[0,0,200,700],
			)->pack(-fill  =>'both',
				-expand=>1);
my $can = $s_can->Subwidget('scrolled');

my @obj;
my @connectors;
my @coords = (20,20,50,50);
sub create_circle{ 
    $obj[0] = Tk::GraphItems->Circle(canvas => $can,
                                     size   => 20,
                                     colour => 'green',
                                     'x'    => \$coords[0],
                                     'y'    => \$coords[1]);
}
sub create_circle_direct{ 
    $obj[0] = Tk::GraphItems::Circle->new(canvas => $can,
                                          size   => 20,
                                          colour => 'green',
                                          'x'    => \$coords[0],
                                          'y'    => \$coords[1]);
} 
sub create_textbox{
    $obj[1] = Tk::GraphItems->TextBox(canvas => $can,
		 		        text => 't',
				      'x'    => \$coords[2],
				      'y'    => \$coords[3]);
} 
sub create_textbox_direct{
    $obj[1] = Tk::GraphItems::TextBox->new(canvas => $can,
					   text => 't',
					   'x'    => \$coords[2],
					   'y'    => \$coords[3]);
}
sub create_connector_direct{
    push @connectors, Tk::GraphItems::Connector->new(
				   source=>$obj[0],
				   target=>$obj[1],
			       );
}
sub create_connector{
    push @connectors, Tk::GraphItems->Connector(
				   source=>$obj[1],
				   target=>$obj[0],
			       );
}
sub create_lab_connector{
    push @connectors, Tk::GraphItems->LabeledConnector(
				   source=>$obj[0],
				   target=>$obj[1],
			       );
}
sub create_lab_connector_direct{
    push @connectors, Tk::GraphItems::LabeledConnector->new(
				   source=>$obj[0],
				   target=>$obj[1],
			       );
}
sub cleanup{
    for (@connectors){$_ ->detach}
    @connectors = ();
}

$mw->update;
eval{create_circle()};
ok( !$@,"instantiation circle $@");
isa_ok($obj[0], 'Tk::GraphItems::Circle');
$mw->update;
eval{create_circle_direct()};
ok( !$@,"instantiation circle direct $@");
isa_ok($obj[0], 'Tk::GraphItems::Circle');
$mw->update;
eval{create_textbox()};
ok( !$@,"instantiation textbox $@");
isa_ok($obj[1],'Tk::GraphItems::TextBox');
$mw->update;
eval{create_textbox_direct()};
ok( !$@,"instantiation textbox direct $@");
isa_ok($obj[1],'Tk::GraphItems::TextBox');
$mw->update;
eval{create_connector()};
ok( !$@,"instantiation connector $@");
$mw->update;
eval{create_connector_direct()};
ok( !$@,"instantiation connector direct $@");
$mw->update;
cleanup();
eval{create_lab_connector()};
ok( !$@,"instantiation labeled connector $@");
$mw->update;

eval{create_lab_connector_direct()};
ok( !$@,"instantiation labeled connector direct $@");
$mw->update;

$connectors[0]->label('labeltext');
is($connectors[0]->label(), 'labeltext', 'get / set LabeledConnector label');

eval{$obj[0]->move(10,10)};
ok( !$@,"moved a node with labeled connector attached $@");

eval{ $obj[0]->set_coords(20,70);
      $mw->update;
      $obj[0]->set_coords(70,70);
      $mw->update;
      $obj[0]->set_coords(70,20);
      $mw->update;
      };
ok( !$@,"set coords for a node with labeled connector attached $@");

cleanup();
}# end SKIP
__END__
