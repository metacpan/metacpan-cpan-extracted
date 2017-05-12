#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2008-2011 -- leonerd@leonerd.org.uk

package Test::HexString;

our $VERSION = '0.03';

use strict;
use warnings;
use base qw( Test::Builder::Module );

our $CLASS = __PACKAGE__;

our @EXPORT = qw(
  is_hexstr
);

our $BYTES_PER_BLOCK = 16;

=head1 NAME

C<Test::HexString> - test binary strings with hex dump diagnostics

=head1 SYNOPSIS

 use Test::More tests => 1;
 use Test::HexString;

 my $data = generate_some_output;

 is_hexstr( $data, "\x01\x02\x03\x04", 'Generated output' );

=head1 DESCRIPTION

This testing module provides a single function, C<is_hexstr()>, which asserts
that the given string matches what was expected. When the strings match (i.e.
compare equal using the C<eq> operator), the behaviour is identical to the
usual C<is()> function provided by C<Test::More>.

When the strings are different, a hex dump is produced as diagnostic, rather
than the string values being printed raw. This may be beneficial if the string
contains largely binary data, such as may be produced by binary file or
network protocol modules.

To print the hex dump when it fails, each string is broken into 16 byte
chunks. The first pair of chunks that fail to match are then printed, in both
hexadecimal and character form, in a message in the following format:

 #   Failed test at -e line 1.
 #   at bytes 0-0xf (0-15)
 #   got: | 61 20 6c 6f 6e 67 20 73 74 72 69 6e 67 20 68 65 |a long string he|
 #   exp: | 61 20 6c 6f 6e 67 20 53 74 72 69 6e 67 20 68 65 |a long String he|
 # Looks like you failed 1 test of 1.

Only bytes in the range C<0x20-0x7e> are printed as literal characters. Any
other byte is rendered as C<.>:

 #   Failed test at -e line 1.
 #   at bytes 0-0xf (0-15)
 #   got: | 00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f |................|
 #   exp: | 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f 10 |................|
 # Looks like you failed 1 test of 1.

Only the first differing line is printed; because otherwise it may result in a
long output because of misaligned bytes.

If STDOUT is a terminal, then different bytes are printed in bold for
visibility.

=cut

sub _bold
{
   my ( $str, $bold ) = @_;
   return $str unless -t STDOUT;
   return $bold ? "\e[1m$str\e[m" : $str;
}

sub _hexline
{
   my ( $bytes, $boldmap ) = @_;

   my @b = split( m//, $bytes );

   my $ret = "| ";
   $ret .= _bold(sprintf( "%02x ", ord $b[$_] ), $boldmap->[$_] ) for 0 .. $#b;
   $ret .= ".. " x ( $BYTES_PER_BLOCK - @b );
   $ret .= "|";
   $ret .= _bold($b[$_] =~ /[\x20-\x7e]/ ? $b[$_] : ".", $boldmap->[$_] ) for 0 .. $#b;
   $ret .= " " x ( $BYTES_PER_BLOCK - @b );
   $ret .= "|";

   return $ret;
}

=head1 FUNCTIONS

=cut

=head2 is_hexstr( $got, $expect, $name )

Test that the string $got is what was expected by $expect. If the strings are
not equal, a hex dump is printed showing the region where they first start to
differ.

=cut

sub is_hexstr($$;$)
{
   my ( $got, $expected, $name ) = @_;

   my $tb = $CLASS->builder;

   if( ref $got ) {
      my $ok = $tb->ok( 0, $name );
      $tb->diag( "  expected a plain string, was given a reference to " . ref($got) );
      return $ok;
   }

   my $ok = $tb->ok( $got eq $expected, $name );

   unless( $ok ) {
      # Try to find where they differ
      for( my $offs = 0; $offs < length $got; $offs += $BYTES_PER_BLOCK ) {
         my $g = substr( $got,      $offs, $BYTES_PER_BLOCK );
         my $e = substr( $expected, $offs, $BYTES_PER_BLOCK );
         next if $g eq $e;

         my @bold = map { $_ < length $g and $_ < length $e and substr( $g, $_, 1 ) ne substr( $e, $_, 1 ) }
                    ( 0 .. $BYTES_PER_BLOCK-1 );

         $tb->diag( sprintf( "  at bytes %#x-%#x (%d-%d)\n",
            $offs, $offs+$BYTES_PER_BLOCK-1, $offs, $offs+$BYTES_PER_BLOCK-1 ) .
            "  got: " . _hexline( $g, \@bold ) . "\n" . 
            "  exp: " . _hexline( $e, \@bold )
         );

         last;
      }
   }

   return $ok;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
