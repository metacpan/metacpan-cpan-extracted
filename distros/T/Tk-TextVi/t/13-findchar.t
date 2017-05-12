#
# Tests charwise find motion commands
#
# f t
#

use strict;
use warnings;

use Tk;
use Tk::TextVi;
use Test::More;

my $mw = eval { new MainWindow };

if( $mw ) {
    plan tests => 8;
}
else {
    print "1..0 # SKIP: Can't test without working Tk.\n";
    exit;
}
my $t = $mw->TextVi();

$t->Contents( <<END );
Testing Tk::TextVi
Some lines of sample text
With a blank line:

Which has some special cases
0123456789
END

sub test {
    my ($init, $cmds) = @_;
    $t->SetCursor( $init );
    $t->InsertKeypress( $_ ) for split //, $cmds;
}

# f

test( '1.0', 'fi' );
ok( $t->index('insert') eq '1.4', 'Find' );

test( '1.4', 'fi' );
ok( $t->index('insert') eq '1.17', 'Find when already on character' );

test( '1.0', 'f$' );
ok( $t->index('insert') eq '1.0', 'No motion if no character' );

test( '2.9', '2f ' );
ok( $t->index('insert') eq '2.13', 'Find with count' );

# t

test( '2.0', 'te' );
ok( $t->index('insert') eq '2.2', 'Until' );

test( '2.3', 'te' );
ok( $t->index('insert') eq '2.7', 'Until when already on character' );

test( '4.0', 'tq' );
ok( $t->index('insert') eq '4.0', 'No motion if no character' );

test( '3.0', '3t ' );
ok( $t->index('insert') eq '3.11', 'until with count' );

