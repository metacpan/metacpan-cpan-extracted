# these tests are useless in the automated build process
exit if $ENV{PERL_MM_USE_DEFAULT};

use Win32::Console;

$^W = 0;  # we get about a trillion warn_undef-s
$OUT = new Win32::Console(STD_OUTPUT_HANDLE);
$IN = new Win32::Console(STD_INPUT_HANDLE);

$OUT->Title("Win32::Console version $Win32::Console::VERSION TEST SUITE");
my($wLeft, $wTop, $wRight, $wBottom) = $OUT->Window();

explodeAttr($OUT, $FG_RED | $BG_YELLOW) if ($wLeft - $wRight);

# explodeAttr($OUT, $ATTR_NORMAL);
($wLeft, $wTop, $wRight, $wBottom) = $OUT->Window();

showAbout() if ($wLeft - $wRight);

$OUT->Cls();
($wLeft, $wTop, $wRight, $wBottom) = $OUT->Window();

Window($OUT, $FG_WHITE | $BG_BLUE, " ", $wLeft, $wTop, $wRight-$wLeft, 2);

$OUT->Cursor(3, 1);
$OUT->Write("Test   About   Quit");
$OUT->FillAttr($FG_BLACK | $BG_WHITE, 6, $wLeft+2, $wTop+1);

$menu=1;
@menupos = (0, $wLeft+2, $wLeft+9, $wLeft+17);
@menulen = (0, 6, 7, 6);

$OUT->FillAttr($FG_BLACK | $BG_WHITE, $menulen[$menu], $menupos[$menu], $wTop+1);

$IN->Mode(ENABLE_MOUSE_INPUT);

$string = "(Press ESC to exit)";
$OUT->Attr($FG_GRAY | $BG_BLUE);
$OUT->Cursor($wRight-$wLeft-length($string)-3, $wTop+1);
$OUT->Write($string);

# Position the cursor on the middle of the screen
# and make it visible as a full character
$mX = ($wRight  - $wLeft) / 2;
$mY = ($wBottom - $wTop)  / 2;
$OUT->Cursor($mX, $mY, 99, 1);

# Main loop
while ($key ne chr(27)) {
    last unless ($wLeft - $wRight);
    @event = $IN->Input();

    $do = 0;

    if ($event[0] == 1 and $event[1]) {
        $key = chr($event[5]);

        # ENTER
        if ($event[5] == 13) {
            $do = $menu;
        }

        # LEFT ARROW
        if ($event[3] == 37
        and $event[4] == 75
        and $menu > 1) {
            $menu = $menu - 1;
            highlightMenu($menu);
        }

        # RIGHT ARROW
        if ($event[3] == 39
        and $event[4] == 77
        and $menu < 3) {
            $menu = $menu + 1;
            highlightMenu($menu);
        }

    }
    elsif ($event[0]==2) {
        $mX = $event[1];
        $mY = $event[2];
        if ($event[3] == 1 and $mY == $wTop+1) {
            for $m (1..3) {
                if ($mX >= $menupos[$m] and $mX <= $menupos[$m]+$menulen[$m]) {
                    $menu = $m;
                    $do = $menu;
                }
            }
            highlightMenu($menu);
        }
    }
    if ($do == 1) {
        grayMenu();
        $T = chooseTest();
        &$T if $T;
        highlightMenu($menu);
    }
    elsif ($do == 2) {
        ($wLeft, $wTop, $wRight, $wBottom) = $OUT->Window();
        $cX = $wLeft + int((($wRight-$wLeft)-45)/2);
        $cY = $wTop  + int((($wBottom-$wTop)-8)/2);

        $BACKGROUND = $OUT->ReadRect($cX, $cY, $cX+45, $cY+8);
        showAbout();
        $OUT->WriteRect($BACKGROUND, $cX, $cY, $cX+45, $cY+8);

    }
    elsif ($do==3) {
        exit(0);
    }
    $OUT->Cursor($mX, $mY);
}
print "\n";


#=============
sub grayMenu {
#=============
    my $m;
    for $m (1..3) {
        $OUT->FillAttr($FG_GRAY | $BG_BLUE, $menulen[$m], $menupos[$m], $wTop+1);
    }
}

