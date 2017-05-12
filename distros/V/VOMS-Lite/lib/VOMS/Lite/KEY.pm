package VOMS::Lite::KEY;

use 5.004;
use strict;

use VOMS::Lite::ASN1Helper qw(ASN1Index ASN1Unwrap);

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);

$VERSION = '0.20';

sub Examine {

  my ($decoded,$dataref)=@_;
  my %Values=%$dataref;
  my @ASN1Index=ASN1Index($decoded);

  my $index=0;
  my $ignoreuntil=0;
  my ($Keyversion,$Keymodulus,$KeypublicExponent,$KeyprivateExponent,$Keyprime1,$Keyprime2,$Keyexponent1,$Keyexponent2,$Keycoefficient);


# Test for PKCS8
  if ($ASN1Index[2]->[2] == 16) { # This is probably a PKCS8 key
    my ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN) = @{$ASN1Index[5]};
    my $newdecoded=substr($decoded,$HEADSTART,($HEADLEN+$CHUNKLEN));
    if ( $TAG == 4 ) {
      $decoded=ASN1Unwrap($newdecoded);
      @ASN1Index=ASN1Index($decoded);
    }
  }

  shift @ASN1Index; #Key Sequence
  foreach (@ASN1Index) {
    my ($CLASS,$CONSTRUCTED,$TAG,$HEADSTART,$HEADLEN,$CHUNKLEN) = @$_;
    if ( $HEADSTART < $ignoreuntil ) { next; }
    else {
      if    ($index==0 && $TAG==2)  {$Keyversion         = substr($decoded,$HEADSTART,($HEADLEN+$CHUNKLEN));}
      elsif ($index==1 && $TAG==2)  {$Keymodulus         = substr($decoded,$HEADSTART,($HEADLEN+$CHUNKLEN));}
      elsif ($index==2 && $TAG==2)  {$KeypublicExponent  = substr($decoded,$HEADSTART,($HEADLEN+$CHUNKLEN));}
      elsif ($index==3 && $TAG==2)  {$KeyprivateExponent = substr($decoded,$HEADSTART,($HEADLEN+$CHUNKLEN));}
      elsif ($index==4 && $TAG==2)  {$Keyprime1          = substr($decoded,$HEADSTART,($HEADLEN+$CHUNKLEN));}
      elsif ($index==5 && $TAG==2)  {$Keyprime2          = substr($decoded,$HEADSTART,($HEADLEN+$CHUNKLEN));}
      elsif ($index==6 && $TAG==2)  {$Keyexponent1       = substr($decoded,$HEADSTART,($HEADLEN+$CHUNKLEN));}
      elsif ($index==7 && $TAG==2)  {$Keyexponent2       = substr($decoded,$HEADSTART,($HEADLEN+$CHUNKLEN));}
      elsif ($index==8 && $TAG==2)  {$Keycoefficient     = substr($decoded,$HEADSTART,($HEADLEN+$CHUNKLEN));}
      $index++;
      $ignoreuntil=$HEADSTART+$HEADLEN+$CHUNKLEN;
    }
  }

  if (defined $Values{Keyversion})         {my @n=ASN1Unwrap($Keyversion);         $Values{Keyversion}         = $n[5];}
  if (defined $Values{Keymodulus})         {my @n=ASN1Unwrap($Keymodulus);         $Values{Keymodulus}         = $n[5];}
  if (defined $Values{KeypublicExponent})  {my @n=ASN1Unwrap($KeypublicExponent);  $Values{KeypublicExponent}  = $n[5];}
  if (defined $Values{KeyprivateExponent}) {my @n=ASN1Unwrap($KeyprivateExponent); $Values{KeyprivateExponent} = $n[5];}
  if (defined $Values{Keyprime1})          {my @n=ASN1Unwrap($Keyprime1);          $Values{Keyprime1}          = $n[5];}
  if (defined $Values{Keyprime2})          {my @n=ASN1Unwrap($Keyprime2);          $Values{Keyprime2}          = $n[5];}
  if (defined $Values{Keyexponent1})       {my @n=ASN1Unwrap($Keyexponent1);       $Values{Keyexponent1}       = $n[5];}
  if (defined $Values{Keyexponent2})       {my @n=ASN1Unwrap($Keyexponent2);       $Values{Keyexponent2}       = $n[5];}
  if (defined $Values{Keycoefficient})     {my @n=ASN1Unwrap($Keycoefficient);     $Values{Keycoefficient}     = $n[5];}

  return (\%Values);
}

################################################################

1;
__END__

=head1 NAME

VOMS::Lite::KEY - Perl extension for parsing DER encoded KEY for the VOMS::Lite module.

=head1 SYNOPSIS

  use VOMS::Lite::KEY;

  # Call the Examine function with two arguments
  #        a string containing a DER encoded key,
  #        and a hash of required information (see DESCRIPTION)
  my %KeyInfo = %{ VOMS::Lite::KEY::Examine($keyder, {Keymodulus=>"",KeyprivateExponent=>""} ) };
  print Hex($KeyInfo{'Keymodulus'})."\n".Hex($KeyInfo{'KeyprivateExponent'})."\n";

=head1 DESCRIPTION

If defined in the hash of the first element in the call to Examine
the following variables will be parsed from the key and returned in
the return hash.  All values are integers and will be returned in signed hex.
  'Keyversion'
  'Keymodulus'
  'KeypublicExponent'
  'KeyprivateExponent'
  'Keyprime1'
  'Keyprime2'
  'Keyexponent1'
  'Keyexponent2'
  'Keycoefficient'

=head2 EXPORT

None.

=head1 SEE ALSO

RFC2313

This module was originally designed for the SHEBANGS project at
The University of Manchester.

http://www.mc.manchester.ac.uk/projects/shebangs/
now http://www.rcs.manchester.ac.uk/research/shebangs/

Mailing list, shebangs@listserv.manchester.ac.uk

Mailing list, voms-lite@listserv.manchester.ac.uk

=head1 AUTHOR

Mike Jones <mike.jones@manchester.ac.uk>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Mike Jones

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut

