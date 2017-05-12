package Test::Locale::Utils;
#                                doom@kzsu.stanford.edu
#                                29 Jan 2006

=head1 NAME

Test::Locale::Utils - utilities for writing tests involving international characters

=head1 SYNOPSIS

   use Test::More;
   use Test::Locale::Utils qw( is_locale_international );

   my $i18n_test_cases = {
     'über maus' =>
     'Über Maus',

     'l\'oeuvre imposante d\'Honoré de Balzac' =>
     'L\'Oeuvre Imposante d\'Honoré de Balzac',
   }
   my $i18n_test_count = scalar( keys( %{ $i18n_test_cases } ) );

   my $i18n_system = is_locale_international();
   SKIP: {
      skip "Can't test strings with international chars", $i18n_count, unless $i18n_system;
      foreach my $case (sort keys %{ $i18n_test_cases }) {
        my $expected = $i18n_test_cases->{ $case };
        my $result   = capitalize_title( $case );
        is ($result, $expected, "Testing: $case");
      }
   }


  # Older style (deprecated):

   use Test::More;
   use Test::Locale::Utils qw(:all);
   my @exchars = extract_extended_chars(\@strings);
   my $internat = internationalized_locale(@exchars);  # Deprecated
   my $exchars_str = join '', @exchars;
   my $exchars_rule = qr{[$exchars_str]};

   foreach my $string (@strings) {
      SKIP: {
         skip "This locale can't deal with i18n chars in string: $string", 1,
             unless ($internat && ($string =~ /$exchars_rule/) );

         is( $expected{$string}, string_transformation($string), "Testing $string" );
      }
   }

=head1 DESCRIPTION

A small collection of utility functions to make it easier to
write tests that work with strings that may contain characters
beyond the 7bit ASCII range (e.g. the "extended characters" or
"international characters" of iso9959-1 and friends).

=head1 EXPORTED

Nothing by default.  All of the following are exportable
on request (and all may be requested with the ":all" tag).

=over

=cut

use 5.006;
use strict;
use warnings;
# use locale;
use utf8;
use Carp;
use Data::Dumper;
# use List::MoreUtils qw( all ); # Not in core, so writing my own "all"

my $DEBUG = 0;

require Exporter;
use vars qw( @ISA %EXPORT_TAGS @EXPORT @EXPORT_OK $VERSION);

@ISA = qw(Exporter);
%EXPORT_TAGS = ( 'all' => [ qw(
  extract_extended_chars
  internationalized_locale
  is_locale_international
  define_sample_i18n_chars
  all_true
  is_uc_and_lc_internationalized
  is_ucfirst_internationalized

) ] );
@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
@EXPORT = qw(  );

$VERSION = '0.01';

=item extract_extended_chars

Given a reference to an array of strings, returns a list of all
extended characters (i.e. characters with the eigth-bit set) that
have appeared at least once in the strings.

=cut

sub extract_extended_chars  {
    my $aref = shift;

    my $sevenbit_rule = qr{[\x00-\x7F]};

    my %seen;
    foreach my $string ( @{$aref} ) {
      (my $residue = $string) =~ s/$sevenbit_rule//g;
      my @chars = split //, $residue;
      @seen{@chars} = (); # mark these chars as seen by filling hash with "undef" values
    }
    my @exchars = sort keys %seen;
    return @exchars;
}

=item is_locale_international

Does some crude checks of uc, lc, and ucfirst to see if they
handle some international characters (latin-1) correctly,
or at least well enough that we can expect the international
character test cases of Text::Capitalize to have meaningful
results.

=cut

sub is_locale_international {
  my $result =
    all_true(
             [  is_uc_and_lc_internationalized(),
                is_ucfirst_internationalized(),
             ]);
  return $result;
}



=item  is_uc_and_lc_internationalized

Looks at the behavior of uc and lc for a small sample of
"international characters": this simply checks if the extended
characters of latin-1 and friends have an upper and lower form
defined as expected.

=cut

sub is_uc_and_lc_internationalized {
  my $exchars = define_sample_i18n_chars();
#  use locale;
  use utf8;

  my @checks;
  foreach my $pair ( @{ $exchars } ) {
    my $lower = $pair->[0];
    my $upper = $pair->[1];

    my $new_up   = uc($lower);
    my $new_down = lc($upper);

    if ( ($upper eq $new_up)   &&
         ($lower eq $new_down) ) { # transformed as expected
      push @checks, 1;
    } else {
      push @checks, 0;
    }
  }
  print STDERR "internationalized_locale: char status: ",
    join " ", @checks, "\n" if ($DEBUG) ;
  my $okay = all_true( \@checks );

  return $okay;
}