#==================
sub highlightMenu {
#==================
    my($menu) = @_;
    my $m;
    for $m (1..3) {
        if ($m == $menu) {
            $OUT->FillAttr($FG_BLACK | $BG_WHITE, $menulen[$m], $menupos[$m], $wTop+1);
        }
	else {
            $OUT->FillAttr($FG_WHITE | $BG_BLUE,  $menulen[$m], $menupos[$m], $wTop+1);
        }
    }
}


#==============
sub filledBox {
#==============
    my($O, $color, $char, $left, $top, $width, $height) = @_;
    my $row = 0;
    for $row ($top..$top+$height) {
        $O->FillAttr($color, $width, $left, $row);
        $O->FillChar($char,  $width, $left, $row);
    }
}

#==============
sub borderBox {
#==============
    my($O, $left, $top, $width, $height) = @_;

    $O->FillChar(chr(218), 1,        $left,          $top);
    $O->FillChar(chr(196), $width-2, $left+1,        $top);
    $O->FillChar(chr(191), 1,        $left+$width-1, $top);

    my $row = 0;
    for $row ($top+1..$top+$height-1) {
        $O->FillChar(chr(179), 1, $left,          $row);
        $O->FillChar(chr(179), 1, $left+$width-1, $row);
    }

    $O->FillChar(chr(192), 1,        $left,          $top+$height);
    $O->FillChar(chr(196), $width-2, $left+1,        $top+$height);
    $O->FillChar(chr(217), 1,        $left+$width-1, $top+$height);

}

#===========
sub Window {
#===========
    my($O, $Attr, $Char, $Col, $Row, $Width, $Height) = @_;
    filledBox($O, $Attr, $Char, $Col, $Row, $Width, $Height);
    borderBox($O, $Col, $Row, $Width, $Height);
}

#==================
sub writeCentered {
#==================
    my $O = shift;
    my $S = (shift or "");
    my $X = (shift or 0);
    my $Y = (shift or 0);
    $O->Cursor(int(($X-length($S))/2), $Y);
    $O->Write($S);
}

#===============
sub millisleep {
#===============
    require Win32 unless defined &Win32::GetTickCount;
    my $ctick = Win32::GetTickCount();
    my $etick = $ctick + $_[0];
    while ($ctick < $etick) { $ctick = Win32::GetTickCount(); }
}


#================
sub explodeAttr {
#================
    my $O    = shift;
    my $Attr = shift;
    $Attr = $ATTR_INVERSE unless defined($Attr);
    my($wLeft, $wTop, $wRight, $wBottom) = $O->Window();

    my $X = $wRight-$wLeft;
    my $Y = $wBottom-$wTop;

    my $times = int( ($X>$Y)? ($Y/2) : ($X/2) );

    my $left   = $wLeft + int($X/2);
    my $right  = $wLeft + int($X/2);
    my $top    = $wTop + int($Y/2);
    my $bottom = $wTop + int($Y/2);

    my($cip, $ciop);
    for $cip (0..$times) {
	last if $times == 0;
        for $ciop ($top..$bottom) {
            $O->FillAttr($Attr, ($right-$left), $left, $ciop);
        }
        $top    -= int(($Y/2)/$times);
        $left   -= int(($X/2)/$times);
        $bottom += int(($Y/2)/$times);
        $right  += int(($X/2)/$times);
        millisleep(5); # sleeps for 5 milliseconds
    }

    # the final touch
    ($wLeft, $wTop, $wRight, $wBottom) = $O->Window();
    $X = $wRight-$wLeft+1;
    $Y = $wBottom-$wTop+1;
    $O->FillAttr($Attr, $X*$Y, $wLeft, $wTop);
}


#==============
sub showAbout {
#==============
    my($wLeft, $wTop, $wRight, $wBottom) = $OUT->Window();

    my $X = $wRight-$wLeft;
    my $Y = $wBottom-$wTop;

    my $dX = 45;
    my $dY = 8;

    my $cX = $wLeft + int(($X-$dX)/2);
    my $cY = $wTop  + int(($Y-$dY)/2);

    Window($OUT, $FG_WHITE | $BG_BLUE, " ",  $cX, $cY, $dX, $dY);
    $OUT->Attr($FG_WHITE | $BG_BLUE);
    writeCentered($OUT, "Win32::Console version $Win32::Console::VERSION",               $X, $cY+2);
    writeCentered($OUT, "TEST SUITE",                                $X, $cY+4);
    writeCentered($OUT, "by Aldo Calpini <dada\@divinf.it>",         $X, $cY+5);
    writeCentered($OUT, "Press any key or mouse button to continue", $X, $cY+6);

    # save settings
    my($oldX, $oldY, $oldS, $oldV) = $OUT->Cursor();
    my $oldmode = $IN->Mode();


    $IN->Mode(ENABLE_MOUSE_INPUT);
    $OUT->Cursor(-1, -1, -1, 0); # hide the cursor
    $IN->Flush();
    # millisleep(500);
    $IN->Flush();

    my $color = 0;
    $string = "TEST SUITE";
    my $sX = int(($X-length($string))/2);
    my $sY = $cY+4;
    my $tX = $sX;
    #
    # watch what's happening without have
    # to wait for something to happen
    #
    my @event = $IN->PeekInput();
    until(($event[0]==1 and $event[1]==1)
    or    ($event[0]==2 and $event[3]!=0)) {

        #
        # cycle colors on "TEST SUITE"
        #
        $OUT->FillAttr($color | $BG_BLUE, 1, $tX, $sY);
        $tX++;
        if ($tX > $sX+length($string)) {
            $tX = $sX ;
            $color++;
            $color = 0 if $color>15;
        }

        #
        # process all pending input events
        #
        for(0..$IN->GetEvents()-1) {
            @event = $IN->Input();
        }
    }
    $IN->Flush();

    # restore settings
    $IN->Mode($oldmode);
    $OUT->Cursor($oldX, $oldY, $oldS, $oldV);
}


