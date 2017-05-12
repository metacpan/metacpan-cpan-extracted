use strict;
use warnings;

use Win32::Sound;

# Create the object
my $WAV = new Win32::Sound::WaveOut(44100, 8, 2);

my $data = ""; 
my $counter = 0;
my $increment = 440/44100;

# Generate 44100 samples ( = 1 second)
for my $i (1..44100) {

    # Calculate the pitch 
    # (range 0..255 for 8 bits)
    my $v = sin($counter*2*3.14) * 127 + 128;

    # "pack" it twice for left and right
    $data .= pack("CC", $v, $v);

    $counter += $increment;
}

$WAV->Load($data);       # get it
$WAV->Write();           # hear it
1 until $WAV->Status();  # wait for completion
$WAV->Save("sinus.wav"); # write to disk
$WAV->Unload();          # drop it
