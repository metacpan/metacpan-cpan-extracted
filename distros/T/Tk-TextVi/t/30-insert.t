# 
# Tests insert mode
#
# a i o
# A O

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

# i

test( '3.5', "iinsert some text \c[" );
ok( <<END eq $t->Contents, 'insert text' );
Testing Tk::TextVi
Some lines of sample text
With insert some text a blank line:

This line contains four i's
0123456789
END

test( '1.1', "i\c[" );
ok( $t->index('insert') eq '1.0', 'ESC moves cursor back' );

test( '2.0', "i\c[" );
ok( $t->index('insert') eq '2.0', 'Except at linestart' );

# a

test( '6.4', "a<append>\c[" );
ok( <<END eq $t->Contents, 'append text' );
Testing Tk::TextVi
Some lines of sample text
With a blank line:

This line contains four i's
01234<append>56789
END

test( '4.0', "a" );
ok( $t->index('insert') eq '4.0', 'cursor not advanced on blank' );

# o

test( '2.4', "oopenline\c[" );
ok( <<END eq $t->Contents, 'open line' );
Testing Tk::TextVi
Some lines of sample text
openline
With a blank line:

This line contains four i's
0123456789
END

test( '2.4', "Oopenline\c[" );
ok( <<END eq $t->Contents, 'Open line' );
Testing Tk::TextVi
openline
Some lines of sample text
With a blank line:

This line contains four i's
0123456789
END


test( '6.4', "A<append>\c[" );
ok( <<END eq $t->Contents, 'append text at end of line' );
Testing Tk::TextVi
Some lines of sample text
With a blank line:

This line contains four i's
0123456789<append>
END


