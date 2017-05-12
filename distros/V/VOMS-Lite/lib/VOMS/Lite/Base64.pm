package VOMS::Lite::Base64;

require Exporter;
use vars qw($VERSION $DEBUG @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);
$VERSION = '0.20';

my %Alphabets = ( VOMS => "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789[]",
                  RFC3548 => "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=",
                  RFC3548URL => "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-="
                );

sub Encode{
  my $data = shift;
  my $str = shift;  # Can supply custom Base64
  my $pad="";
  if ( defined $str ) {
    $str = $Alphabets{$str} if ($Alphabets{$str});
    if ( $str =~ /^(.{64})(.?)$/s ) { $str=$1; $pad="$2"; }
    else { return undef; }
  }
  else { $str = $Alphabets{RFC3548}; }
  $data=~s|(.)(.?)(.?)| substr($str,((ord($1)&252)>>2),1).
                        substr($str,((ord($1)&3)<<4)+((ord($2)&240)>>4),1).
                        ((length($2))?substr($str,((ord($2)&15)<<2)+((ord($3)&192)>>6),1):$pad).
                        ((length($3))?substr($str,(ord($3)&63),1):$pad)|gse;
  return $data;
}

sub Decode {
  my $data = shift;
  my $str = shift;  # Can supply custom Base64
  my $pad="=";

  my $type;
  if ( defined $str && ! defined $Alphabets{$str} )  { $type = 'USER'; }
  elsif ( defined $str && defined $Alphabets{$str} ) { $type = $str; } 
#Try to guess
  elsif ( $data =~ /[\[\]]/s && $data !~ /[+\/_-]/ ) { $type = 'VOMS'; }  
  elsif ( $data =~ /[_-]/s && $data !~ /[\[\]+\/]/)  { $type = 'RFC3548URL'; }
  else                                               { $type = 'RFC3548'; } # Assume Standard Base64 if 
  if ( $type eq "USER" )                             { $Alphabets{'USER'} = $str; }

  #strip non-base64 chars
  my $estr;
  if ( $Alphabets{$type} =~ /^(.{64})(.?)$/s ) { $str=$1; $estr=quotemeta($1); $pad=$2; } else { return undef; }
  $data =~ s/[^$estr]//gs;

# Force Padding
  $data .= $pad x (3-(((length($data)+3) % 4)));
  $data=~s|(.)(.)(.?)(.?)|
              chr(((index($str,$1)<<2)&252)+((index($str,$2)>>4)&3)).                      #six bits from first with two bits from the second
              (($3 ne $pad)?chr(((index($str,$2)<<4)&240)+((index($str,$3)>>2)&15)):"").   #last 4 bits from second with four bits from third unless third is pad
              (($4 ne $pad)?chr(((index($str,$3)<<6)&192)+((index($str,$4))&63)):"")       #last 2 bits from third with six bits from the forth unless forth is pad
              |ge;
  return $data;
}

1;

__END__

=head1 NAME

VOMS::Lite::VOMS - Perl extension for gLite VOMS server interaction

=head1 SYNOPSIS

  use VOMS::Lite::Base64;

  $Base64Data = VOMS::Lite::Base64::Encode( $Data, $Encoding );
  $Data = VOMS::Lite::Base64::Decode( $Base64Data, $Encoding );

=head1 DESCRIPTION

  $Encoding can be VOMS, RFC3548 or RFC3548URL.

  By default RFC3548 is used.

=head2 EXPORT

None.

=head1 Also See

https://twiki.cnaf.infn.it/cgi-bin/twiki/view/VOMS/VOMSProtocol
http://glite.cvs.cern.ch/cgi-bin/glite.cgi/org.glite.security.voms

RFC3548 for Base64 encoding

This module was originally designed for the JISC funded SARoNGS project at developed at 
The University of Manchester.
http://www.rcs.manchester.ac.uk/projects/sarongs/

=head1 AUTHOR

Mike Jones <mike.jones@manchester.ac.uk>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Mike Jones

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
