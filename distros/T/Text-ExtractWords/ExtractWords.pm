#
# ExtractWords.pm
# Last Modification: Mon Oct 13 14:12:51 WEST 2003
#
# Copyright (c) 2003 Henrique Dias <hdias@aesbuc.pt>. All rights reserved.
# This module is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
package Text::ExtractWords;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(&words_count &words_list);
$VERSION = '0.08';

bootstrap Text::ExtractWords $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Text::ExtractWords - Perl extension for extract words from strings

=head1 SYNOPSIS

  use Text::ExtractWords qw(words_count words_list);

  my %hash = ();
  my %config = (
    minwordlen => 2,
    maxwordlen => 32,
    locale     => "pt_PT.ISO_8859-1",
  );
  words_count(\%hash, "test the words_count function", \%config);

  my @list = ();
  words_list(\@list, "test the words_list function", \%config);

=head1 DESCRIPTION

The aim of this module is to extract the words from the texts or mails to
identify spam. But it can be used for another purpose.

=head1 METHODS

=head2 words_count(HASHREF, STRING, HASHREF)

Extract words from a string to hash reference and count the number of
occurrences for each word.

=head2 words_list(ARRAYREF, STRING, HASHREF)

Extract words from a string to array reference.

=head1 AUTHOR

Henrique Dias <hdias@aesbuc.pt>

=head1 SEE ALSO

perl(1).

=cut
