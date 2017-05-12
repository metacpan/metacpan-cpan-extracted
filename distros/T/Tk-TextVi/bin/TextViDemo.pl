# Demonstration of Tk::TextVi

use strict;
use warnings;

# Test it without a make install
BEGIN { unshift @INC, '../lib' }

use Tk;
use Tk::TextVi;

my $mw = MainWindow->new(  );

my $frame = $mw->Frame(  )->pack( -side => 'top' );
my $split = 0;

my $text = $frame->TextVi(
    -background => '#FFFFFF',
    -statuscommand => \&showstat,
    -messagecommand => \&showmsg,
    -errorcommand => \&showerr,
    -systemcommand => \&dosys,
    -height => 20,
    -width => 55,
    )->pack(  );

my $left = $mw->Label( -font => 'Courier' )->pack( -side => 'left' );
my $right = $mw->Label( -font => 'Courier' )->pack( -side => 'right' );

{
    undef $/;
    $text->Contents( <DATA> );
}

$text->SetCursor('1.0');
$text->focus();

MainLoop;

sub dosys {
    my ($action) = @_;

    if( $action eq 'quit' ) {
        Tk::exit(0);
    }
    elsif( $action eq 'split' ) {
        return "Already split" if $split;
        $split = 1;

        # ***** it.  There's some magical set of pack() flags that
        # will make the frame divide in two but after a half hour of
        # the nonsensical behavior plus four interruptions I don't
        # ******* care any more.
        $text->configure( -height => 10 );
        return $frame->TextVi(
            -background => '#FFFFFF',
            -statuscommand => \&showstat,
            -messagecommand => \&showmsg,
            -errorcommand => \&showerr,
            -systemcommand => \&dosys,
            -height => 10,
            -width => 55,
            )->pack( -side => 'top' );
    }

    return;
}

sub showstat {
    my ($mode,$keys) = @_;

    $keys =~ s/([\x01-\x19])/'^'.chr(0x40+ord($1))/ge;

    my $rec = (substr($mode,1,1) eq 'q') ? 'recording' : '';
    $mode = substr $mode, 0, 1;

    $left->configure( -foreground => '#000000' );

    if( $mode eq 'n' ) {
        $left->configure( -text => ' '.$rec );
        $right->configure( -text => $keys );
    }
    elsif( $mode eq 'c' ) {
        $left->configure( -text => ':' . $keys );
    }
    elsif( $mode eq '/' ) {
        $left->configure( -text => '/' . $keys );
    }
    elsif( $mode eq 'i' ) {
        $left->configure( -text => '-- INSERT --'.$rec );
        $right->configure( -text => $keys );
    }
    elsif( $mode eq 'R' ) {
        $left->configure( -text => '-- REPLACE --'.$rec );
        $right->configure( -text => $keys );
    }
    elsif( $mode eq 'v' ) {
        $left->configure( -text => '-- VISUAL --'.$rec );
        $right->configure( -text => $keys );
    }
    elsif( $mode eq 'V' ) {
        $left->configure( -text => '-- VISUAL LINE --'.$rec );
        $right->configure( -text => $keys );
    }
}

sub showmsg {
    $left->configure( -foreground => '#000000' );
    $left->configure( -text => $text->viMessage() );
}

sub showerr {
    $left->configure( -foreground => '#FF0000' );
    $left->configure( -text => $text->viError() );
}

__DATA__
                     Tk::TextVi
-+* Yet Another Stupid Thing Created With Perl / Tk *+-

I needed a quick way to edit test scripts, run them
through a program that generated test data from them,
send them over a TCP/IP connection and display the
result.  Perl easily handled all four parts:  Perl/Tk
provided a GUI to display and edit the script and
results, executing programs, pipes and sockets are Perl
built-ins, and I have a nice module that handles the
specific protocol.

But I'm used to using Vim for my text editing and often
typed things like 'dt)', ':w' and so on in the script.
I can't be wasting valuable seconds typing 'delete
delete delete delete...'  Obviously a more powerful
widget is needed...

Tk::TextVi acts just like a normal Tk::Text with one
big exception: InsertKeypress() has been overrided to
handle keyboard input in a slightly more useful way.

A good chunck of the basic commands are implemented:
  a d f ga gg h i j k l m n o p q r t x v y D G O V
  0 @ ` $ % / :map :nohlsearch :split :quit
along with counts and registers.
