package VOMS::Lite::ASN1Helper;

use 5.004;
use strict;
use warnings;
use Math::BigInt lib => 'GMP';

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);
%EXPORT_TAGS = ( );
@EXPORT_OK = qw( Hex DecToHex ASN1BitStr ASN1Wrap ASN1UnwrapHex ASNLenStr ASN1Index ASN1Unwrap ASN1OIDtoOID OIDtoASN1OID);
@EXPORT = (  );
$VERSION = '0.20';

##################################################

sub Hex { #Converts a binary string to a padded string of hex values
  my $data=shift;
  return undef if ( ! defined $data );
  my $str=unpack('H*',$data);
  return ((length($str) & 1)?"0":"").$str;
}

##################################################

sub DecToHex { #Converts an 'integer' to a padded string of hex values
  my $data=shift;
  return undef if ( ! defined $data );
  return "NaN" if ( $data !~ /^-?[0-9]+$/ );
  my $num=Math::BigInt->new("$data");
  $num->binc() if ( $data =~ /^-/ );
  my $str=$num->as_hex();
  $str =~ s/^-?0x//;           # strip 0x and negative sign
  $str =~ s/^.(..)*$/0$&/;     # even up str
  $str =~ s/^[89a-f]/00$&/;    # convert to 2's complement as if positive
  $str =~ y/0-9a-f/fedcba9876543210/ if ( $data =~ /^-/ ); # if negative, negate
  return $str;
}

##################################################

sub ASN1OIDtoOID {
  my ($val,$OIDstr)=(0,"");
  foreach (split(//,shift)) {        # Tackle OID one byte at a time
    $val=($val*128)+ord($_&"\x7f");  # effectively shift $val 7 bits left add last 7 bits of $_
    if (($_&"\x80") ne "\x80") {     # If bit 8 is 0 then write append the value to the oid string
      $OIDstr .= ( ( length($OIDstr) ) ? ".$val" : (int($val/40).".".$val%40) ); 
      $val=0;
    } 
  }
  return $OIDstr;
}

sub OIDtoASN1OID {
  if ( $_[0] !~ /^[0-9]+(?:\.[0-9]+)*$/ ) { return undef; }
  my @nums=split /\./,$_[0];
  unshift(@nums,shift(@nums)*40+shift(@nums));
  my $OIDASN1str="";
  foreach (@nums) {
    my $str="";
    while ( $_ > 0 ) {
      my $m = $_ % 128;
      $_ -= $m;
      $m += 128 if ($str ne "");
      $str = pack('C',$m).$str;
      $_/=128;
    }
    $OIDASN1str .= $str;
  } 
  return $OIDASN1str;
}

##################################################

sub ASN1BitStr { #Converts a hex representation of a bit string to an ASN1 bitstring primitive
  my ($data,$length)=@_;
  return undef if ( ! defined $data );
  if ( defined $length ) {
    my $wholebytes = int($length/8);
    my $mask       = Hex(pack('C',(2**((8-$length)%8)-1))); 
    return $mask.substr($data,0,$wholebytes*2);
  }
  return "00".$data;
}

##################################################

sub ASN1Wrap { #wraps an ASN1 structure with its ASN1 headers
  my $Header=shift;
  my $Data=shift;
  return undef if (! defined $Header || ! defined $Data);
  return $Header.ASNLenStr($Data).$Data;
}

##################################################

sub ASN1UnwrapHex {
  my $data=shift;
  return undef if ( ! defined $data );
  $data=~ s/(..)/pack("C",hex($&))/ge;
  return Hex(scalar ASN1Unwrap($data));
}

sub ASN1Unwrap {
  my $BER=shift;
  return (wantarray ? (0,0,undef,undef,undef,"") : "") if (! defined $BER );
  my $inheader=1;
  my ($Class,$Constructed,$Tag)=(0,0,0);
  my ($headlen,$reallen,$lenlen)=(0,0,0);
#  my $i;
  for ( my $i = 0 ; $i <= length($BER) ; $i++ ) {
    my $C=substr $BER,$i,1;
    my @B=split(//, unpack("B*", $C));
    if ( $inheader==1 ) { # ID First Byte
      $headlen=1;
      $Class= (shift @B)*2 + shift @B;
      $Constructed=shift @B;
      $Tag=unpack("N", pack("B32",substr("0" x 32 . join("",@B), -32 )));
      if ($Tag==31) { $inheader=2; $Tag=0; }
      else { $inheader=3; }
    } elsif ( $inheader==2 ) { # ID Subsequent Bytes
      $headlen++;
      $inheader+=shift @B;
      $Tag <<= 7;
      $Tag=unpack("N", pack("B32",substr("0" x 32 . join("",@B), -32 )));
    } elsif ( $inheader==3 ) { # Length First Byte
      $headlen++;
      if ( shift @B ) { $inheader=4;  $reallen=0; $lenlen  = unpack("N", pack("B32",substr("0" x 32 . join("",@B), -32 )));}
      else {            $inheader=-1; $lenlen=0;  $reallen = unpack("N", pack("B32",substr("0" x 32 . join("",@B), -32 )));}
    } elsif ( $inheader==4 ) { # Length Subsequent Bytes
      $headlen++; $lenlen--;
      $reallen+=(unpack("N", pack("B32",substr("0" x 32 . join("",@B), -32 ))))*(256**$lenlen);
      if ( $lenlen == 0 ) { $inheader=-1;}
    } else { #What's left: Primative or Construction
      return wantarray ? ($headlen,$reallen,$Class,$Constructed,$Tag,substr($BER,$i,$reallen)) : substr($BER,$i,$reallen);
    }
  }
  return wantarray ? (0,0,undef,undef,undef,"") : "";
}

##################################################

sub ASNLenStr { #expects Hex String returns ASN1 length header
  my $data=shift;
  return undef if ( ! defined $data );

  my $len=length($data)/2;
  if ($len <= 127) {
    return unpack("H2",pack("i",$len));
  } else {
    my $lenlen=sprintf "%0x",$len;
    if ( length($lenlen) & 1 ) { $lenlen='0'.$lenlen; }
    return sprintf("%0x%s",((length($lenlen)/2)+128),$lenlen);
  }
}

##################################################
# Subroutine to find structure of DER ASN.1
##################################################

sub ASN1Index {
  my $data=shift;
  return () if ( ! defined $data );

  my @ContentStart=(0);
  my $datalength=length($data);
  my @ContentStop=($datalength);
  my $pointer=0;

  my @total=ASN1Unwrap(substr($data,$pointer,($ContentStop[-1]-$ContentStart[-1])));
  if ( $total[0]+$total[1] != $datalength ) { return (); }

  my @data;
  while ( defined $ContentStop[-1] && $pointer < $ContentStop[0] ) {

    my ($headlen,$reallen,$Class,$Constructed,$Tag,$Data) = ASN1Unwrap(substr($data,$pointer,($ContentStop[-1]-$ContentStart[-1])));

    if ( ! defined $Class ) { return (); }
    push @ContentStart,($pointer+$headlen);
    push @ContentStop,($pointer+$headlen+$reallen);

    push @data, [$Class,$Constructed,$Tag,$pointer,$headlen,$reallen];

    $pointer+=$headlen;
    $pointer+=$reallen if ($Constructed==0);
    while ( defined $ContentStop[-1] && $pointer == $ContentStop[-1] ) {
      if ( ! defined pop @ContentStop) { return (); }
      if ( ! defined pop @ContentStart) { return (); }
    }
  }
  return @data;
}

1;
__END__

=head1 VOMS::Lite::ASN1Helper

VOMS::Lite::ASN1Helper - Perl extension for basic ASN.1 encoding and decoding.
There is no OO in this module, it's a very basic straightforward implementation of ASN.1.

=head1 SYNOPSIS

  use VOMS::Lite::ASN1Helper qw( Hex DecToHex ASN1BitStr ASN1Wrap ASN1UnwrapHex ASNLenStr ASN1Index ASN1Unwrap ASN1OIDtoOID);

  # To convert a binary string, $data, to padded hex i.e. ([0-9a-f]{2})*
  my $hexstr=Hex($data);

  # To convert an integer to a padded string of hex values
  my $hexint=DecToHex($int);

  # To convert ASN1 represeantation of an OID to a dot representation e.g. 1.2.840.113549.1.9.1
  my $OIDstr=ASN1OIDtoOID($data);

  # To convert a dot representation of an OID (e.g. 1.2.840.113549.1.9.1) to an ASN1 represeantation 
  my $ASN1str=OIDtoASN1OID($oid);

  # To convert a hex representation of a N*8 bit bytestring into an ASN1 bitstring
  my $hexbitstr=ASN1BitStr($hexstr);
  my $hexbitstr=ASN1BitStr($hexstr,$lengthinbits);

  # To wrap a hex string into an ASN.1 Primative
  my $objectstr=30; #30 denotes a SEQUENCE
  my $asn1prim=ASN1Wrap($hexstr);

  # To unwrap a chunk of BER encoded ASN.1
  my $contents=ASN1Unwrap($data);
  my $contentshex=ASN1UnwrapHex($data);
  # or
  my ($headerLength,$dataLength,$class,$constructed,$tag,$contents)=ASN1Unwrap($data);

  # To return the ASN.1 length header for a hex representation of some data
  my $LenghtHeaderHex=ASNLenStr($hexstr);

  # To index an ASN.1 string
  foreach ASN1Index($data) {
    my ($class,$constructed,$tag,$position,$headLength,$dataLength)=@$_;
    ...
  }

=head1 DESCRIPTION

VOMS::Lite::ASN1Helper is designed to provide simple ASN.1 encoding decoding methods for VOMS::Lite.

=head2 EXPORT

None by default.

By EXPORT_OK the following functions:
 Hex
 DecToHex
 ASN1BitStr
 ASN1Wrap
 ASN1UnwrapHex
 ASNLenStr
 ASN1Index
 ASN1Unwrap
 ASN1OIDtoOID
 OIDtoASN1OID

=head1 SEE ALSO

The X.680 and X.690 specifications:
http://www.itu.int/ITU-T/studygroups/com17/languages/

This module was originally designed for the SHEBANGS project at The University of Manchester.
http://www.mc.manchester.ac.uk/projects/shebangs/
now http://www.rcs.manchester.ac.uk/research/shebangs/

Mailing list, shebangs@listserv.manchester.ac.uk
Mailing list, voms-lite@listserv.manchester.ac.uk

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Mike Jones <mike.jones@manchester.ac.uk>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Mike Jones

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
