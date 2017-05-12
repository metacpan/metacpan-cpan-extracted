package Text::Shellwords;

# simple wrapper around perl4-based shellwords.pl

use strict;
require Exporter;

use Text::ParseWords();


use vars qw(@ISA @EXPORT $VERSION);
@ISA = 'Exporter';
$VERSION = '1.08';

@EXPORT = qw(shellwords);

sub shellwords {
  my @args = @_;
  return unless @args;
  foreach(@args) {
    $_ = '' unless defined $_;
    s/^\s+//;
    s/\s+$//;
  }
  Text::ParseWords::shellwords(@args);
}

1;

__END__

=head1 NAME

Text::Shellwords

=head1 SYNOPSIS

  use Text::Shellwords;
  @words = shellwords($line);
  @words = shellwords(@lines);

=head1 DESCRIPTION

This used to be a wrapper around shellwords.pl, but has now been
superseded by Text::ParseWords.  Use that module insteade.  If you
use this module, it will simply report the shellwords() function from
Text::ParseWords.

The old description follows:

This is a thin wrapper around the shellwords.pl package, which comes
preinstalled with Perl.  This module imports a single subroutine,
shellwords().  The shellwords() routine parses lines of text and
returns a set of tokens using the same rules that the Unix shell does
for its command-line arguments.  Tokens are separated by whitespace,
and can be delimited by single or double quotes.  The module also
respects backslash escapes.

If called with one or more arguments, shellwords() will treat each
argument as a line of text, parse it, and return the tokens.

Note that the old behavior of parsing $_ if no arguments are provided
is no longer supported. Sorry.

=head1 BUGS

Please report them.

=head1 SEE ALSO

L<shellwords.pl>

=head1 AUTHOR

Lincoln Stein <lstein@cshl.org>.

Copyright (c) 2001 Cold Spring Harbor Laboratory

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut
