# https://learn.microsoft.com/en-us/dotnet/api/system.console.beep?view=net-8.0
# This example demonstrates the System::Console->Beep(Int, Int) method

use 5.014;
use warnings;

use lib '../lib', 'lib';
use Win32::Console::DotNet;
use System;

# Define the frequencies of notes in an octave, as well as
# silence (rest).
use constant {
  REST    => 0,
  GbelowC => 196,
  A       => 220,
  Asharp  => 233,
  B       => 247,
  C       => 262,
  Csharp  => 277,
  D       => 294,
  Dsharp  => 311,
  E       => 330,
  F       => 349,
  Fsharp  => 370,
  G       => 392,
  Gsharp  => 415,
};

# Define the duration of a note in units of milliseconds.
use constant WHOLE     => 1600;
use constant HALF      => int(WHOLE/2);
use constant QUARTER   => int(HALF/2);
use constant EIGHTH    => int(QUARTER/2);
use constant SIXTEENTH => int(EIGHTH/2);

# Declare the first few notes of the song, "Mary Had A Little Lamb".
my $mary = [
  { toneVal => B, durVal => QUARTER },
  { toneVal => A, durVal => QUARTER },
  { toneVal => GbelowC, durVal => QUARTER },
  { toneVal => A, durVal => QUARTER },
  { toneVal => B, durVal => QUARTER },
  { toneVal => B, durVal => QUARTER },
  { toneVal => B, durVal => HALF },
  { toneVal => A, durVal => QUARTER },
  { toneVal => A, durVal => QUARTER },
  { toneVal => A, durVal => HALF },
  { toneVal => B, durVal => QUARTER },
  { toneVal => D, durVal => QUARTER },
  { toneVal => D, durVal => HALF },
];

# Play the notes in a song.
sub play {
  my $tune = shift;
  require Time::HiRes;

  foreach my $n (@$tune) {
    if ($n->{toneVal} == REST) {
      Time::HiRes::sleep($n->{durVal}/1000);
    }
    else {
      Console->Beep($n->{toneVal}, $n->{durVal});
    }
  }
}

sub main {
  # Play the song
  play($mary);
  return 0;
}

exit main();

__END__

=pod

This example produces the following results:

This example plays the first few notes of "Mary Had A Little Lamb"
through the console speaker.
