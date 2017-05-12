=head1 NAME

Text::Same::Util

=head1 DESCRIPTION

Utility methods for Text::Same

=head1 METHODS

See below.  Methods private to this module are prefixed by an
underscore.

=cut

package Text::Same::Util;

use warnings;
use strict;
use Carp;

use vars qw($VERSION @ISA @EXPORT);
use Exporter;

@ISA = qw( Exporter );
@EXPORT = qw( hash is_ignorable );

$VERSION = '0.07';

use Digest::MD5 qw(md5);

=head2 hash

 Title   : hash
 Usage   : my $hash_value = hash($options, $text)
 Function: return an integer hash/checksum for the given text

=cut

sub hash
{
  my $options = shift;
  my $text = shift;

  if ($options->{ignore_case}) {
    $text = lc $text;
  }
  if ($options->{ignore_space}) {
    $text =~ s/^\s+//;
    $text =~ s/\s+/ /g;
    $text =~ s/\s+$//;
  }
  return md5($text);
}

sub _is_simple
{
  my ($options, $text) = @_;
  if ($options->{ignore_simple}) {
    my $simple_len = $options->{ignore_simple};
    $text =~ s/\s+//g;
    if (length $text <= $simple_len) {
      return 1;
    }
  }
  return 0;
}

=head2 is_ignorable

 Title   : is_ignorable
 Usage   : if (is_ignorable($options, $text)) { ... }
 Function: return true if and only if for the given options, the given text
           should be ignored during comparisons 

=cut

sub is_ignorable
{
  my ($options, $text) = @_;
  return 1 if !defined $text;
  return (($options->{ignore_blanks} && $text =~ m/^\s*$/) ||
          _is_simple($options, $text));
}

=head1 AUTHOR

Kim Rutherford <kmr+same@xenu.org.uk>

=head1 COPYRIGHT & LICENSE

Copyright 2005,2006 Kim Rutherford.  All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER

This module is provided "as is" without warranty of any kind. It
may redistributed under the same conditions as Perl itself.

=cut

1;
