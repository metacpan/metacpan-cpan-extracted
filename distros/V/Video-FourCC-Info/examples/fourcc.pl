#!/usr/bin/perl

# examples/fourcc.pl
#  Determine information about a given codec
#
# $Id: fourcc.pl 9530 2009-10-04 04:37:16Z FREQUENCY@cpan.org $

use strict;
use warnings;

use Pod::Usage;

use Video::FourCC::Info;

=head1 NAME

fourcc.pl - determine a codec referred to by a given FourCC

=head1 SYNOPSIS

Usage: fourcc.pl code [...]

Given a list of Four Character codes as arguments, this script will look up
each code and print some information about each codec. There must be at least
one given code, and there is no upper bound on the number of codes you can
search.

Remember that these codes are byte-indexed, not character-indexed. Therefore,
the input is case-sensitive and should be extracted directly from files.

=cut

my @codecs = @ARGV;

# if no parameters are passed, give usage information
unless (@codecs) {
  pod2usage(msg => 'Please supply at least one codec argument');
}

foreach my $code (@codecs) {
  my $codec;
  eval {
    $codec = Video::FourCC::Info->new($code);
  };

  printf "Codec - FourCC: %s\n", $code;
  if ($@) {
    printf STDERR "  Could not find codec '%s' in database.\n", $code;
    next;
  }

  # Check if we have description entity information
  if (defined $codec->description) {
    printf "  Description:   %s\n", $codec->description;
  }

  # Check if we have owner entity information
  if (defined $codec->owner) {
    printf "  Registered by: %s\n", $codec->owner;
  }

  # Check if we have registration date information
  if (defined $codec->registered) {
    print '  Registered on: ';
    if (ref($codec->registered)) {
      print $codec->registered->ymd('-');
    }
    else {
      print $codec->registered;
    }
    print "\n";
  }
}

=head1 AUTHOR

Jonathan Yu E<lt>jawnsy@cpan.orgE<gt>

=head1 LICENSE

This has the same copyright and licensing terms as L<Video::FourCC::Info>.

=head1 SEE ALSO

L<Video::Info>,
L<Video::FourCC::Info>

=cut
