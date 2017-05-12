#
# Tests find motions that can cross lines
#
# %
#

use strict;
use warnings;

use Tk;
use Tk::TextVi;
use Test::More;

my $mw = eval { new MainWindow };

if( $mw ) {
    plan tests => 6;
}
else {
    print "1..0 # SKIP: Can't test without working Tk.\n";
    exit;
}
my $t = $mw->TextVi();

$t->Contents( <<END );
( Parens )
Some [ Brackets { with
   nested brace }
and [ brackets ]
spanning 3 lines ]
No { match for these )
END

sub test {
    my ($init, $cmds) = @_;
    $t->SetCursor( $init );
    $t->InsertKeypress( $_ ) for split //, $cmds;
}

# %

test( '1.0', '%' );
ok( $t->index('insert') eq '1.9', '( to )' );

test( '1.4', '%' );
ok( $t->index('insert') eq '1.0', 'If not on bracket use next' );

test( '3.10', '%' );
ok( $t->index('insert') eq '2.16', 'Curly brace across lines' );

test( '2.0', '%' );
ok( $t->index('insert') eq '5.17', 'Skips nested brackets' );

test( '6.1', '%' );
ok( $t->index('insert') eq '6.1', 'No matching brace' );

test( '6.10', '%' );
ok( $t->index('insert') eq '6.10', 'No matching brace' );

