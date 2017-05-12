use strict;
use warnings;

use Win32::Sound;

push @ARGV, "welcome.wav" if $#ARGV < 0;

foreach my $file (@ARGV) {
    my($hz, $bit, $channels) = Win32::Sound::Format($file);
    if($hz and $bit and $channels) {
        printf( "%s: %.3fkHz %d-bit %s\n",
            $file,
            ($hz/1000),
            $bit,
            ( ($channels == 1) ? "Mono" : "Stereo" )
        );
    } else {
        printf( "%s: not a wave file!\n", $file);
    }
}

