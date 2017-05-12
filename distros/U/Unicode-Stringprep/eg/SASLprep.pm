package Acme::Examples::Authen::SASL::SASLprep;

use strict;
use utf8;
use warnings;
require 5.006_000;

our $VERSION = '1.00';
$VERSION = eval $VERSION;

require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(saslprep);

use Unicode::Stringprep;

use Unicode::Stringprep::Mapping;
use Unicode::Stringprep::Prohibited;

my %C12_to_SPACE = ();
for(my $pos=0; $pos <= $#Unicode::Stringprep::Prohibited::C12; $pos+=2) 
{
  for(my $char = $Unicode::Stringprep::Prohibited::C12[$pos]; 
         defined $Unicode::Stringprep::Prohibited::C12[$pos]
	 && $char <= $Unicode::Stringprep::Prohibited::C12[$pos];
	 $char++) {
    $C12_to_SPACE{$char} = ' ';
  }
};

*saslprep = Unicode::Stringprep->new(
  3.2,
  [ \@Unicode::Stringprep::Mapping::B1,
    \%C12_to_SPACE ],
  'KC',
  [ \@Unicode::Stringprep::Prohibited::C12,
    \@Unicode::Stringprep::Prohibited::C21,
    \@Unicode::Stringprep::Prohibited::C22,
    \@Unicode::Stringprep::Prohibited::C3,
    \@Unicode::Stringprep::Prohibited::C4,
    \@Unicode::Stringprep::Prohibited::C5,
    \@Unicode::Stringprep::Prohibited::C6,
    \@Unicode::Stringprep::Prohibited::C7,
    \@Unicode::Stringprep::Prohibited::C8,
    \@Unicode::Stringprep::Prohibited::C9,
  ],
  1
);

1;
