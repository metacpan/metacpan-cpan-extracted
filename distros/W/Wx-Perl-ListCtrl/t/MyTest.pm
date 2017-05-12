package MyTest;

use strict;
use Wx;
use base qw(Wx::Frame Exporter);
our @EXPORT = qw(test init);

my $code;
my $frame;

sub init {
    my( $lc, $rows, $cols ) = @_;

    foreach my $c ( 1 .. $cols ) {
        $lc->InsertColumn( $c - 1, "C$c" );
    }

    foreach my $r ( 1 .. $rows ) {
        $lc->InsertStringItem( $r - 1, "(R$r, C1)" );
        foreach my $c ( 2 .. $cols ) {
            $lc->SetItem( $r - 1, $c - 1, "(R$r, C$c)" );
        }
    }
}

sub test(&) {
    MyApp->new;
    &{$_[0]}( $frame );
    $frame->Destroy;
}

package MyApp;

use strict;
use base 'Wx::App';

sub OnInit {
    ( $frame = MyTest->new( undef, -1, 'test' ) )->Show( 1 );

    1;
}

1;
