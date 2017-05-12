# Is the 'layout' option handled correctly?

use Test::More tests => 18;
use Text::TypingEffort qw( effort );

my $text = <<"";
This is a test of the Dvorak layout vs QWERTY
Hopefully this text will have enough differences between the two
keyboard layouts that I'll be able to find the differences in the tests.
If not, what on earth am I going to do?  I would be unable to test the
module! Durn!

# qwerty layout
$effort = effort( text=>$text, layout=>'qwerty' );
results_ok( $effort, 'qwerty', 'layout=qwerty' );

# dvorak layout
$effort = effort( text=>$text, layout=>'dvorak' );
results_ok( $effort, 'dvorak', 'layout=dvorak' );

# aset layout
$effort = effort( text=>$text, layout=>'aset' );
results_ok( $effort, 'aset', 'layout=aset' );

# xpert layout
$effort = effort( text=>$text, layout=>'xpert' );
results_ok( $effort, 'xpert', 'layout=xpert' );

# colemak layout
$effort = effort( text=>$text, layout=>'colemak' );
results_ok( $effort, 'colemak', 'layout=colemak' );

# unknown layout
$effort = effort( text=>$text, layout=>'this is not a layout name' );
results_ok( $effort, 'unknown', 'layout=unknown' );


############### helper sub ###################
sub results_ok {
    my ($a, $layout, $msg) = @_;

    isa_ok( $a, 'HASH', "$msg: result is a hashref" );

    my $joules;
    my $others;
    if( $layout eq 'dvorak' ) {
        $joules = '8.9729';
        $others = {
                characters => 269,
                presses    => 282,
                distance   => 3800,
        };
    } elsif( $layout eq 'aset' ) {
        $joules = '10.0054';
        $others = {
                characters => 269,
                presses    => 282,
                distance   => 4250,
        };
    } elsif( $layout eq 'xpert' ) {
        $joules = '12.1384';
        $others = {
                characters => 269,
                presses    => 281,
                distance   => 5180,
        };
    } elsif( $layout eq 'colemak' ) {
        $joules = '8.9500';
        $others = {
                characters => 269,
                presses    => 282,
                distance   => 3790,
        };
    } else {
        $joules = '14.2732';
        $others = {
                characters => 269,
                presses    => 282,
                distance   => 6110,
        };
    }

    # floating point compare can be wierd
    my $energy = sprintf("%.4f", delete $a->{energy});
    is( $energy, $joules, "$msg: energy" );

    is_deeply($a, $others, "$msg: characters, presses and distance");
}
