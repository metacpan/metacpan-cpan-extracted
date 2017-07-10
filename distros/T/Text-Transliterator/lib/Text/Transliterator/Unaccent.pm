package Text::Transliterator::Unaccent;

use warnings;
use strict;

our $VERSION = "1.03";

use Text::Transliterator;
use Unicode::UCD        qw(charinfo charscript charblock);
use Unicode::Normalize  qw();

sub char_map {
  my $class = shift;

  my @all_ranges;
  my $ignore_wide  = 0;
  my $ignore_upper = 0;
  my $ignore_lower = 0;

  # decode arguments to get character ranges and boolean flags
  while (my ($kind, $arg) = splice(@_, 0, 2)) {
    my $ranges;

    my $todo = {
      script   => sub { $ranges = charscript($arg)
                          or die "$arg is not a valid Unicode script" },
      block    => sub { $ranges = charblock($arg)
                          or die "$arg is not a valid Unicode block"  },
      ranges   => sub { $ranges = $arg },
      wide     => sub { $ignore_wide  = !$arg                         },
      upper    => sub { $ignore_upper = !$arg                         },
      lower    => sub { $ignore_lower = !$arg                         },
     };
    my $coderef = $todo->{$kind}
      or die "invalid argument: $kind";
    $coderef->();
    push @all_ranges, @$ranges if $ranges;
  }

  # default
  @all_ranges = @{charscript('Latin')} if !@all_ranges;

  # build the map
  my %map;
  foreach my $range (@all_ranges) {
    my ($start, $end) = @$range;

    # iterate over characters in range
  CHAR:
    for my $c ($start .. $end) {

      # maybe drop that char under some conditions
      last CHAR if $ignore_wide and $c > 255;
      next CHAR if $ignore_upper and chr($c) =~ /\p{Uppercase_Letter}/;
      next CHAR if $ignore_lower and chr($c) =~ /\p{Lowercase_Letter}/;

      # get canonical decomposition (if any)
      my $canon  = Unicode::Normalize::getCanon($c);

      # store into map
      if ($canon && length($canon) > 1) {
        # the unaccented char is the the base (first char) of the decomposition
        my $base = substr $canon, 0, 1;
        $map{chr($c)} = $base,
      }
    }
  }

  return \%map;
}

sub char_map_descr {
  my $class = shift;

  my $map = $class->char_map(@_);

  my $txt = "";
  while (my ($k, $v) = each %$map) {
    my $accented = ord($k);
    my $base     = ord($v);
    $txt .= sprintf "U+%04x %-40s => U+%04x %s\n", 
               $accented,
               charinfo($accented)->{name},
               $base,
               charinfo($base)->{name};
  }
  return $txt;
}

sub new {
  my $class = shift;
  my $map = $class->char_map(@_);
  return Text::Transliterator->new($map)
}

1; # End of Text::Transliterator::Unaccent


__END__

=head1 NAME

Text::Transliterator::Unaccent - Compile a transliterator from Unicode tables, to remove accents from text

=head1 SYNOPSIS

  my $unaccenter = Text::Transliterator::Unaccent->new(script => 'Latin',
                                                       wide   => 0,
                                                       upper  => 0);
  $unaccenter->($string);

  my $map   = Text::Transliterator::Unaccent->char_map(script => 'Latin');

  my $descr = Text::Transliterator::Unaccent->char_map_descr();

=head1 DESCRIPTION

This package compiles a transliteration function that will replace
accented characters by unaccented characters. That function
is fast, because it uses the builtin C<tr/.../.../> Perl operator; it
is compact, because it only treats the Unicode subset that you need
for your language; and it is complete, because it relies on
the builtin Unicode character tables shipped with your Perl installation.

The algorithm for detecting accented characters is derived from the notion
of I<compositions> in Unicode; that notion is explained in L<perluniintro>.
Characters considered "accented" are the precomposed characters for
which the Unicode canonical decomposition contains more than one
codepoint; for such decompositions, the first codepoint is the
unaccented character that will be mapped to the accented one.  This
definition seems to work well for the Latin script; I presume that it
also makes sense for other scripts as well, but I'm not able to test.

=head1 METHODS

=head2 new

  my $unaccenter = Text::Transliterator::Unaccent->new(@range_description);
  # or
  my $unaccenter = Text::Transliterator::Unaccent->new(); # script => 'Latin'

Compiles a new 'unaccenter' function. The C<@range_description>
argument specifies which ranges of characters will be handled, and is
comprised of pairs of shape :

=over

=item C<< script => $unicode_script >>

C<$unicode_script> is the name of a Unicode script, such as 'Latin', 
'Greek' or 'Cyrillic'.
For a complete list of unicode scripts, see

  perl -MUnicode::UCD=charscripts -e "print join ', ', keys %{charscripts()}"

=item C<< block => $unicode_block >>

C<$unicode_block> is the name of a Unicode block. For a complete list of 
Unicode blocks, see

  perl -MUnicode::UCD=charblocks -e "print join ', ', keys %{charblocks()}"

=item C<< range => \@codepoint_ranges >>

C<@codepoint_ranges> is a list of arrayrefs that contain
I<start-of-range, end-of-range>
code point pairs.

=item C<< wide => $bool >>

Decides if wide characters (i.e. characters with code points above 255)
are kept or not within the map. The default is I<true>.

=item C<< upper => $bool >>

Decides if uppercase characters are kept or not within the map. The
default is I<true>.

=item C<< lower => $bool >>

Decides if lowercase characters are kept or not within the map. The
default is I<true>.

=back

The C<@range_description> may contain a list of several scripts,
blocks and/or ranges; all will get concatenated into a single
correspondance map.  If the list is empty, the default range is
C<< script => 'Latin' >>.

The return value from that C<new> method is actually
a reference to a function, not an object. That function is called as 

  $unaccenter->(@strings);

and modifies every member of C<@strings> I<in place>, 
like the C<tr/.../.../> operator.
The return value is the number of transliterated characters
in the last member of C<@strings>.


=head2 char_map

  my $map = Text::Transliterator::Unaccent->char_map(@range_description);

Utility class method that 
returns a hashref of the accented characters in C<@range_description>,
mapped to their unaccented corresponding characters, according to
the algorithm described in the introduction. The C<@range_description>
format is exactly like for the C<new()> method.

=head2 char_map_descr

  my $descr = Text::Transliterator::Unaccent->char_map_descr(@range_descr);

Utility class method that 
returns a textual description of the map 
generated by C<@range_descr>.

=head1 SEE ALSO

L<Text::Unaccent> is another unaccenter module, with a C and a Pure
Perl version. It is based on C<iconv> instead of Perl's internal
Unicode tables, and therefore may produce slighthly different
results. According to some experimental benchmarks, the C version of
C<Text::Unaccent> is faster than C<Text::Transliterator::Unaccent> on
short strings and on small number of calls, and slower on long strings
or high number of calls (but this may be a side-effect of the fact
that it returns a copy of the string instead of replacing characters
in-place); however I am not able to give a predictable rule about
which module is faster in which circumstances.

L<Text::StripAccents> is a Pure Perl module. In only handles Latin1, and
is several orders of magnitude slower because it does an
internal split and join of the whole string.

L<Search::Tokenizer> uses the present module for building
an C<unaccent> tokenizer.


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

    perldoc Text::Transliterator::Unaccent


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


