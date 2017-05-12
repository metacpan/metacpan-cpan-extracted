package VOMS::Lite::RSAHelper;

use 5.004;
use strict;
use Math::BigInt lib => 'GMP';

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);
%EXPORT_TAGS = ( );
@EXPORT_OK = qw( rsasign rsaencrypt rsaverify rsadecrypt );
@EXPORT = ( );
$VERSION = '0.20';

###############################################

sub rsasign { # use private key to encrypt
  return &rsaenc( "01", @_);
}

###############################################

sub rsaencrypt { # use public key to encrypt
  return &rsaenc( "02", @_);
}

###############################################

sub rsaverify {
  return rsadecrypt( @_ );
}

###############################################

sub rsadecrypt {
  my ($EDhex,$chex,$nhex)=@_;

# Even up hex lengths into whole octets
  $chex=~s/^.(..)*$/0$&/;
  $nhex=~s/^.(..)*$/0$&/;
  $EDhex=~s/^.(..)*$/0$&/;
  my $khex=length($nhex);

# Length of modulus and Data in octets
  my $k=$khex/2;
  my $EDlen=length($EDhex)/2;

# Create Integer representing Data
  my $x=Math::BigInt->bzero();
  foreach (split(//,$EDhex)) {
    $x->bmul(16);
    $x->badd(hex($_));
  }

# Create Integer representing Modulus
  my $n=Math::BigInt->bzero();
  foreach (split(//,$nhex)) {
    $n->bmul(16);
    $n->badd(hex($_));
  }

# Create Integer representing Exponent
  my $c=Math::BigInt->bzero();
  foreach (split(//,$chex)) {
    $c->bmul(16);
    $c->badd(hex($_));
  }

# Do Big RSA Maths y = x^c mod n
  my $y=Math::BigInt->bzero();
  $y = $x->bmodpow($c,$n);

# Get Encrypted Data Character String
  my $Dhex=$y->as_hex();
  $Dhex=~s/^0x//;
  $Dhex=~s/^.(..)*$/0$&/; # Even up the length

  if ( length($Dhex) < ($khex-4) ) { # short string: BT must be 00 (NB RFC difference should be ($khex-2) )
    return $Dhex;
  } 
  else { # long string: BT is any one of 00, 01 and 02
    my $BT=substr($Dhex,0,2);
    $Dhex=substr($Dhex,2);
    if ( $BT eq "00" ) {
      until ( substr($Dhex,0,2) ne '00' || $Dhex eq "" ) { $Dhex=substr($Dhex,2); } 
    }
    else { # BT = 01 or 02
      until ( substr($Dhex,0,2) eq '00' || $Dhex eq "" ) { $Dhex=substr($Dhex,2); }
      $Dhex=substr($Dhex,2);
    }
  }
  return $Dhex;
}

###############################################

sub rsaenc { #RSA Algorythm as per RFC2313  (with tweak for openssl verification stuff)

# Get block type, Data, HexKey, HexModulus
  my ($BT,$Dhex,$chex,$nhex)=@_;

# Even up hex lengths into whole octets
  $chex=~s/^.(..)*$/0$&/;
  $nhex=~s/^.(..)*$/0$&/;
  $Dhex=~s/^.(..)*$/0$&/;
  my $khex=length($nhex);

# Length of modulus and Data in octets
  my $k=$khex/2;
  my $Dlen=length($Dhex)/2;

# Barf if datalen is too long for RSA
  ( $Dlen > ($k - 11) ) && die "Too much data to encrypt!";

# Padding for signing (why - 4 and not - 3 as per RFC I don't know)
  my $PS="ff" x ( $k - 4 - $Dlen);

# If encrypting alter padding to random
  if ( $BT eq "02" ) { $PS=~s/../unpack('H2',pack('i',int(rand(255)+1)))/ge; }

# Make Encryption Block. EB = 00 || BT || PS || 00 || D
  my $EB='00'.$BT.$PS.'00'.$Dhex;

# Create Integer representing Data
  my $x=Math::BigInt->bzero();
  foreach (split(//,$EB)) {
    $x->bmul(16);
    $x->badd(hex($_));
  }

# Create Integer representing Modulus
  my $n=Math::BigInt->bzero();
  foreach (split(//,$nhex)) {
    $n->bmul(16);
    $n->badd(hex($_));
  }

# Create Integer representing Exponent
  my $c=Math::BigInt->bzero();
  foreach (split(//,$chex)) {
    $c->bmul(16);
    $c->badd(hex($_));
  }

# Do Big RSA Maths y = x^c mod n
  my $y=Math::BigInt->bzero();
  $y = $x->bmodpow($c,$n);

# Get Encrypted Data Character String
  my $ED=$y->as_hex();
  $ED=~s/^0x//;
  $ED=~s/^.(..)*$/0$&/;
  
# Send Hex Data back
  return $ED;
}

1;
__END__

=head1 NAME

VOMS::Lite::RSAHelper - Perl extension implementing basic RSA encryption/decryption

=head1 SYNOPSIS

  use VOMS::Lite::RSAHelper qw( rsasign rsaencrypt );
  $HexEData=rsasign($HexData,$HexKey,$HexModulus);
  $HexEData=rsaencrypt($HexData,$HexKey,$HexModulus);

=head1 DESCRIPTION

VOMS::Lite::RSAHelper is primarily for internal use.  But frankly I don't mind if you use this package directly :-)
It takes hex encoded data string and applies RSA encryption to it using the supplied key.


=head2 EXPORT

None by default.

rsasign rsaencrypt if specified.

=head1 SEE ALSO

RFC2313 for RSA encryption/decryption

This module was originally designed for the SHEBANGS project at The University of Manchester.
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