#=============
sub testInfo {
#=============

    # save settings
    my $oldT = $OUT->Title();
    my($oldX, $oldY, $oldS, $oldV) = $OUT->Cursor();
    my($wLeft, $wTop, $wRight, $wBottom) = $OUT->Window();

    my $X = $wRight-$wLeft;
    my $Y = $wBottom-$wTop;

    my @towrite = ();
    my @info = $OUT->Info();
    push(@towrite, sprintf("Console screen buffer size:     %3d, %3d", $info[0], $info[1]));
    push(@towrite, sprintf("Current cursor position:        %3d, %3d", $info[2], $info[3]));
    push(@towrite, sprintf("Current attribute:              %3d     ", $info[4]));
    push(@towrite, sprintf("Window coordinates:    %3d, %3d-%3d, %3d", $info[5], $info[6],
                                                                       $info[7], $info[8]));
    push(@towrite, sprintf("Maximum window size:            %3d, %3d", $info[9], $info[10]));

    my $string = "";
    my $max = 0;
    foreach $string (@towrite) {
        $max=length($string) if length($string)>$max;
    }
    my $dX = $max + 4;
    my $dY = $#towrite + 4;

    my $cX = $wLeft + int(($X-$dX)/2);
    my $cY = $wTop  + int(($Y-$dY)/2);

    my $BACKGROUND = $OUT->ReadRect($cX, $cY, $cX+$dX, $cY+$dY);

    Window($OUT, $FG_WHITE | $BG_BLUE, " ",  $cX, $cY, $dX, $dY);
    $OUT->Attr($FG_WHITE | $BG_BLUE);
    for $row ($cY+1..$cY+1+$#towrite) {
        $OUT->Cursor($cX+2, $row);
        $OUT->Write($towrite[$row-$cY-1]);
    }

    writeCentered($OUT, "Press a key or mouse button to continue", $X, $cY+$#towrite+3);

    $OUT->Cursor(-1, -1, -1, 0); # hide the cursor

    $IN->Flush();
    my @event = $IN->Input();
    until(($event[0]==1 and $event[1]==1)
    or    ($event[0]==2 and $event[3]!=0)) {
        @event = $IN->Input();
    }
    $IN->Flush();

    $OUT->Window(1, $wLeft, $wTop, $wRight, $wBottom);
    $OUT->WriteRect($BACKGROUND, $cX, $cY, $cX+$dX, $cY+$dY);
    $OUT->Cursor($oldX, $oldY, $oldS, $oldV);
    $OUT->Title($oldT);
}

#==============
sub testTitle {
#==============

    # save settings
    my $oldT = $OUT->Title();
    my($oldX, $oldY, $oldS, $oldV) = $OUT->Cursor();

    $OUT->Cursor(-1, -1, -1, 0); # hide the cursor

    my($wLeft, $wTop, $wRight, $wBottom) = $OUT->Window();

    my $X = $wRight-$wLeft;
    my $Y = $wBottom-$wTop;

    my $dX = 14;
    my $dY = 2;

    my $cX = $wLeft + int(($X-$dX)/2);
    my $cY = $wTop  + int(($Y-$dY)/2);

    my $BACKGROUND = $OUT->ReadRect($cX, $cY, $cX+$dX, $cY+$dY);

    Window($OUT, $FG_WHITE | $BG_BLUE, " ",  $cX, $cY, $dX, $dY);
    $OUT->Attr($FG_WHITE | $BG_BLUE);
    writeCentered($OUT, "Testing...", $X, $cY+1);

    my $string = "I'M WRITING ON THE TITLE BAR! I'M WRITING ON THE TITLE BAR!";
    my $c = 0;
    for $c (0..length($string)) {
        $OUT->Title(substr($string, 0, $c));
        millisleep(50);
    }


    for $c (0..666) {
        $OUT->Title("I'M FLASHING THE TITLE BAR! I'M FLASHING THE TITLE BAR!");
        $OUT->Title("");
    }

    $OUT->WriteRect($BACKGROUND, $cX, $cY, $cX+$dX, $cY+$dY);
    $OUT->Cursor($oldX, $oldY, $oldS, $oldV);
    $OUT->Title($oldT);
}

#===============
sub testScroll {
#===============

    # save settings
    my $oldT = $OUT->Title();
    my($oldX, $oldY, $oldS, $oldV) = $OUT->Cursor();

    $OUT->Cursor(-1, -1, -1, 0); # hide the cursor

    my($wLeft, $wTop, $wRight, $wBottom) = $OUT->Window();

    my $X = $wRight-$wLeft;
    my $Y = $wBottom-$wTop;

    my $dX = 48;
    my $dY = 4;

    my $cX = $wLeft + int(($X-$dX)/2);
    my $cY = $wTop  + int(($Y-$dY)/2);

    filledBox($OUT, $FG_GRAY | $BG_BLACK, " ",  $wLeft, $wTop+3, $wRight, $wBottom);

    Window($OUT, $FG_WHITE | $BG_BLUE, " ",  $cX, $cY, $dX, $dY);
    $OUT->Attr($FG_WHITE | $BG_BLUE);
    writeCentered($OUT, "Scrolling", $X, $cY+1);
    writeCentered($OUT, "Scroll this window around with the arrow keys", $X, $cY+2);
    writeCentered($OUT, "Press ESC to end test", $X, $cY+3);

    $IN->Flush();
    my $key = 0;
    my @event = ();
    my $test = 1;
    my $return = "";
    while ($key != 27) {

        @event = $IN->Input();

        if ($event[0] == 1 and $event[1]) {


            # LEFT ARROW
            if ($event[3] == 37 and $event[4] == 75 and $cX > $wLeft) {
                $result = $OUT->Scroll($cX, $cY, $cX+$dX, $cY+$dY, $cX-1, $cY, " ", $FG_GRAY|$BG_BLACK, $wLeft, $wTop, $wRight, $wBottom);
                $cX--;
            }

            # RIGHT ARROW
            if ($event[3] == 39  and $event[4] == 77 and $cX < $wRight-$dX) {
                $result = $OUT->Scroll($cX, $cY, $cX+$dX, $cY+$dY, $cX+1, $cY, " ", $FG_GRAY|$BG_BLACK, $wLeft, $wTop, $wRight, $wBottom);
                $cX++;
            }

            # UP ARROW
            if ($event[3] == 38 and $event[4] == 72 and $cY > $wTop+3) {
                $result = $OUT->Scroll($cX, $cY, $cX+$dX, $cY+$dY, $cX, $cY-1, " ", $FG_GRAY|$BG_BLACK, $wLeft, $wTop, $wRight, $wBottom);
                $cY--;
            }

            # DOWN ARROW
            if ($event[3] == 40 and $event[4] == 80 and $cY < $wBottom-$dY) {
                $result = $OUT->Scroll($cX, $cY, $cX+$dX, $cY+$dY, $cX, $cY+1, " ", $FG_GRAY|$BG_BLACK, $wLeft, $wTop, $wRight, $wBottom);
                $cY++;
            }

            $key = $event[5];
        }

    }
    $IN->Flush();

    filledBox($OUT, $FG_GRAY | $BG_BLACK, " ",  $cX, $cY, $dX, $dY);
    $OUT->Cursor($oldX, $oldY, $oldS, $oldV);
    $OUT->Title($oldT);
}


#============
sub testBox {
#============

    # save settings
    my $oldT = $OUT->Title();
    my($oldX, $oldY, $oldS, $oldV) = $OUT->Cursor();

    $OUT->Cursor(-1, -1, -1, 0); # hide the cursor

    my($wLeft, $wTop, $wRight, $wBottom) = $OUT->Window();

    my @FG_COLORS=(
        $FG_BLACK,
        $FG_BLUE,
        $FG_LIGHTBLUE,
        $FG_RED,
        $FG_LIGHTRED,
        $FG_GREEN,
        $FG_LIGHTGREEN,
        $FG_MAGENTA,
        $FG_LIGHTMAGENTA,
        $FG_CYAN,
        $FG_LIGHTCYAN,
        $FG_BROWN,
        $FG_YELLOW,
        $FG_GRAY,
        $FG_WHITE,
    );

    my @BG_COLORS=(
        $BG_BLACK,
        $BG_BLUE,
        $BG_LIGHTBLUE,
        $BG_RED,
        $BG_LIGHTRED,
        $BG_GREEN,
        $BG_LIGHTGREEN,
        $BG_MAGENTA,
        $BG_LIGHTMAGENTA,
        $BG_CYAN,
        $BG_LIGHTCYAN,
        $BG_BROWN,
        $BG_YELLOW,
        $BG_GRAY,
        $BG_WHITE,
    );

    my $X = $wRight-$wLeft;
    my $Y = $wBottom-$wTop;

    my $dX = 30;
    my $dY = 2;

    my $cX = $wLeft + int(($X-$dX)/2);
    my $cY = $wTop  + int(($Y-$dY)/2);

    $IN->Flush();
    my $key = 0;
    my @event = $IN->PeekInput();
    my $x = 0;
    my $y = 0;
    my $w = 0;
    my $h = 0;
    my $FG = 0;
    my $BG = 0;
    until(($event[0]==1 and $event[1]==1)
    or    ($event[0]==2 and $event[3]!=0)) {

        $x = rand($X);
        $y = 3+rand($Y-3);
        $w = rand($X-$x);
        $h = rand($Y-$y);

        $FG = $FG_COLORS[rand($#FG_COLORS)];
        $BG = $BG_COLORS[rand($#BG_COLORS)];

        if (rand(100)>50 and $w>2 and $h>2) {
            borderBox($OUT, $x, $y, $w, $h);
        }
	else {
            filledBox($OUT, $FG|$BG, " ", $x, $y, $w, $h);
        }

        # process all pending input events
        for(0..$IN->GetEvents()-1) {
            @event = $IN->Input();
        }
    }
    $IN->Flush();

    $OUT->Cursor($oldX, $oldY, $oldS, $oldV);
    $OUT->Title($oldT);
}


#===============
sub testWindow {
#===============

    # save settings
    my $oldT = $OUT->Title();
    my($oldX, $oldY, $oldS, $oldV) = $OUT->Cursor();
    my($wLeft, $wTop, $wRight, $wBottom) = $OUT->Window();

    my $X = $wRight-$wLeft;
    my $Y = $wBottom-$wTop;

    my $dX = 14;
    my $dY = 2;

    my $cX = $wLeft + int(($X-$dX)/2);
    my $cY = $wTop  + int(($Y-$dY)/2);

    my $BACKGROUND = $OUT->ReadRect($cX, $cY, $cX+$dX, $cY+$dY);

    Window($OUT, $FG_WHITE | $BG_BLUE, " ",  $cX, $cY, $dX, $dY);
    $OUT->Attr($FG_WHITE | $BG_BLUE);
    writeCentered($OUT, "Testing...", $X, $cY+1);

    $OUT->Cursor(-1, -1, -1, 0); # hide the cursor

    my($maxx, $maxy) = $OUT->MaxWindow();
    $OUT->Window(1, 0, 0, $maxx, $maxy);

    while ($maxx>1 and $maxy>1) {
        $maxx--;
        $maxy--;
        $OUT->Window(1, 0, 0, $maxx, $maxy);
        millisleep(50);
    }

    $OUT->Window(1, $wLeft, $wTop, $wRight, $wBottom);
    $OUT->WriteRect($BACKGROUND, $cX, $cY, $cX+$dX, $cY+$dY);
    $OUT->Cursor($oldX, $oldY, $oldS, $oldV);
    $OUT->Title($oldT);
}




#===============
sub chooseTest {
#===============

    # save settings
    my $oldT = $OUT->Title();
    my($oldX, $oldY, $oldS, $oldV) = $OUT->Cursor();
    my($wLeft, $wTop, $wRight, $wBottom) = $OUT->Window();

    my $X = $wRight-$wLeft;
    my $Y = $wBottom-$wTop;

    my $dX = 45;
    my $dY = 6;

    my $cX = $wLeft;
    my $cY = $wTop  + 3;

    my $BACKGROUND = $OUT->ReadRect($cX, $cY, $cX+$dX, $cY+$dY);

    Window($OUT, $FG_WHITE | $BG_BLUE, " ",  $cX, $cY, $dX, $dY);

    $OUT->Attr($FG_WHITE | $BG_BLUE);

    $OUT->Cursor($wLeft+2, $cY+1);    $OUT->Write("Console Info");
    $OUT->Cursor($wLeft+2, $cY+2);    $OUT->Write("Random Boxes");
    $OUT->Cursor($wLeft+2, $cY+3);    $OUT->Write("Scrolling");
    $OUT->Cursor($wLeft+2, $cY+4);    $OUT->Write("Title Bar");
    $OUT->Cursor($wLeft+2, $cY+5);    $OUT->Write("Window Size");

    $IN->Flush();
    my $key = 0;
    my @event = ();
    my $test = 1;
    highlightTest(1);
    my $return = "";
    my($mX, $mY) = $OUT->Cursor();

    while ($key != 27) {

        @event = $IN->Input();

        # A KEY PRESSED
        if ($event[0] == 1 and $event[1]) {

            # UP ARROW
            if ($event[3] == 38 and $event[4] == 72 and $test > 1) {
                $test=$test-1;
                highlightTest($test);
            }

            # DOWN ARROW
            if ($event[3] == 40 and $event[4] == 80 and $test < 5) {
                $test=$test+1;
                highlightTest($test);
            }

            $key = $event[5];

            # ENTER
            if ($key == 13) {
                $return = ("", "testInfo", "testBox",
                               "testScroll", "testTitle", "testWindow")[$test];
                $key = 27;
            }
        }
	elsif ($event[0] == 2) {
            $mX = $event[1];
            $mY = $event[2];
            if ($event[3] == 1) {
                for $m (1..5) {
                    if (($mX >= $cX+1 and $mX <= $cX+$dX)
                    and ($mY == $cY+$m) ) {
                        $return = ("", "testInfo", "testBox",
                                       "testScroll", "testTitle", "testWindow")[$m];
                        $key = 27;
                    }
                }
            }
        }
        $OUT->Cursor($mX, $mY);
    }
    $IN->Flush();

    $OUT->WriteRect($BACKGROUND, $cX, $cY, $cX+$dX, $cY+$dY);
    $OUT->Cursor($oldX, $oldY, $oldS, $oldV);
    $OUT->Title($oldT);
    return $return;
}

#==================
sub highlightTest {
#==================
    my($i) = @_;
    for $m (1..5) {
        if ($m == $i) {
            $OUT->FillAttr($FG_BLACK | $BG_WHITE, 43, $wLeft+1, $wTop+3+$m);
        }
	else {
            $OUT->FillAttr($FG_WHITE | $BG_BLUE, 43, $wLeft+1, $wTop+3+$m);
        }
    }
}


