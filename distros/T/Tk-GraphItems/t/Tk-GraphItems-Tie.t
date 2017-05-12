# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Tk-GraphItems-Tie.t'


use Test::More tests => 9;
BEGIN {use_ok ('Tk')};
require_ok ('Tk::GraphItems::Circle');
require_ok ('Tk::GraphItems::TextBox');
require_ok ('Tk::GraphItems::Connector');


use strict;
use warnings;

SKIP:{

my $mw = eval{ tkinit()};
skip 'Tk::MainWindow instantiation failed - skipping Tk-GraphItems-Tie.t',
      5 if $@;

my $s_can = $mw -> Scrolled('Canvas',
			    -scrollregion=>[0,0,200,700],
			)->pack(-fill  =>'both',
				-expand=>1);
my $can = $s_can->Subwidget('scrolled');

my @obj;
my @coords = (20,20,50,50);
sub create{ 
    $obj[0] = Tk::GraphItems::Circle->new(canvas => $can,
					     #  size   => 20,
					     #  colour => 'green',
					       'x'    => \$coords[0],
					       'y'    => \$coords[1]);

    $obj[1] = Tk::GraphItems::TextBox->new(canvas => $can,
					   text => 't',
					   'x'    => \$coords[2],
					   'y'    => \$coords[3]);

    Tk::GraphItems::Connector->new(
				   source=>$obj[0],
				   target=>$obj[1],
			       );

}
sub move{
    $obj[0]->move(20,0);
}

sub und{
    my $item = pop(@obj);
    undef ($item);
}

sub set_c{
    $obj[1]->set_coords(40,20);
    $_ += 10 for @coords;
  #  $mw->update;
    my ($x,$y) =  $obj[1]->get_coords;
    print "<$x>,<$y>\n";
    die if abs ( $x - 50 ) > 0.01 or abs( $y - 30 ) > 0.01;
}

sub set_tied_coords{
    my $x = 0;
    my $y = 0;
    $obj[1]->set_coords( \$x, \$y );
    ( $x , $y ) = ( 25, 25 );
    my @coords = $obj[1]->get_coords;
    for (@coords){
        die if abs( $_ - 25 ) > 0.01;
    }

}


$mw->update;
eval{create()};
ok( !$@,"instantiation $@");
$mw->update;

eval{move()};
ok( !$@,"method move $@");
$mw->update;

eval{set_c()};
ok( !$@,"method set_coords $@");
$mw->update;

eval{set_tied_coords()};
ok( !$@,"method set_tied_coords $@");
$mw->update;

eval{und()};
ok( !$@,"undef last $@");
$mw->update;

} # end SKIP
__END__
