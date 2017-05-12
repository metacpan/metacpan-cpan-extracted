# -*- mode: perl; coding: utf-8-unix; -*-
#
# Author:      Peter John Acklam
# Time-stamp:  2013-03-01 13:37:53 +00:00
# E-mail:      pjacklam@online.no
# URL:         http://home.online.no/~pjacklam

package TestUtil;

# The 'utf8' and 'warnings' pragmas only require Perl 5.006, but the support
# for UTF-8 is rotten in Perl < 5.008, so require 5.008.

use 5.008;              # for UTF-8 support
use strict;             # restrict unsafe constructs
use warnings;           # control optional warnings

#use utf8;               # enable/disable UTF-8 (or UTF-EBCDIC) in source code

#use Carp;
use Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(nice_string);
our @EXPORT_OK = qw();

#########################

# The following function only seems to work with Perl >= 5.8. Neither
# "unpack 'U*', $x" nor "split //, $x" can be used to split a string into
# characters with Perl 5.6. However, "substr($offset, 1, $x)" seems to work
# fine also with Perl 5.6.

sub nice_string {
    join "",
      map { $_ > 255 ?                  # if wide character...
            sprintf("\\x{%04X}", $_) :  # \x{...}
            chr($_) =~ /[^[:print:]]/ ? # else if non-printable ...
            sprintf("\\x%02X", $_) :    # \x..
            chr($_)                     # else as is
          }
        unpack 'U*', $_[0];             # unpack Unicode characters
}

# This function works with Perl >= 5.6.
#
# sub nice_string {
#     my $str_in  = $_[0];
#     my $str_out = '';
#
#     my $max_offset  = length($str_in) - 1;
#
#     for my $offset (0 .. $max_offset) {
#         my $chr = substr($str_in, $offset, 1);
#         my $ord = ord($chr);
#         $str_out .= $ord > 255 ?                  # if wide character...
#                     sprintf("\\x{%04X}", $ord) :  # \x{...}
#                     $chr =~ /[^[:print:]]/ ?      # else if non-printable ...
#                     sprintf("\\x%02X", $ord) :    # \x..
#                     $chr                          # else as is
#     }
#
#     return $str_out;
# }

#########################

1;
