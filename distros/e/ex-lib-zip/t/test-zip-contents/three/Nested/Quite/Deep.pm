#!perl -w
package Nested::Quite::Deep;
use strict;
use AutoLoader 'AUTOLOAD';
use Exporter;
use vars qw (@ISA @EXPORT_OK);

@ISA = qw (Exporter);
@EXPORT_OK = qw (spam spanish_inquisition panic penguin);

sub spam {
  "Bloody Vikings";
}

1;
__END__
sub spanish_inquisition {
  my @weapons = ("Fear", "Surprise", "Ruthless efficiency",
		 "Fanatical loyalty to the Pope");
  return @weapons[0..rand(@weapons)];
}

sub panic {
  "Burma";
}

sub penguin {
  "It's 8pm and time for the penguin on top of your TV to explode";
  # This will amuse the BSD fans
}
