package Text::JaroWinkler;

use 5.006;
use warnings;
use strict;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	    strcmp95
	    do_strcmp95
                                  ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.1';

bootstrap Text::JaroWinkler $VERSION;

# Preloaded methods go here.

sub strcmp95 {
    my($ying, $yang, $y_length, %opt) = @_;
    $ying = sprintf("%*.*s", -$y_length, $y_length, $ying);
    $yang = sprintf("%*.*s", -$y_length, $y_length, $yang);

    my $high_prob = $opt{HIGH_PROB} || 0;
    my $toupper   = $opt{TOUPPER} || 0;
    do_strcmp95($ying, $yang, $y_length, $high_prob, $toupper);
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Text::JaroWinkler - An implementation of the Jaro-Winkler distance

=head1 SYNOPSIS

  use Text::JaroWinkler qw( strcmp95 );

  print strcmp95("it is a dog","i am a dog.",11);
  # print "0.865619834710744"

=head1 DESCRIPTION

This module implements the Jaro-Winkler distance. The Jaro-Winkler distance
is a measure of similarity between two strings. It is a variant of the Jaro
distance metric and mainly used in the area of record linkage (duplicate
detection). The higher the Jaro-Winkler distance for two strings is,
the more similar the strings are. The Jaro-Winkler distance metric is designed
and best suited for short strings such as person names. The score is normalized
such that 0 equates to no similarity and 1 is an exact match.
More information can be found on <http://en.wikipedia.org/wiki/Jaro-Winkler>

It is an XS wrapper of the original C implementation by the author of the
algorithm: <http://www.census.gov/geo/msb/stand/strcmp.c>, with some minor
modification to accept variance length input.

=head2 EXPORT

None by default.

=head1 AUTHOR

Shu-Chun Weng E<lt>scw@csie.orgE<gt>

=head1 SEE ALSO

L<perl>, L<Text::Levenshtein>, L<Text::LevenshteinXS>, L<Text::WagnerFischer>

=cut
