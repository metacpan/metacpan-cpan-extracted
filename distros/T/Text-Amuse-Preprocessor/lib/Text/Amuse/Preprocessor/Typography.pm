# -*- mode: cperl -*-
package Text::Amuse::Preprocessor::Typography;

use strict;
use warnings;
use utf8;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw/typography_filter linkify_filter
                   get_typography_filter/;

# frozen at 0.09
our $VERSION = '0.09';

use Text::Amuse::Preprocessor::TypographyFilters;


sub linkify_filter {
    return Text::Amuse::Preprocessor::TypographyFilters::linkify(shift);
}

sub _typography_filter_common {
  my $l = shift;
  $l =~ s/ﬁ/fi/g ;
  $l =~ s/ﬂ/fl/g ;
  $l =~ s/ﬃ/ffi/g ;
  $l =~ s/ﬄ/ffl/g ;
  $l =~ s/ﬀ/ff/g ;

  return $l;
}


sub _typography_filter_en {
  my $l = shift;
  # then the quotes
  # ascii style
  $l =~ s/``/“/g ;
  $l =~ s/(''|")\b/“/g ;
  $l =~ s/(?<=\s)(''|")/“/gs;
  $l =~ s/^(''|")/“/gm;
  $l =~ s/(''|")/”/g ;

  # single
  $l =~ s/'(?=[0-9])/’/g;
  $l =~ s/`/‘/g;
  $l =~ s/\b'/’/g;
  $l =~ s/'\b/‘/g;
  $l =~ s/^'/‘/gm;
  $l =~ s/'/’/g;

  # the dashes
  # this is the en-dash –
  $l =~ s/(?<![\-\/])\b(\d+)-(\d+)\b(?![\-\/])/$1–$2/g ;

  # em-dash —
  $l =~ s/(?<=\S) +-{1,3} +(?=\S)/ — /gs;

  # and the common case ^th
  $l =~ s!\b(\d+)(th|rd|st|nd)\b!$1<sup>$2</sup>!g;
  $l =~ s/(\. ){2,3}\./.../g;
  return $l;
}

sub _typography_filter_es {
  my $l = shift;

  # em-dash —
  # look behind and check it's not a \n
  # not a spece, space, one-three hyphens, space, not a space => space — space
  $l =~ s/(?<=\S) +-{1,3} +(?=\S)/ — /gs;
  # - at beginning of the line (with no space), it's a dialog (em dash)
  $l =~ s/^- */— /gm;


  # I believe the following rules are dangerous. What if someone says:
  # "the bit- and byte-wise" => "the bit — and byte-wise" !!!!
  # I believe they should be removed.

#   # fix "example- "
#   $l =~ s/ +-(?=\S)/ — /;
#   # and " -example"
#   $l =~ s/(?<=\S)- +/ — /;

  # better idea: check for matching on the same line
  $l =~ s/ +-(\w.+?\w)- +/ — $1 — /gm;

  # if it touches a word on the right, and on the left there is not a
  # word, it's an opening quote
  $l =~ s/(?<=\W)"(?=\w)/«/gs;
  $l =~ s/(?<=\W)'(?=\w)/‘/g;

  # if there is a space at the left, it's opening
  $l =~ s/(?<=\s)"/«/gs; 
  $l =~ s/(?<=\s)'/‘/gs;

  # beginning of line, opening
  $l =~ s/^"/«/gm; 
  $l =~ s/^'/‘/gm;

  # word at the left, closing
  $l =~ s/(?<=\w)'/’/g;
  $l =~ s/(?<=\w)"/»/g;

  # the others are right quotes, hopefully
  $l =~ s/"/»/gs;
  $l =~ s/'/’/g;

  # now the dots at the end of the quotations, but look behind not to
  # have another dot
  #  $l =~ s/(?<!\.)\.»(?=\s)/»./gs;
  
  return $l;
}


sub _typography_filter_fi {
  my $l = shift;
  $l =~ s/"/\x{201d}/g;
  $l =~ s/'/\x{2019}/g;
  $l =~ s/(?<=\S) +--? +(?=\S)/ \x{2013} /gs;
  return $l;
}

sub _typography_filter_sr {
  my $l = shift;
  $l =~ s/(''|")\b/\x{201e}/g ;
  $l =~ s/(?<=\s)(''|")/\x{201e}/gs;
  $l =~ s/(''|")/\x{201c}/g ;
  $l =~ s/(?<=\W)'(.*?)'(?=\W)/\x{201a}$1\x{2018}/gs;
  $l =~ s/'/\x{2019}/g; # remaining apostrophes
  $l =~ s/(?<=\S) +--? +(?=\S)/ \x{2013} /gs;
  return $l;
}

sub _typography_filter_hr {
  my $l = shift;
  $l =~ s/(''|")\b/\x{201e}/g ;
  $l =~ s/(?<=\s)(''|")/\x{201e}/gs;
  $l =~ s/(''|")/\x{201d}/g ; # ”
  $l =~ s/(?<=\W)'(.*?)'(?=\W)/\x{201a}$1\x{2019}/gs; # ‚ ’
  $l =~ s/'/\x{2019}/g;  # remaining apostrophes
  $l =~ s/(?<=\S) +--? +(?=\S)/ \x{2014} /gs; # —
  return $l;
}


sub _typography_filter_ru {
  my $l = shift;
  $l =~ s/(?<=\s)(''|")/«/gs;
  $l =~ s/^(''|")/«/gm;
  $l =~ s/(''|")\b/«/gs;
  $l =~ s/(''|")/»/g ;
  $l =~ s/'(?=[0-9])/’/g;
  $l =~ s/`/‘/g;
  $l =~ s/\b'/’/g;
  $l =~ s/'\b/‘/g;
  $l =~ s/'/’/g;
  # em-dash —
  $l =~ s/(?<=\S) +-{1,3} +(?=\S)/ — /gs;
  $l =~ s/(\. ){2,3}\./.../g;


  # NON-BREAKING SPACE INSERTIONS

  # before em dash (—) and en dash (−)
  $l =~ s/ (\x{2013}|\x{2014}|\x{2212})/\x{a0}$1/g;

  # space before, but only if there is a number, otherwise doesn't
  # make sense.

  $l =~ s/(?<=\d)
          [ ]+ # white space
          (
              # months
              января | февраля | марта    | апреля  | мая    | июня    |
              июля   | августа | сентября | октября | ноября | декабря |

              # units
              г|кг|мм|дм|см|м|км|л|В|А|ВТ|W|°C
          )
          \b # word boundary
         /\x{a0}$1/gsx;
  
  # space after:
  $l =~ s/\b # start with a word boundary
          ( 
              # prepositions
              в|к|о|с|у|
              В|К|О|С|У|
              на|от|об|из|за|по|до|во|та|ту|то|те|ко|со|
              На|От|Об|Из|За|По|До|Во|Со|Ко|Та|Ту|То|Те|

              # conjunctions
              А |А,|
              а |а,|
              И |И,|
              и |и,|
              но|но,|
              Но|Но,|

              # obuiquitous "da"
              да|да,|Да|Да,|

              # particles with space after
              не|ни|
              Не|Ни|

              # interjections, space after
              ну|ну,|
              Ну|Ну,|

              # abbreviations
              с\.|ч\.|
              см\.|См\.|
              им\.|Им\.|
              т\.|п\.
          )
          [ ]+ # white space
          (?=\S) # and look ahead for something that is not a white
                 # space or end of line
         /$1\x{a0}/gsx;


  # and a space before
  $l =~ s/(?<=\S) # look behind for something that is not \n
          [ ]+ # one or more space
          (
              # particles
              б|ж|ли|же|ль|бы|бы,|же,
          )
          (?=[\W]) # white space follows or something that is not a word
         /\x{a0}$1/gsx;


  return $l;
}


sub filters {
    return {
		    en => \&_typography_filter_en,
		    fi => \&_typography_filter_fi,
		    hr => \&_typography_filter_hr,
		    sr => \&_typography_filter_sr,
		    ru => \&_typography_filter_ru,
		    es => \&_typography_filter_es,
		   };
}

sub typography_filter {
  my $lang = $_[0];
  my $text = " " . $_[1] . " ";
  $text = _typography_filter_common($text);

  my $lang_filters = filters();
  if ($lang and exists $lang_filters->{$lang}) {
    $text = $lang_filters->{$lang}->($text);
  }
  my $llength = length($text) - 2; 
  return substr($text, 1, $llength);
}

sub get_typography_filter {
    my ($lang, $links) = @_;
    my @routines = (\&_typography_filter_common);
    my $lang_filters = filters();
    if ($lang && exists $lang_filters->{$lang}) {
        push @routines, $lang_filters->{$lang};
    }
    if ($links) {
        push @routines, \&linkify_filter;
    }
    return sub {
        my $text = shift;
        $text = ' ' . $text . ' ';
        foreach my $sub (@routines) {
            $text = $sub->($text);
        }
        my $llength = length($text) - 2;
        return substr($text, 1, $llength);
    };
}

1;

__END__

=encoding utf8

=head1 NAME

Text::Amuse::Preprocessor::Typography - Perl extension for pre-processing of Text::Amuse files [DEPRECATED]

=head1 SYNOPSIS

  use Text::Amuse::Preprocessor::Typography qw/typography_filter/;
  my $cleanedtext = typography_filter($lang, $text)
  

=head1 DESCRIPTION

Common routines to filter the input files, fixing typography and
language-specific rules. All the text is assumed to be already decoded.

This module is B<DEPRECATED> and kept only for legacy. Please use the
interface described in L<Text::Amuse::Preprocessor> instead.

=head1 FUNCTIONS

=head2 linkify_filter($string)

Detect and replace the bare links with the proper markup, as
[[http://domain.org/my/url/and_params?a=1&b=c][domain.org]]

It's a bit opinionated to hide the full url and show only the domain.
Anyway, it's a preprocessing filter and the most important thing is
not to loose pieces. And we don't, because the full url is still
there. Anyway, long urls are a pain to display and to typeset, so the
domain is a sensible choice. The user can anyway change this. It's
just an helper to avoid boring tasks, nothing more.

Returns the adjusted string.

=head2 typography_filter($lang, $string)

Perform the smart replacement of single quotes, double quotes, dashes
and, in some cases, the superscript for things like 2nd, 13th, etc.

The languages supported are C<en>, C<fi>, C<hr>, C<sr>, C<ru>, C<es>.

Returns the adjusted string.

=head2 get_typography_filter($lang, $links)

Return a sub which you can call later on a string. The sub will first
call the common replacements (ugly unicode ligatures). If the first
argument is set and is a valid language, will do the language specific
replacements. If the second argument is set and true, will also fix
the links.

The sub itself will return the adjusted string.

=head2 filters()

Return an hashref with the filters subs.

=cut



=head1 SEE ALSO

L<Text::Amuse::Preprocessor>

=cut
