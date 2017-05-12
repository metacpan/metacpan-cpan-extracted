#                              -*- Mode: Perl -*- 
# Util.pm -- 
# Author          : Ulrich Pfeifer
# Created On      : Thu Feb  1 16:08:41 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Sun Apr  3 11:44:12 2005
# Language        : Perl
# Update Count    : 8
# Status          : Unknown, Use with caution!

package Text::German::Util;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(bit_to_int wordclass $CAPITAL $LOWER $ADJEKTIV $UMLAUTR 
	     $VERB $FUNNY $ADJEKTIV $ANY);

sub bit_to_int {
    my $bitvec = shift;

    unpack('I', pack('b*', $bitvec)."\0\0\0\0");
}

$CAPITAL  = bit_to_int('10000');
$LOWER    = bit_to_int('01111');
$ADJEKTIV = bit_to_int('00100');
$VERB     = bit_to_int('01000');
$FUNNY    = bit_to_int('01001');
$ANY      = bit_to_int('11111');
$UMLAUTR  = "[äöü]";

sub wordclass {
  my ($word, $satz_anfang) = @_;
  
  if ($satz_anfang) {
    return $ANY;
  } elsif ($word =~ /^[A-ZÄÖÜ]/) {
    $CAPITAL;
  } else {
    $LOWER;
  }
}
