# Copyright 2009, 2010, 2011, 2013, 2016 Kevin Ryde

# This file is part of Time-Duration-Locale.
#
# Time-Duration-Locale is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Time-Duration-Locale is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Time-Duration-Locale.  If not, see <http://www.gnu.org/licenses/>.

# cf Lingua::FI::Kontti too

package Time::Duration::en_PIGLATIN;
use 5.004;
use strict;
use Time::Duration::Filter;  #  from => 'Time::Duration';

use vars '$VERSION';
$VERSION = 12;

sub _filter {
  my ($str) = @_;

  # Could do something for apostrophe in the middle of a word, but that
  # doesn't arise from Time::Duration.
  $str =~ s{([[:alpha:]]+)}{
    my $word = $1;
    my $ret;
    if ($word =~ /^(([bcdfghjklmnprstvwxz]|qu?)+)([aeiouy].*)/i) {
      # leading consonants to end
      $ret = $3 . $1 . 'ay';
    } elsif ($word =~ /[aeiouy]$/i) {
      # ending in a vowel
      $ret = $word . 'way';
    } else {
      # ending in a consonant
      $ret = $word . 'ay';
    }
    _follow_caps ($word, $ret);
  }egi;
  return $str;
}

# Return $str with upper, lower or ucfirst case following what $orig has.
# If $orig is a single upper case char then it's treated as ucfirst.
sub _follow_caps {
  my ($orig, $str) = @_;
  return ($orig =~ /^[[:upper:]](.*[[:lower:]]|$)/ ? ucfirst(lc($str))
          : $orig =~ /[[:lower:]]/ ? lc($str)
          : uc($str));
}

# Text::Bastardize 0.08 has a bug where pig() goes into an infinite loop on
# a word with no vowels like a number "20" etc from Time::Duration ...
#
# use Text::Bastardize;
# my $bastardizer = Text::Bastardize->new;
# sub _pig {
#   my ($str) = @_;
#   $bastardizer->charge ($str);
#   return $bastardizer->pig;
# }

# use Time::Duration ();
# use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
# 
# $VERSION = 7;
# 
# use Exporter;
# @ISA = ('Exporter');
# 
# @EXPORT = @Time::Duration::EXPORT;
# @EXPORT_OK = @Time::Duration::EXPORT_OK;
# %EXPORT_TAGS = (all => \@EXPORT_OK);
# 
# foreach my $name (@EXPORT_OK) {
#   eval "sub $name { _pig (Time::Duration::$name (\@_)) }";
# }

1;
__END__

=for stopwords igpay Atinlay Ryde

=head1 NAME

Time::Duration::en_PIGLATIN - fun pig Latin time durations

=head1 SYNOPSIS

 use Time::Duration::en_PIGLATIN;
 print "next update ",duration(150),"\n";
  # prints "2 inutesmay andway 30 econdssay"

=head1 DESCRIPTION

C<Time::Duration::en_PIGLATIN> is a silly variant of C<Time::Duration>
returning duration strings in pig Latin (igpay Atinlay).  It can be used
directly, or via C<Time::Duration::Locale> with language setting
"en_PIGLATIN".

=head1 EXPORTS

Like C<Time::Duration>, the following functions are exported by default

    later()       later_exact()
    earlier()     earlier_exact()
    ago()         ago_exact()
    from_now()    from_now_exact()
    duration()    duration_exact()
    concise()

The exports follow C<Time::Duration> at run-time, so anything new there is
automatically filtered and exported.

=head1 SEE ALSO

L<Time::Duration>, L<Time::Duration::Locale>

L<Lingua::PigLatin>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/time-duration-locale/index.html>

=head1 COPYRIGHT

Copyright 2009, 2010, 2011, 2013, 2016 Kevin Ryde

Time-Duration-Locale is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Time-Duration-Locale is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Time-Duration-Locale.  If not, see <http://www.gnu.org/licenses/>.

=cut
