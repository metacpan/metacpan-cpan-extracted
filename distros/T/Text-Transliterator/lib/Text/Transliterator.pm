package Text::Transliterator;
use strict;
use warnings;

our $VERSION = '1.03';

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

  # build the coderef
  my $src = "sub {tr[$from][$to]$modifiers for \@_ }";
  local $@;
  my $coderef = eval $src or die $@;

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
combination of the C<cds> modifiers to the C<tr/.../.../> operator.

In the second syntax, the argument is a hashref, in which
keys are the characters to be replaced, and values are the
replacement characters. Optional C<$modifiers> are as above.

The return value from that C<new> method is actually
a reference to a function, not an object. That function is called as

  $tr->(@strings);

and modifies every member of C<@strings> I<in place>,
like the C<tr/.../.../> operator.
The return value is the number of transliterated characters
in the last member of C<@strings>.

=head1 AUTHOR

Laurent Dami, C<< <dami@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-text-transliterator at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Transliterator>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Transliterator


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Transliterator>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-Transliterator>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-Transliterator>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-Transliterator/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2010, 2017 Laurent Dami.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut


