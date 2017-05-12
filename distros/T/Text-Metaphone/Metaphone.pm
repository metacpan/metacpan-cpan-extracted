package Text::Metaphone;

use strict;
use warnings;

require Exporter;
require DynaLoader;

use integer;

our @ISA = qw(Exporter DynaLoader);

our @EXPORT = qw(
    Metaphone
);

our $VERSION = '20160805';

bootstrap Text::Metaphone $VERSION;

1;

__END__
=pod

=head1 NAME

Text::Metaphone - A modern soundex.  Phonetic encoding of words.

=head1 SYNOPSIS

  use Text::Metaphone;

  # XWRN
  my $phoned_word = Metaphone('Schwern');


=head1 DESCRIPTION

C<Metaphone()> is a function whereby a string/word is broken down into
a rough approximation of its english phonetic pronunciation.  Very
similar in concept and purpose to soundex, but much more
comprehensive in its approach.


=head1 FUNCTIONS

=head3 Metaphone

    $phoned_word = Metaphone($word, $max_phone_len);

Takes a word and encodes it according to the Metaphone algorithm.
The algorithm only deals with alphabetical characters, all else is ignored.

If $max_phone_len is provided, Metaphone will only encode up to that many
characters for each word.

'sh' is encoded as 'X', 'th' is encoded as '0'.  This can be changed
in the metaphone.h header file.


=head1 CAVEATS

=head3 Metaphone algorithm changes

I have made a few minor changes to the traditional metaphone algorithm found
in the books.  The most significant one is that it will differenciate between
SCH and SCHW making the former K (As in School) and the latter sh (as in
Schwartz and Schwern).

My changes can be turned off by defining the USE_TRADITIONAL_METAPHONE
flag in metaphone.h.

Due to these changes, any users of Metaphone v1.00 or earlier which have stored
metaphonetic encodings, they should recalculate those with the new version.


=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>

=head1 SEE ALSO

=head2 Man pages

L<Text::Soundex> - A simpler word hashing algorithm
L<Text::DoubleMetaphone> - Improved metaphone
L<Text::Phonetic> - A collection of phonetic algorithms

=head2 Books, Journals and Magazines

=head3 Binstock, Andrew & Rex, John. "Metaphone:  A Modern Soundex." I<Practical Algorithms For Programmers.>  Reading, Mass:  Addion-Wesley, 1995  pp160-169 

Contains an explanation of the basic metaphone concept & algorithm and C code
from which I learned of Metaphone and ported this module.

=head3 Parker, Gary. "A Better Phonetic Search." I<C Gazette>, Vol. 5, No. 4 (June/July), 1990.

This is the public-domain C version of metaphone from which Binstock & Rex 
based their own..  I haven't actually read it.

=head3 Philips, Lawrence. I<Computer Language>, Vol. 7, No. 12 (December), 1990.  

And here's the original Metaphone algorithm as presented in Pick BASIC.


=head1 COPYRIGHT and LICENSE

Copyright (c) 1997, 1999, 2007-2008 Michael G Schwern.  All Rights Reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