=item define_sample_i18n_chars

Returns a short list of pairs of extended characters,
pairing a lowercase form with an uppercase one
(an aref of arefs).

These were selected because they're the only extended
characters in use in the test cases for L<Text::Capitalize>.

=cut

sub define_sample_i18n_chars {
  use utf8;
  my @exchars = (
                  ['ü', 'Ü'],
                  ['é', 'É'],
                  ['í', 'Í'],
                  ['ó', 'Ó'],
                 );

  # print Dumper( \@exchars ), "\n";
  return \@exchars;
}

=item is_ucfirst_internationalized

A very specific test to to see if ucfirst can upcase German's
"over".  If it can, we assume ucfirst is working on the kind of
international characters used in the Text::Capitalized tests.

Motivation:

Solaris boxes apparently have a knack for getting uc and lc to
work on international characters, but still leaving ucfirst
broken -- it upcases the character *after* a leading
international character (such as a latin-1 u-umlaut):

  Text-Capitalize-0.8:
  - i86pc-solaris-thread-multi / 5.8.8:
    - FAIL http://nntp.x.perl.org/group/perl.cpan.testers/5882611

  - sun4-solaris-64int / 5.8.4:
    - FAIL http://nntp.x.perl.org/group/perl.cpan.testers/5846995

=cut

sub is_ucfirst_internationalized {
#  use locale;
  my ($over, $upper_over);
  {
    use utf8;
    $over       = 'über';
    $upper_over = 'Über';
  }
  use utf8;
  my $new_upper = ucfirst( $over );

  if( $new_upper eq $upper_over ) {
    return 1;
  } else {
    return 0;
  }
}

=item all_true

Example usage:

  my $okay = all_true( \@checks );

This is an alternative to List::MoreUtils "all", written to
avoid a non-core dependency for the L<Text::Capitalize> tests.

Note: If you'd rather use that more common module, do this:

   use List::MoreUtils qw( all );
   my $okay = all { ($_) } @checks;

=cut

sub all_true {
  my $aref = shift;
  my $flag = 1;
  foreach my $item ( @{ $aref } ) {
    unless ($item) {
      $flag = 0;
      last;
    }
  }
  return $flag;
}

=item  internationalized_locale

DEPRECATED.  use L<is_locale_international> instead.

Given an array of extended characters that you care about,
this code will check to make sure that the current locale
seems to comprehend what to do with them.  Specifically,
it checks to see if they have a defined upper and lower case.

This is an excessively simple version that just looks at the
extended characters to see if they change case when run through
either uc or lc.

This apparently fails for some locales, e.g. Russian, where the
extended chars are in the same locations as in iso8859, but the
upper and lower have reversed positions.

=cut

sub internationalized_locale {
  my @exchars = @_;
#  use locale;

  my $okay = 1;
  foreach my $ex (@exchars) {
    my $up = uc($ex);
    my $down = lc($ex);
    if ($up eq $down) { # then we got problems
      warn "For this locale, uc & lc act strangely on $ex\n" if $DEBUG;
      $okay = 0;
    }
  }
  return $okay;
}

1;
__END__

=back

=head1 DISCUSSION

The "use locale" story seems to have some notable gaps.
A brief summary, off the top of my head:

There's no definitive way to get a listing of all available
locales on a system.  The right way to do it varies from platform
to platform.  There's no definitive way of finding out what
platform you're on: You can check ^O, but you need to parse it
yourself (and that's not as easy as you might think: matching for
/win/ to see if you're on a windows platform will get confused in
cases like "cygwin").  There's no definitive list of all possible
values of ^O.  There are some useful tricks in the POSIX module that
can help with these issues, but you can't count on every system that
perl runs on being POSIX compliant, (and like I just said,
checking what kind of platform you're on is a little trickier
than you'd think).

And a recent discovery of mine: when the locale is utf-8,
doing a "use locale" does not give you "unicode semantics",
you actually have to do "utf8::upgrade" on anything you
want "uc" and friends to work on.  Heigh-ho.

This little module is an attempt at cutting the Gordian Knot
represented by this cluster of problems, at least as far as
the automated tests for L<Text::Capitalize> are concerned.

Since it's difficult to determine the Right Way to do cross-platform
checks of string handling including international characters,
instead I use some simple operational tests to see if the system
does what's expected with the international characters, and if not,
the tests using those characters will be skipped.

=head1 SEE ALSO

L<perlocale>

=head1 AUTHOR

Joseph Brenner, E<lt>doom@kzsu.stanford.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Joseph Brenner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut

# Local Variables:
# coding: utf-8-unix
# End:
