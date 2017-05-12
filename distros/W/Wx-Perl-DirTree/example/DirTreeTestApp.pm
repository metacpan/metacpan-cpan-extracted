package DirTreeTestApp;

use strict;
use warnings;

use Wx;
use FindBin ();
use DirTreeTest;

our @ISA = qw(Wx::App);

sub OnInit {
    my ( $self ) = @_;
    
    my( $frame ) = DirTreeTest->new( undef, -1, "Wx::Perl::DirTree", [20,20], [500,340] );
    $frame->Show(1);
    
    1;
}

1;