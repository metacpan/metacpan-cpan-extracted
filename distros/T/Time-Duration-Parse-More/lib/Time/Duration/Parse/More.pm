package Time::Duration::Parse::More;

# ABSTRACT: parse natural language time duration expressions
our $VERSION = '0.008'; # VERSION
our $AUTHORITY = 'cpan:MELO'; # AUTHORITY

use strict;
use warnings;
use Exporter;
use Carp;

our @ISA    = qw( Exporter );
our @EXPORT = qw( parse_duration );

# From Time::Duration::Parse
my %units = (
  map(($_, 1),                  qw(s second seconds sec secs)),
  map(($_, 60),                 qw(m minute minutes min mins)),
  map(($_, 60 * 60),            qw(h hr hour hours)),
  map(($_, 60 * 60 * 24),       qw(d day days)),
  map(($_, 60 * 60 * 24 * 7),   qw(w week weeks)),
  map(($_, 60 * 60 * 24 * 30),  qw(M month months)),
  map(($_, 60 * 60 * 24 * 365), qw(y year years))
);

my %cache;

sub parse_duration {
  my ($expression) = @_;
  return unless defined $expression;

  return $cache{$expression} if exists $cache{$expression};

  my ($val, $cacheable) = _parse_duration($expression);
  return $val unless $cacheable;
  return $cache{$expression} = $val;
}

sub parse_duration_nc { return (_parse_duration(@_))[0] }

