#
# Tests specific to visual character mode
#

use strict;
use warnings;

use Tk;
use Tk::TextVi;
use Test::More;

my $mw = eval { new MainWindow };

if( $mw ) {
    plan tests => 3;
}
else {
    print "1..0 # SKIP: Can't test without working Tk.\n";
    exit;
}
my $t = $mw->TextVi();

my $text = <<END;
Testing Tk::TextVi
Some lines of sample text
With a blank line:

This line contains four i's
0123456789
END

chomp($text);   # Tk::Text->Contents() seems to be added an extra newline

sub test {
    my ($pos,$cmds) = @_;
    if( defined $pos ) {
        $t->Contents( $text );
        $t->viMode('n');
        $t->SetCursor( $pos );
    }
    $t->InsertKeypress( $_ ) for split //, $cmds;
}

test( '2.5', 'Vjd' );
ok( <<END eq $t->Contents, 'foward a line' );
Testing Tk::TextVi

This line contains four i's
0123456789
END

test( '2.5', 'Vkd' );
ok( <<END eq $t->Contents, 'back a line' );
With a blank line:

This line contains four i's
0123456789
END

test( '2.5', 'V5ld' );
ok( <<END eq $t->Contents, 'one the same line' );
Testing Tk::TextVi
With a blank line:

This line contains four i's
0123456789
END
