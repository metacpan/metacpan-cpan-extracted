package Unicode::CheckUTF8::PP;
$Unicode::CheckUTF8::PP::VERSION = '0.003';
use base qw(Exporter);
# ABSTRACT: Pure Perl implementation of Unicode::CheckUTF8

use strict;
use warnings;

our @EXPORT    = qw();
our @EXPORT_OK = qw(is_utf8);

my @validSingleByte = (
    0,0,0,0,0,0,0,0,0,1,1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0
);
 
my @trailingBytesForUTF8 = (
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,4,4,4,4,5,5,5,5
);

my $_isLegalUTF8 = sub {
    my ($bytes, $length) = @_;

    my $i = $length;
    if ( $length <= 4 ) {
       my $c;
       if ( $length == 4 ) {
          $c = $bytes->[--$i];
          return 0 unless defined $c;
          return 0 if $c < 0x80 || $c > 0xBF;
       }
      
       if ( $length >= 3 ) {
          $c = $bytes->[--$i];    
          return 0 unless defined $c;
          return 0 if $c < 0x80 || $c > 0xBF;
       }
       
       if ( $length >= 2 ) {
          $c = $bytes->[--$i];    
          return 0 unless defined $c;
          return 0 if $c > 0xBF;
          
          if    ( $bytes->[$i] == 0xE0 ) { return 0 if $c < 0xA0; }
          elsif ( $bytes->[$i] == 0xF0 ) { return 0 if $c < 0x90; }
          elsif ( $bytes->[$i] == 0xF0 ) { return 0 if $c > 0x8F; }
          else                           { return 0 if $c < 0x80; }
      }
       
       if ( $length >= 1 ) {
          return $validSingleByte[ $bytes->[0] ];
       }
    }
    else {
       return 0;
    }

    return 1;
};

my $_isLegalUTF8String = sub {
    my ($str) = @_;

    my @bytes = unpack 'U*', $str;
    my $len = @bytes;
    my $l = 0;
    
    my $i = 0;
    while ( $i < $len ) {
       my $byte = $bytes[$i];
       my $length = $trailingBytesForUTF8[$byte] + 1;
       
       # check for early termination of string
       foreach my $j ( 1 .. $length - 1 ) {
          return 0 unless defined $bytes[$j];
          return 0 if $bytes[$j] == 0;
       }
       
       return 0 unless
          $_isLegalUTF8->([@bytes[$i..$i+$length-1]], $length);
       
       $l = $bytes[$i];
       $i += $length;
    }

    return ($l || 0) == ($bytes[-1] || 0) ? 1 : 0;
};

sub is_utf8 {
    return $_isLegalUTF8String->(@_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Unicode::CheckUTF8::PP - Pure Perl implementation of Unicode::CheckUTF8

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 use Unicode::CheckUTF8::PP qw(is_utf8);
 my $is_ok = is_utf8($scalar);

=head1 DESCRIPTION 

Pure Perl implementation of L<Unicode::CheckUTF8>, almost all logic was directly ported from that module. The target audience of this module are users who would like the functionality of Unicode::CheckUTF8, but don't have access to a C compiler or lack permissions to compile on their systems (for whatever reason)

=head1 METHODS

=over 4

=item C<is_utf8>

Determines whether a Perl scalar is a UTF8 compliant string

 returns 1 if the supplied string is UTF8 compliant 
 returns 0 otherwise

=back

=head1 AUTHOR 

Based entirely on L<Unicode::CheckUTF8>, written by Brad Fitzpatrick

=head1 AUTHOR

Hunter McMillen <mcmillhj@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Hunter McMillen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