sub _parse_duration {
  my ($expression) = @_;
  return unless defined $expression;

  my $e = $expression;

  ### split up 1h2m3s...
  my $n_re = qr{[-+]?\d+(?:[.,]\d+)?};
  $e =~ s/ ($n_re) ([hsm]) (?= $n_re [hsm]) /$1 $2 /gxi;
  $e =~ s/ ($n_re) ([hsm]) \b / $1 $2 /gxi;

  $e =~ s/\band\b/ /gi;
  $e =~ s/[\s\t]+/ /g;
  $e =~ s/^\s+|\s+$//g;

  $e =~ s/^\s*([-+]?\d+(?:[.,]\d+)?)\s*$/$1s/;
  $e =~ s/^\s*([-+]?[.,]\d+)\s*$/$1s/;
  $e =~ s/\b(\d+):(\d+):(\d+)\b/$1h $2m $3s/g;
  $e =~ s/\b(\d+):(\d+)\b/$1h $2m/g;

  my $duration  = 0;
  my $cacheable = 1;
  my $signal    = 1;
  while ($e) {
    if    ($e =~ s/^plus\b(\s*,?)*//)  { $signal = 1 }
    elsif ($e =~ s/^minus\b(\s*,?)*//) { $signal = -1 }
    elsif ($e =~ s/^(([-+]?\d+(?:[,.]\d*)?)\s*(\w+))(\s*,?)*// or $e =~ s/^(([-+]?[,.]\d+)\s*(\w+))(\s*,?)*//) {
      my ($m, $n, $u) = ($1, $2, $3);
      $n =~ s/,/./;
      $u = lc($u) unless length($u) == 1;
      croak "Unit '$u' not recognized in '$m'" unless exists $units{$u};
      $duration += $signal * $n * $units{$u};
    }
    elsif ($e =~ s/^midnight\b(\s*,?)*//) {
      my ($sec, $min, $hour) = (localtime())[0 .. 2];
      $duration += $signal * (60 - $sec + (60 - $min - 1) * 60 + (24 - $hour - 1) * 60 * 60);

      ## 'midnight' is uncacheable
      $cacheable = 0;
    }
    else {
      croak("Could not parse '$e'");
    }
  }

  return (sprintf('%.0f', $duration), $cacheable);
}


1;

__END__

=pod

=encoding UTF-8

=for :stopwords Pedro Melo ACKNOWLEDGEMENTS cpan testmatrix url annocpan anno bugtracker rt
cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 NAME

Time::Duration::Parse::More - parse natural language time duration expressions

=head1 VERSION

version 0.008

=head1 SYNOPSIS

    use Time::Duration::Parse::More;

    my ($seconds);
    $seconds = parse_duration('1 minute, 30 seconds'); ## 90
    $seconds = parse_duration('1 minute plus 15 seconds'); ## 75
    $seconds = parse_duration('1 minute minus 15 seconds'); ## 45
    $seconds = parse_duration('1 day minus 2.5 hours and 10 minutes plus 15 seconds'); ## 76815
    $seconds = parse_duration('minus 15 seconds'); ## -15
    $seconds = parse_duration('midnight'); ## it depends :)

=head1 DESCRIPTION

The module parses a limited set of natural language expressions and converts
them into seconds.

It is backwards compatible with L<Time::Duration::Parse> (passes the same test
cases), but adds more expressions and memoization.

At the moment, the module is limited to english language expressions.

=head2 Rules

The following rules are used to parse the expressions:

=over 4

=item *

horizantal white-space, commas and the token I<and> are ignored;

=item *

an expresion in the form C<< N factor >> is translated to C<< N *
factor_in_seconds >>. C<factor> is optional, defaults to I<seconds>. Negative
and fractional values of C<N> are suported. Singular, plural and single letter
versions of C<factor> are also recognised. All are case-insensitive B<except>
the single letter versions;

=item *

expressions in the form C<hh:mm:ss>, C<hh:mm>, and C<XhYmZs> (any order, all
parts optional) are also supported;

=item *

the tokens I<plus> or I<minus> change the signal of the expressions that follow
them;

=item *

the final value is the sum of all the expressions taking in account the sign
defined by the previous rule.

=back

The hard-coded 'midnight' expression is also understood and returns the number
of seconds up to 00:00:00 of the next day.

=head2 Factors

The following factors are understood, with the corresponding value in seconds
between parentesis:

=over 4

=item *

seconds (1): s, second, seconds, sec, and secs;

=item *

minutes (60): m, minute, minutes, min, and mins;

=item *

hours (60 * minutes factor): h, hr, hour, and hours;

=item *

days (24 * hours factor): d, day, and days;

=item *

weeks (7 * days factor): w, week, and weeks;

=item *

months (30 * days factor): M (note the case), month and months;

=item *

years (365 * days factor): y, year, and years;

=back

=encoding utf8

=head1 FUNCTIONS

=head2 parse_duration

    $seconds = parse_duration($expression);

Given an C<$expression> in natural lanaguage returns the number of seconds it
represents. This result, with the exception of the 'midnight' expression, is
cached so future calls with the same expression will be faster.

If the expression cannot be parsed, C<parse_duration> will croak.

=head2 parse_duration_nc

Same as L</parse_duration>, but the result will not be cached.

=head1 HISTORY

This module started as a private module for a closed-source project. I started
to release it as C<Time::Delta> when I discovered L<Time::Duration::Parse>. I
updated the API to match it, and added my own improvements. This is the result.

=head1 SEE ALSO

L<Time::Duration::Parse> and L<Time::Duration>.

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Time::Duration::Parse::More

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/Time-Duration-Parse-More>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/T/Time-Duration-Parse-More>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Time-Duration-Parse-More>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Time::Duration::Parse::More>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Time-Duration-Parse-More>

=back

=head2 Email

You can email the author of this module at C<MELO at cpan.org> asking for help with any problems you have.

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the web interface at L<https://github.com/melo/perl-time-duration-parse-more/issues>. You will be automatically notified of any progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/melo/perl-time-duration-parse-more>

  git clone git://github.com/melo/perl-time-duration-parse-more.git

=head1 ACKNOWLEDGEMENTS

Stole test cases and other small tidbits from Miyagawa's
L<Time::Duration::Parse>.

=head1 AUTHOR

Pedro Melo <melo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Pedro Melo.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
