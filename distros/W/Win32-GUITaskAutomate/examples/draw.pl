#!C:\Perl\bin\perl.exe -w

use strict;
use warnings;

use Win32::GUITaskAutomate;


print <<'END_NOTE';

****************************************************
    This example opens up MSPaint and draws
    a face
****************************************************
    NOTE: The example works for MY theme/color
    settings. If you want to run it on your
    computer open up MSPaint, screenshot
    the image of the brush button and save it
    as brush.PNG found in this directory.
    (note2: size matters too, make sure it's
    close to the brush.PNG that came with distro)
****************************************************

END_NOTE

my $robot = Win32::GUITaskAutomate->new(
   load => {
           pic    => 'brush.PNG',
    },
);

$robot->do( [
        { save => 1 }, # save original mouse cursor position
        "{LWI}r",     # bring up "Run" dialog and run MSPaint
        [.5],         # pausing ocasionally to allow the stuff to
        "mspaint~",   # show up
        [1],
        "^e",
        [.5],
        "50{TAB}50~", # resize the image to 50x50
    ],
);

# now we know the brush is there, but we need the location.
# the find_do() will find it and report the coordinates off of which
# we can base the position of the brush to draw our "face" :)
$robot->find_do(
    pic => [
        { lmb => 1, x => 5, y => 5 },
        { drag => 1, x => 35, y => -70, d_x => 70, d_y => -70 },
        { drag => 1, x => 70, y => -70, d_x => 70, d_y => -30 },
        { drag => 1, x => 70, y => -30, d_x => 35, d_y => -30 },
        { drag => 1, x => 35, y => -30, d_x => 35, d_y => -70 },
        { drag => 1, x => 45, y => -40, d_x => 60, d_y => -40 },
        { lmb  => 1, x => 45, y => -60 },
        { lmb  => 1, x => 60, y => -60 },
        { restore => 1 }, # restore original mouse position
    ],
    10, # 10 second timeout
);


print "I am done \\o/\n";


=pod

    *****************************************
    This example opens up MSPaint and draws
    a face
    *****************************************
    NOTE: The example works for MY theme/color
    settings. If you want to run it on your
    computer open up MSPaint, screenshot
    the image of the brush button and save it
    as brush.PNG found in this directory.
    (note2: size matters too, make sure it's
    close to the brush.PNG that came with distro)
    *****************************************

    To run:   perl draw.pl

=cut
