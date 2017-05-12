#
# Tests the basic motion commands
#
# gg h j k l
# G
# 0 $
#

use strict;
use warnings;

use Tk;
use Tk::TextVi;
use Test::More;

my $mw = eval { new MainWindow };

if( $mw ) {
    plan tests => 24;
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

# h

test( '2.8', 'h' );
ok( $t->index('insert') eq '2.7', 'Normal-h moves back one character' );

test( '2.0', 'h' );
ok( $t->index('insert') eq '2.0', 'Normal-h does not cross lines' );

test( '2.5', '2h' );
ok( $t->index('insert') eq '2.3', 'Normal-h with count' );

test( '2.5', '99h' );
ok( $t->index('insert') eq '2.0', 'Normal-h with count does not cross lines' );

# j

test( '1.5', 'j' );
ok( $t->index('insert') eq '2.5', 'Normal-j moves down one line' );

test( '1.1', '2j' );
ok( $t->index('insert') eq '3.1', 'Normal-j with a count' );

# k

test( '2.5', 'k' );
ok( $t->index('insert') eq '1.5', 'Normal-k moves up one line' );

test( '3.3', '2k' );
ok( $t->index('insert') eq '1.3', 'Normal-k moves up one line' );

# l

test( '1.0', 'l' );
ok( $t->index('insert') eq '1.1', 'Normal-l advances 1 char' );

test( '1.0', '2l' );
ok( $t->index('insert') eq '1.2', 'Normal-l with count' );

test( '6.9', 'l' );
ok( $t->index('insert') eq '6.9', 'Normal-l stops at final char' );

test( '6.0', '99l' );
ok( $t->index('insert') eq '6.9', 'Normal-l with count stops at final char');

test( '4.0', 'l' );
ok( $t->index('insert') eq '4.0', 'Normal-l on blank line' );

# gg

test( '3.5', 'gg' );
ok( $t->index('insert') eq '1.0', 'Normal-gg goes to first line' );

test( '2.8', '2gg' );
ok( $t->index('insert') eq '2.0', 'Normal-gg goes to count line' );

# G

test( '3.5', 'G' );
ok( $t->index('insert') eq '7.0', 'Normal-G goes to last line' );

test( '2.8', '2G' );
ok( $t->index('insert') eq '2.0', 'Normal-G goes to count line' );

# 0

test( '3.5', '0' );
ok( $t->index('insert') eq '3.0', 'Normal-0 goes to line start' );

# $

test( '6.0', '$' );
ok( $t->index('insert') eq '6.9', 'Normal-$ goes to line end' );

test( '4.0', '$' );
ok( $t->index('insert') eq '4.0', 'Normal-$ on empty line' );

test( '5.5', '2$' );
ok( $t->index('insert') eq '6.9', 'Normal-$ advances count-1 lines' );

# :

test( '1.0', ":3\n" );
ok( $t->index('insert') eq '3.0', ':range to set line' );

test( '1.0', ":.+2\n" );
ok( $t->index('insert') eq '3.0', ':range with . and +' );

test( '3.0', ":.-2\n" );
ok( $t->index('insert') eq '1.0', ':range with . and -' );

