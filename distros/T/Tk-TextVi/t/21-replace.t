#
# Tests for the replace operations
# 
# r R ~
#

use strict;
use warnings;

use Tk;
use Tk::TextVi;
use Test::More;

my $mw = eval { new MainWindow };

if( $mw ) {
    plan tests => 7;
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

# r

test( '2.5', 'rq' );
ok( <<END eq $t->Contents, 'replace character' );
Testing Tk::TextVi
Some qines of sample text
With a blank line:

This line contains four i's
0123456789
END

test( '3.0', '5r-' );
ok( <<END eq $t->Contents, 'replace multiple' );
Testing Tk::TextVi
Some lines of sample text
-----a blank line:

This line contains four i's
0123456789
END

test( '3.10', '9rx' );
ok( <<END eq $t->Contents, 'cannot replace at end of line' );
Testing Tk::TextVi
Some lines of sample text
With a blank line:

This line contains four i's
0123456789
END

# R
test( '1.0', 'RReplace' );
ok( <<END eq $t->Contents, 'Testing replace mode' );
Replace Tk::TextVi
Some lines of sample text
With a blank line:

This line contains four i's
0123456789
END

test( '1.3', "R123\cH\cH" );
ok( <<END eq $t->Contents, 'Backspace restores overtyped characters' );
Tes1ing Tk::TextVi
Some lines of sample text
With a blank line:

This line contains four i's
0123456789
END

test( '1.3', "R\cH" );
ok( <<END eq $t->Contents, 'Backspace when no replaced chars' );
Testing Tk::TextVi
Some lines of sample text
With a blank line:

This line contains four i's
0123456789
END

# ~

test( '1.7', "~~~" );
ok( <<END eq $t->Contents, 'Toggle case' );
Testing tK::TextVi
Some lines of sample text
With a blank line:

This line contains four i's
0123456789
END


