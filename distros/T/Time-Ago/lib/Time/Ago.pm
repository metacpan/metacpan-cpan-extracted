package Time::Ago;
# ABSTRACT: Approximate duration in words

# Port of Rails distance_of_time_in_words and time_ago_in_words
# http://apidock.com/rails/v4.2.1/ActionView/Helpers/DateHelper/distance_of_time_in_words

use strict;
use warnings;
use utf8;
use Carp;
use Encode;
use Locale::Messages qw/ bind_textdomain_filter /;
use Locale::TextDomain 'Time-Ago';
use Scalar::Util qw/ blessed /;

our $VERSION = '1.00';

BEGIN {
  $ENV{OUTPUT_CHARSET} = 'UTF-8';
  bind_textdomain_filter 'Time-Ago' => \&Encode::decode_utf8;
}

use constant {
  MINUTES_IN_QUARTER_YEAR        => 131400, # 91.25 days
  MINUTES_IN_THREE_QUARTERS_YEAR => 394200, # 273.75 days
  MINUTES_IN_YEAR                => 525600,
};


sub new {
  my $class = shift;

  $class = ref($class) || $class;
  my $self = bless {}, $class;

  while (@_) {
    my ($method, $val) = splice @_, 0, 2;
    $self->$method(ref $val eq 'ARRAY' ? @$val : $val);
  }

  return $self;
}


{
  my %locale = (
    about_x_hours => sub {
      __nx('about {count} hour', 'about {count} hours', $_, count => $_);
    },

    about_x_months => sub {
      __nx('about {count} month', 'about {count} months', $_, count => $_);
    },

    about_x_years => sub {
      __nx('about {count} year', 'about {count} years', $_, count => $_);
    },

    almost_x_years => sub {
      __nx('almost {count} year', 'almost {count} years', $_, count => $_);
    },

    half_a_minute => sub { __('half a minute') },

    less_than_x_minutes => sub {
      __nx('less than a minute', 'less than {count} minutes', $_, count => $_);
    },

    less_than_x_seconds => sub {
      __nx(
        'less than {count} second',
        'less than {count} seconds',
        $_,
        count => $_,
      );
    },

    over_x_years => sub {
      __nx('over {count} year', 'over {count} years', $_, count => $_);
    },

    x_days => sub {
      __nx('{count} day', '{count} days', $_, count => $_);
    },

    x_minutes => sub {
      __nx('{count} minute', '{count} minutes', $_, count => $_);
    },

    x_months => sub {
      __nx('{count} month', '{count} months', $_, count => $_);
    },
  );

  sub _locale {
    my $self = shift;

    return sub {
      my $string_id = shift or croak 'no string id supplied';
      my %args = @_;

      my $sub = $locale{ $string_id }
        or croak "unknown locale string_id '$string_id'";

      local $_ = $args{count};
      return $sub->();
    };
  }
}


