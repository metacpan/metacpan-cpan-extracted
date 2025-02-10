package Text::Transliterator;
use strict;
use warnings;

our $VERSION = '1.05';

sub new {
  my $class = shift;
  my ($from, $to);

  # first arguments : either a hashref, or a pair of strings
  if ((ref $_[0] || '') eq 'HASH') {
    my $map = shift;
    $from = join "", keys   %$map;
    $to   = join "", values %$map;
  }
  else {
    $from = shift;
    $to   = shift;
    defined $from and defined $to
      or die 'Text::Transliterator->new($from, $to): invalid args';
  }

  # remaining arguments
  my $modifiers = shift || '';
  not @_
    or die 'Text::Transliterator->new(): too many args';

  # build the coderef.
  # Returns the list of tr/../../ results.
  # In scalar context, returns the last item (for compatibility with the previous API)
  my $src = "sub {my \@l = map {tr[$from][$to]$modifiers} \@_; return wantarray ? \@l : \$l[-1]}";
  local $@;
  my $coderef = eval $src or die "Text::Transliterator: error in compiling the tr function: $@";

  return $coderef;
}


1; # End of Text::Transliterator

__END__


=head1 NAME

Text::Transliterator - Wrapper around Perl tr/../../ operator

=head1 SYNOPSIS

  my $tr = Text::Transliterator->new($from, $to, $modifiers);
  # or
  my $tr = Text::Transliterator->new(\%map, $modifiers);

  $tr->(@strings);

=head1 DESCRIPTION

This package is a simple wrapper around Perl's transliteration operator
C<tr/../../..>. Starting either from two strings of characters, or from a
map of characters, it will compile a function that
applies the transliteration to any list of strings.

This does very little work, and therefore would barely merit a module
on its own; it was written mainly for serving as a base package for
L<Text::Transliterator::Unaccent|Text::Transliterator::Unaccent>.
However, in some situations it may be useful in its own right, since
Perl has no construct similar to C<qr/.../> for "compiling" a
transliteration. As a matter of fact, the C<tr/../../> documentation
says "if you want to use variables, you must use an eval()" ... which
is what the present module does, albeit in a somewhat more controlled
way.

=head1 METHODS

=head2 new

  my $tr = Text::Transliterator->new($from, $to, $modifiers);
  # or
  my $tr = Text::Transliterator->new(\%map, $modifiers);

Creates a new transliterator function.

In the first syntax, the arguments are two strings that will be passed
directly to the C<tr/.../.../> operator 
(see L<perlop/"Regexp Quote-Like Operators">),
i.e. a string of characters to be replaced,
and a string of replacement characters.  The third argument
C<$modifiers> is optional and may contain a string with any
combination of the C<cdsr> modifiers to the C<tr/.../.../> operator.

In the second syntax, the argument is a hashref, in which
keys are the characters to be replaced, and values are the
replacement characters. Optional C<$modifiers> are as above.

Unlike usual object-oriented modules, here the return value from
the C<new> method is a reference to a function, not an object.
That function should be called as

  $tr->(@strings);

and modifies every member of C<@strings>.
By default strings are modified I<in place>,like with the C<tr/.../.../> operator,
unless the C<r> modifier is present.

The function returns the list of results of the C<tr/.../.../> operation on each of the input strings.
By default this will be the number of transliterated characters for each string.
If the C<r> modifier is present, the return value is the list of transliterated strings.
In scalar context, the last member of the list is returned (for compatibility with the previous API).

=head1 AUTHOR

Laurent Dami, C<< <dami@cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2025 Laurent Dami.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut


