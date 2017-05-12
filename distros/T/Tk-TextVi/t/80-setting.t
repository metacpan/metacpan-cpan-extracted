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
chomp $text;

sub test {
    my ($pos,$cmds) = @_;
    if( defined $pos ) {
        $t->Contents( $text );
        $t->viMode('n');
        $t->SetCursor( $pos );
    }
    $t->InsertKeypress( $_ ) for split //, $cmds;
}

test( '1.0', ":set sts=4\ni\cI" );
is( <<END , $t->Contents, 'Tab at beginning of line' );
    Testing Tk::TextVi
Some lines of sample text
With a blank line:

This line contains four i's
0123456789
END

test( '1.2', "i\cI" );
is( <<END , $t->Contents, 'Tab in middle of line' );
Te  sting Tk::TextVi
Some lines of sample text
With a blank line:

This line contains four i's
0123456789
END

test( '1.0', "i      \cH" );
is( <<END , $t->Contents, 'Backspace deletes to tabstop' );
    Testing Tk::TextVi
Some lines of sample text
With a blank line:

This line contains four i's
0123456789
END