sub in_words {
  my $self = shift;
  my %args = (@_ % 2 ? (duration => @_) : @_);

  defined $args{duration} or croak 'no duration supplied';
  my $duration = $args{duration}; 

  if (blessed $duration) {
    if ($duration->can('epoch')) { # DateTime/Time::Piece-like object
      $duration = time - $duration->epoch;
    } elsif ($duration->can('delta_months')) { # DateTime::Duration-like
      # yes, we're treating every month as 30.41 days
      $duration = ($duration->delta_months  * (86400 * 365 / 12)) +
                  ($duration->delta_days    * 86400) +
                  ($duration->delta_minutes * 60)    +
                  $duration->delta_seconds
      ;
    }
  }

  my $round = sub { int($_[0] + 0.5) };

  $duration = abs $duration;
  my $mins = $round->($duration / 60);
  my $secs = $round->($duration);

  my $locale = $self->_locale;

  if ($mins <= 1) {
    unless ($args{include_seconds}) {
      return $mins == 0 ?
        $locale->('less_than_x_minutes', count => 1) :
        $locale->('x_minutes', count => $mins)
      ;
    }

    return $locale->('less_than_x_seconds', count => 5)  if $secs <= 4;
    return $locale->('less_than_x_seconds', count => 10) if $secs <= 9;
    return $locale->('less_than_x_seconds', count => 20) if $secs <= 19;
    return $locale->('half_a_minute', count => 20)       if $secs <= 39;
    return $locale->('less_than_x_minutes', count => 1)  if $secs <= 59;
    return $locale->('x_minutes', count => 1);
  }

  return $locale->('x_minutes', count => $mins) if $mins <= 44;
  return $locale->('about_x_hours', count => 1) if $mins <= 89;

  # 90 mins up to 24 hours
  if ($mins <= 1439) {
    return $locale->('about_x_hours', count => $round->($mins/60));
  }

  # 24 hours up to 42 hours
  return $locale->('x_days', count => 1) if $mins <= 2519;

  # 42 hours up to 30 days
  return $locale->('x_days', count => $round->($mins / 1440)) if $mins <= 43199;

  # 30 days up to 60 days
  if ($mins <= 86399) {
    return $locale->('about_x_months', count => $round->($mins / 43200));
  }

  # 60 days up to 365 days
  if ($mins <= 525600) {
    return $locale->('x_months', count => $round->($mins / 43200));
  }

  # XXX does not implement leap year stuff that Rails implementation has

  my $remainder = $mins % MINUTES_IN_YEAR;
  my $years     = int($mins / MINUTES_IN_YEAR);

  if ($remainder < MINUTES_IN_QUARTER_YEAR) {
    return $locale->('about_x_years', count => $years);
  }

  if ($remainder < MINUTES_IN_THREE_QUARTERS_YEAR) {
    return $locale->('over_x_years', count => $years);
  }
  
  return $locale->('almost_x_years', count => $years + 1); 
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Time::Ago - Approximate duration in words

=head1 VERSION

version 1.00

=head1 SYNOPSIS

  use Time::Ago;

  print Time::Ago->in_words(0), "\n";
  # prints "less than a minute"

  print Time::Ago->in_words(3600 * 4.6), "\n";
  # prints "about 5 hours"
  
  print Time::Ago->in_words(86400 * 360 * 2), "\n";
  # prints "almost 2 years"
  
  print Time::Ago->in_words(86400 * 365 * 11.3), "\n";
  # prints "over 11 years"

=head1 DESCRIPTION

Given a duration, in seconds, returns a readable approximation.
This a Perl port of the time_ago_in_words() helper from Rails.

From Rails' docs:

  0 <-> 29 secs
    less than a minute

  30 secs <-> 1 min, 29 secs
    1 minute

  1 min, 30 secs <-> 44 mins, 29 secs
    [2..44] minutes

  44 mins, 30 secs <-> 89 mins, 29 secs
    about 1 hour

  89 mins, 30 secs <-> 23 hrs, 59 mins, 29 secs
    about [2..24] hours

  23 hrs, 59 mins, 30 secs <-> 41 hrs, 59 mins, 29 secs
    1 day

  41 hrs, 59 mins, 30 secs <-> 29 days, 23 hrs, 59 mins, 29 secs
    [2..29] days

  29 days, 23 hrs, 59 mins, 30 secs <-> 44 days, 23 hrs, 59 mins, 29 secs
    about 1 month

  44 days, 23 hrs, 59 mins, 30 secs <-> 59 days, 23 hrs, 59 mins, 29 secs
    about 2 months

  59 days, 23 hrs, 59 mins, 30 secs <-> 1 yr minus 1 sec
    [2..12] months

  1 yr <-> 1 yr, 3 months
    about 1 year

  1 yr, 3 months <-> 1 yr, 9 months
    over 1 year

  1 yr, 9 months <-> 2 yr minus 1 sec
    almost 2 years

  2 yrs <-> max time or date
    (same rules as 1 yr)

=head1 METHODS

=over 4

=item in_words 

  Time::Ago->in_words(30); # returns "1 minute"
  Time::Ago->in_words(3600 * 24 * 365 * 10); # returns "about 10 years"

Given a duration, in seconds, returns a readable approximation in words.

If an include_seconds parameter is supplied, durations under one minute
generate more granular phrases:

  foreach (4, 9, 19, 39, 59) {
    print Time::Ago->in_words($_, include_seconds => 1), "\n";
  }

  # less than 5 seconds
  # less than 10 seconds
  # less than 20 seconds
  # half a minute
  # less than a minute

As a convenience, if the duration is an object with an epoch() interface
(as provided by Time::Piece or DateTime), the current time minus the
object's epoch() seconds is used.

Passing the duration as a DateTime::Duration instance is also supported.

=back

=head1 LOCALIZATION

Locale::TextDomain is used for localization.

Currently Arabic, Dutch, English, French, German, Italian, Japanese, Russian,
and Spanish translations are available. Contact me if you need another
language.

See L<Locale::TextDomain> for how to specify a language.

  #!/usr/bin/env perl
  
  use strict;
  use warnings;
  use open qw/ :std :utf8 /;
  use POSIX ':locale_h';
  use Time::Ago;
  
  my $secs = 86400 * 365 * 10.4;
  
  foreach (qw/ en fr de it ja ru es /) {
    setlocale(LC_ALL, '');
    $ENV{LANGUAGE} = $_;
    print Time::Ago->in_words($secs), "\n";
  }

Output:

  over 10 years
  plus de 10 ans
  vor mehr als 10 Jahren
  oltre 10 anni
  10年以上
  больше 10 лет
  más de 10 años

=head1 BUGS

The rails' implementation includes some logic for leap years that is not
implemented here.

=head1 CREDITS

Ruby on Rails DateHelper
L<http://apidock.com/rails/v4.2.1/ActionView/Helpers/DateHelper/distance_of_time_in_words>

Ruby i18n library
L<https://github.com/svenfuchs/i18n>

=head1 SEE ALSO

Github repository L<https://github.com/mla/time-ago>

L<Time::Duration>, L<DateTime::Format::Human::Duration>, L<Locale::TextDomain>

=head1 AUTHOR

Maurice Aubrey <maurice.aubrey@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Maurice Aubrey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
