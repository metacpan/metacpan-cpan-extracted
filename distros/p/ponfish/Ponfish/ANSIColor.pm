#!perl

package Ponfish::ANSIColor;

use strict;
require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Ponfish::Config;
use Term::ANSIColor;

@ISA = qw(Exporter);
@EXPORT = qw( colored );

{
  no warnings;		# We're redefining the 'colored' routine in ANSIColor...

  sub colored {
    if ( WINDOWS ) {
      return $_[1];
    } else {
      return Term::ANSIColor::colored( @_ );
    }
  }
}
1;
