package VOMS::Lite::Audit;

use 5.004;
use strict;

use VOMS::Lite::ASN1Helper qw(Hex ASN1Index ASN1Unwrap ASN1Wrap);

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);

$VERSION = '0.20';

sub Create {
  my ($location,$critical) = @_;
# SEQ{OID{1.3.6.1.4.1.18141.3.100.5.1 }.[CRITICAL].OS{URL}} # NB Critical is not generally used
  if ( $location !~ m#^https?://.*# ) { return ""; }
  my $Audit=ASN1Wrap('30','060c2b06010401818d5d03640501'.
                       ($critical?"01010f":"").
                       ASN1Wrap('04',Hex($location)));
  $Audit =~ s/(..)/pack('C',hex($&))/ge;
  return $Audit;
}

sub Examine {
  my $decoded=$_[0];
  if ( $decoded !~ /^\x30/ ) { return { Errors => ["Expecting Sequence (0x30...)"] }; }
  if ( ASN1Unwrap($decoded) =~ /^\x06\x0c\x2b\x06\x01\x04\x01\x81\x8d\x5d\x03\x64\x05\x01((?:\x01\x01[^\0])?)(\x04.*)$/ ) {
    my $URL=ASN1Unwrap($2);
    if ( $URL !~ /^https?:\/\//) { return { Errors => ["Badly encoded Audit URL"] }; }
    return { URL=>$URL, critical => (($1=="")?0:1) };
  }
  return { Errors => ["Not an Audit Extension"] };
} 

################################################################

1;
__END__

=head1 NAME

VOMS::Lite::Audit - Perl extension for the creation of and parsing of DER encoded Audit Extension for the VOMS::Lite module.

=head1 SYNOPSIS

  use VOMS::Lite::Audit;


  my $DER = VOMS::Lite::Audit::Create('http://audit.endpoint.acme/');
  my $DER = VOMS::Lite::Audit::Create('http://audit.endpoint.acme/',1); #Set to critical (Not Generally Used/Recognised)

  my %Audit = %{ VOMS::Lite::Audit::Examine($DERencodedChunk) };
  print %Audit{'URL'}."\n";
  if ( %Audit{'critical'} ) {print "Is critical\n";}

  NB this is an experimental extension:
  There are known encoding issues that will change as the Auditing Service is developed.
  When this happens this module will need updating to match.

=head1 DESCRIPTION

  Creates or Examines an Audit extension for Proxy certificates

=head2 EXPORT

None.

=head1 SEE ALSO

This module was originally designed for the NGS SARoNGS service at
The University of Manchester.

http://www.mc.manchester.ac.uk/projects/sarongs/
now http://www.rcs.manchester.ac.uk/projects/sarongs/

Globus Incubator project
  http://dev.globus.org/wiki/Incubator/Proxy-Audit

JISC funded project
  http://www.jisc.ac.uk/whatwedo/programmes/aim/pcai.aspx

=head1 AUTHOR

Mike Jones <mike.jones@manchester.ac.uk>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Mike Jones

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut

