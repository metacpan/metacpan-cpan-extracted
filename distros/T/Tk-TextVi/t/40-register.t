#
# Basic tests using registers
#
# p y
# "
#

use strict;
use warnings;

use Tk;
use Tk::TextVi;
use Test::More;

my $mw = eval { new MainWindow };

if( $mw ) {
    plan tests => 5;
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

test( '1.0','yyp' );
ok( $t->Contents eq <<END, 'Yank line and paste' );
Testing Tk::TextVi
Testing Tk::TextVi
Some lines of sample text
With a blank line:

This line contains four i's
0123456789
END

test( '2.0','yf p' );
ok( $t->Contents eq <<END, 'yank til space and paste' );
Testing Tk::TextVi
SSome ome lines of sample text
With a blank line:

This line contains four i's
0123456789
END

test( '3.0','"ayyp' );
ok( $t->Contents eq <<END, 'duplicated in unnamed register' );
Testing Tk::TextVi
Some lines of sample text
With a blank line:
With a blank line:

This line contains four i's
0123456789
END

test( '5.0','yy"ap' );
ok( $t->Contents eq <<END, 'Put from register' );
Testing Tk::TextVi
Some lines of sample text
With a blank line:

This line contains four i's
With a blank line:
0123456789
END

test( '1.0','"ayy' );
test( '2.0','"Ayy"ap' );
ok( $t->Contents eq <<END, 'Capital letter register for append' );
Testing Tk::TextVi
Some lines of sample text
Testing Tk::TextVi
Some lines of sample text
With a blank line:

This line contains four i's
0123456789
END

__END__
test( '','' );
ok( $t->Contents eq <<END, '' );
Testing Tk::TextVi
Some lines of sample text
With a blank line:

This line contains four i's
0123456789
END


