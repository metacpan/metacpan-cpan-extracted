#
# Tests for the delete operator.
# Doesn't so much test delete as it tests all the motion operators
# to make sure they declare charwise/linewise inclusive/exclusive right
# Also see section 4 since none of these tests verify the registers
#
# Also tests the commands that are just mapped to a d command
#
# d x
# D
#

use strict;
use warnings;

use Tk;
use Tk::TextVi;
use Test::More;

my $mw = eval { new MainWindow };

if( $mw ) {
    plan tests => 26;
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

# dd

test( '2.5', 'dd' );
ok( <<END eq $t->Contents, 'delete line' );
Testing Tk::TextVi
With a blank line:

This line contains four i's
0123456789
END

test( '4.0', '3dd' );
ok( <<END eq $t->Contents, 'delete 3 lines' );
Testing Tk::TextVi
Some lines of sample text
With a blank line:
END

test( '6.0', '3dd' );
ok( <<END eq $t->Contents, 'Not enough lines, delete nothing' );
Testing Tk::TextVi
Some lines of sample text
With a blank line:

This line contains four i's
0123456789
END

# df

test( '1.0', 'df ' );
ok( <<END eq $t->Contents, 'delete find space' );
Tk::TextVi
Some lines of sample text
With a blank line:

This line contains four i's
0123456789
END

test( '2.5', 'dfq' );
ok( <<END eq $t->Contents, 'delete cant find character' );
Testing Tk::TextVi
Some lines of sample text
With a blank line:

This line contains four i's
0123456789
END

test( '1.0', '2df:' );
ok( <<END eq $t->Contents, 'delete find second colon' );
TextVi
Some lines of sample text
With a blank line:

This line contains four i's
0123456789
END

test( '5.0', '2d2fi' );
ok( <<END eq $t->Contents, 'delete 2 * 2 find i' );
Testing Tk::TextVi
Some lines of sample text
With a blank line:

's
0123456789
END

# dgg

test( '3.0', 'dgg' );
ok( <<END eq $t->Contents, 'behead' );

This line contains four i's
0123456789
END

test( '3.0', 'd5gg' );
ok( <<END eq $t->Contents, 'delete lines 3 to 5' );
Testing Tk::TextVi
Some lines of sample text
0123456789
END

# dh

test( '1.5', 'dh' );
ok( <<END eq $t->Contents, 'delete back one char' );
Testng Tk::TextVi
Some lines of sample text
With a blank line:

This line contains four i's
0123456789
END

test( '2.0', 'dg' );
ok( <<END eq $t->Contents, 'delete nothing, no previous character' );
Testing Tk::TextVi
Some lines of sample text
With a blank line:

This line contains four i's
0123456789
END

# dj

test( '1.5', 'dj' );
ok( <<END eq $t->Contents, 'delete lines with j' );
With a blank line:

This line contains four i's
0123456789
END

test( '7.0', 'dj' );
ok( <<END eq $t->Contents, 'delete nothing, no next line' );
Testing Tk::TextVi
Some lines of sample text
With a blank line:

This line contains four i's
0123456789
END

# dk

test( '3.5', 'dk' );
ok( <<END eq $t->Contents, 'delete lines with k' );
Testing Tk::TextVi

This line contains four i's
0123456789
END

test( '1.5', 'dk' );
ok( <<END eq $t->Contents, 'delete nothing, no previous line' );
Testing Tk::TextVi
Some lines of sample text
With a blank line:

This line contains four i's
0123456789
END

# dl

test( '3.0', 'dl' );
ok( <<END eq $t->Contents, 'delete next character' );
Testing Tk::TextVi
Some lines of sample text
ith a blank line:

This line contains four i's
0123456789
END

test( '4.0', 'dl' );
ok( <<END eq $t->Contents, 'delete nothing, no next character' );
Testing Tk::TextVi
Some lines of sample text
With a blank line:

This line contains four i's
0123456789
END

# Delete until mark

test( '2.9', 'ma' );
test( undef, '0d`a' );
ok( <<END eq $t->Contents, 'delete until mark a' );
Testing Tk::TextVi
s of sample text
With a blank line:

This line contains four i's
0123456789
END

test( '2.5', 'ma' );
test( undef, 'jd`a' );
ok( <<END eq $t->Contents, 'delete until mark across line' );
Testing Tk::TextVi
Some a blank line:

This line contains four i's
0123456789
END

# dt

test( '1.0', 'dtg' );
ok( <<END eq $t->Contents, 'delete until' );
g Tk::TextVi
Some lines of sample text
With a blank line:

This line contains four i's
0123456789
END

test( '5.0', '2d2ti' );
ok( <<END eq $t->Contents, 'delete 2 * 2 until i' );
Testing Tk::TextVi
Some lines of sample text
With a blank line:

i's
0123456789
END

test( '3.0', 'dtd' );
ok( <<END eq $t->Contents, 'delete until nothing' );
Testing Tk::TextVi
Some lines of sample text
With a blank line:

This line contains four i's
0123456789
END

# d0

test( '2.5', 'd0' );
ok( <<END eq $t->Contents, 'delete to linestart' );
Testing Tk::TextVi
lines of sample text
With a blank line:

This line contains four i's
0123456789
END

# d$

test( '2.5', 'd$' );
ok( <<END eq $t->Contents, 'delete to lineend' );
Testing Tk::TextVi
Some 
With a blank line:

This line contains four i's
0123456789
END

# D

test( '3.1', 'D' );
ok( <<END eq $t->Contents, 'delete to lineend via D' );
Testing Tk::TextVi
Some lines of sample text
W

This line contains four i's
0123456789
END

# x

test( '3.0', 'x' );
ok( <<END eq $t->Contents, 'delete next character' );
Testing Tk::TextVi
Some lines of sample text
ith a blank line:

This line contains four i's
0123456789
END

