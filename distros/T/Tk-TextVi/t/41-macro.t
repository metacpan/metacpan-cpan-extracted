#
# Tests using registers for macros
#
# q
# @
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

test( '1.0','qaddq@a' );
ok( $t->Contents eq <<END, 'Record a macro' );
With a blank line:

This line contains four i's
0123456789
END

test( '1.0','qaq@a' );
ok( $t->Contents eq <<END, 'Erase the macro' );
Testing Tk::TextVi
Some lines of sample text
With a blank line:

This line contains four i's
0123456789
END

test( '6.2','"aylgg0@adl' );
ok( $t->Contents eq <<END, 'Macro with incomplete command' );
sting Tk::TextVi
Some lines of sample text
With a blank line:

This line contains four i's
0123456789
END


