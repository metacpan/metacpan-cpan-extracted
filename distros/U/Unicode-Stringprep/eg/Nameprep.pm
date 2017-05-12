package Acme::Examples::Net::IDN::Nameprep;

use strict;
use utf8;
use warnings;
require 5.006_000;

our $VERSION = '1.00';
$VERSION = eval $VERSION;

require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(nameprep);

use Unicode::Stringprep;

use Unicode::Stringprep::Mapping;
use Unicode::Stringprep::Prohibited;

*nameprep = Unicode::Stringprep->new(
  3.2,
  [ 
    @Unicode::Stringprep::Mapping::B1, 
    @Unicode::Stringprep::Mapping::B2 
  ],
  'KC',
  [
    @Unicode::Stringprep::Prohibited::C12,
    @Unicode::Stringprep::Prohibited::C22,
    @Unicode::Stringprep::Prohibited::C3,
    @Unicode::Stringprep::Prohibited::C4,
    @Unicode::Stringprep::Prohibited::C5,
    @Unicode::Stringprep::Prohibited::C6,
    @Unicode::Stringprep::Prohibited::C7,
    @Unicode::Stringprep::Prohibited::C8,
    @Unicode::Stringprep::Prohibited::C9
  ],
  1,
);

1;
