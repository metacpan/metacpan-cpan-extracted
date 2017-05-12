package Ucam::Term;

use strict;
use warnings;

use Carp;
use DateTime;
use DateTime::Span;
use DateTime::Duration;

our $VERSION = "3.00";

=head1 NAME

Ucam::Term - return information about the start and end dates of terms
(and a few related events) at the University of Cambridge, UK.

=head1 SYNOPSIS

  use Ucam::Term;

  my $term = Ucam::Term->new('m',2010);
  print $term->name, " term ", $term->year, " starts ";
  print $term->dates->start, "\n";

  my $term = Ucam::Term->new('e',2015);
  print "General Admission ", $term->year, " starts ";
  print $term->general_admission->start, "\n";

=head1 DESCRIPTION

The academic year at the University of Cambridge, UK, is divided into
three I<Terms> - I<Michaelmas> (autumn), I<Lent> (spring) and
I<Easter> (summer). The half-way point of each term is called the
I<Division of Term>. Three quarters of each Term is designated I<Full
Term>, during which lectures are given and when undergraduate students
are normally required to be in residence. Near the end of the Easter
Term there are three or four days of I<General Admission>, during which
degrees are conferred on those who have just successfully completed
courses, followed by the I<Long Vacation period of residence> during
which some additional courses of instruction are given.

The dates of some of these events and periods are fixed, but others
depend on dates that appear in the University's published 'Ordnances'
(see L</SEE ALSO> below for references) which are updated from time to
time. This version of the module contains data covering the period
from the Michaelmas Term 2007 to the Easter Term 2030.

This module returns L<DateTime> or L<DateTime::Span> objects
corresponding to these events and periods. Note that the
DateTime::Span objects run from 00:00 (inclusive) on the day the
period starts to 00:00 (exclusive) on the day after the period ends
(see DateTime::Span->end_is_open). This means that
union/intersection/complement/intersects/contains operations will all
work correctly, but that it is normally necessary to subtract one day
from the end date of the span in order to find the date of the last
day of the period.

=cut

# See Ordinances, Chapter II, Section 10 'Dates of Term and Full Term'
# and Ordinances, Chapter II, Section 12 'Admission to Degrees'
# http://www.admin.cam.ac.uk/univ/so/ as ammended in respect of
# General Admission by grace 1 of 13 February 2013
# (http://www.admin.cam.ac.uk/reporter/2012-13/weekly/6297/section6.shtml)
# and by grace 2 of 5 February 2014
# (http://www.admin.cam.ac.uk/reporter/2013-14/weekly/6336/section8.shtml)

# "The dates on which Full Terms begin and end shall be as shown in
# the table appended to these regulations"

# This data represents the first day of full term and of General
# Admission (Thursdays before 2014, Wednesdays from 2014 onwards),
# extracted from the table in S&O Chapter II, Section 10 (2009 edition
# for 2007 to 2020, 2012 edition for 2011 to 2030)

use constant FULL_TERM_START =>
#                   Jan      Apr  Jun/Jul      Oct
    { 2007 => {                            m =>  2 },
      2008 => { l => 15, e => 22, g => 26, m =>  7 },
      2009 => { l => 13, e => 21, g => 25, m =>  6 },
      2010 => { l => 12, e => 20, g => 24, m =>  5 },
      2011 => { l => 18, e => 26, g => 30, m =>  4 },
      2012 => { l => 17, e => 24, g => 28, m =>  2 },
      2013 => { l => 15, e => 23, g => 27, m =>  8 },
      2014 => { l => 14, e => 22, g => 25, m =>  7 },
      2015 => { l => 13, e => 21, g => 24, m =>  6 },
      2016 => { l => 12, e => 19, g => 22, m =>  4 },
      2017 => { l => 17, e => 25, g => 28, m =>  3 },
      2018 => { l => 16, e => 24, g => 27, m =>  2 },
      2019 => { l => 15, e => 23, g => 26, m =>  8 },
      2020 => { l => 14, e => 21, g => 24, m =>  6 },
      2021 => { l => 19, e => 27, g => 30, m =>  5 },
      2022 => { l => 18, e => 26, g => 29, m =>  4 },
      2023 => { l => 17, e => 25, g => 28, m =>  3 },
      2024 => { l => 16, e => 23, g => 26, m =>  8 },
      2025 => { l => 21, e => 29, g => 2,  m =>  7 },
      2026 => { l => 20, e => 28, g => 1,  m =>  6 },
      2027 => { l => 19, e => 27, g => 30, m =>  5 },
      2028 => { l => 18, e => 25, g => 28, m =>  3 },
      2029 => { l => 16, e => 24, g => 27, m =>  2 },
      2030 => { l => 15, e => 23, g => 26,         },
  };

use constant TERM_NAME => { m => 'Michaelmas', l => 'Lent', e => 'Easter' };

use constant JAN => 1;
use constant FEB => 2;
use constant MAR => 3;
use constant APR => 4;
use constant MAY => 5;
use constant JUN => 6;
use constant JUL => 7;
use constant AUG => 8;
use constant SEP => 9;
use constant OCT => 10;
use constant NOV => 11;
use constant DEC => 12;

# The legths of the various terms
use constant EIGHTY_DAYS     => DateTime::Duration->new( days => 80 );
use constant SEVENTY_DAYS    => DateTime::Duration->new( days => 70 );
use constant SIXTY_DAYS      => DateTime::Duration->new( days => 60 );
use constant FIFTYTHREE_DAYS => DateTime::Duration->new( days => 53 );
use constant THREE_DAYS      => DateTime::Duration->new( days =>  3 );
use constant FOUR_DAYS       => DateTime::Duration->new( days =>  4 );

=head1 METHODS

=over 4

=item * Ucam::Term->new()

Create a new Ucam::Term object

  my $term = Ucam::Term->new('michaelmas',2010);

Requires two arguments: term and year. Term can be 'm', 'mich',
'michaelmas', 'l', 'lent', 'e', 'easter' in any mixture of case. Year
should be the full 4-digit year number. Croaks if given an
unrecognised term. Otherwise returns a new Ucam::Term object.

=cut

sub new {

    my $class = shift;
    my ($term,$year) = @_;

    my $self = bless({}, $class);

    if ($term =~ /^m(ics(aelmas)?)?/i) {
        $term = 'm';
    }
    elsif ($term =~ /^l(ent)?/i) {
        $term = 'l';
    }
    elsif ($term =~ /^e(aster)?/i) {
        $term = 'e';
    }
    else {
        croak ("Unrecognised term: '$term'");
    }

    $self->{term} = $term;
    $self->{year} = $year;
    $self->{cache} = {};

    return $self;

}

=item * Ucam::Term->available_years()

List years with useful information

  my @years = Ucam::Term->available_years

Returns a sorted list of years for which at least some term date
information is available. Some years returned will not have dates for
all terms available (typically the first year will have only
Michaelemas defined, the last only Lent and Easter). Convenient for
iterating over all information available.

=cut

sub available_years {

    return sort keys %{FULL_TERM_START()};

}

=item * $term->name()

Extract term name

  my $name = $term->name

Return the full, human-readable name of the term represented by the
object ('Michaelmas', 'Lent', or 'Easter')

=cut

sub name {
    my $self = shift;

    return TERM_NAME->{$self->{term}};

}

=item * $term->year()

Extract term year

  my $year = $term->year

Return the year of the term represented by the object.

=cut

sub year {
    my $self = shift;

    return $self->{year};

}

=item * $term->dates()

Return the term start/end dates for the object

  my $span = $term->dates

Return a DateTime::Span representing the corresponding term. This runs
from 00:00 on the first day of term (inclusive) to 00:00 on the day
after term ends (exclusive). Returns undef unless the module has data
for this term (even though this is really only needed for Easter terms)

=cut

sub dates {
    my $self = shift;

    my $term_start = FULL_TERM_START->{$self->{year}}->{$self->{term}};
    return undef unless defined($term_start);

    # Extract from cache if available
    return $self->{cache}->{term} if $self->{cache}->{term};

    my ($start, $duration);

# "The Michaelmas Term shall begin on 1 October and shall consist of
# eighty days, ending on 19 December"
    if ($self->{term} eq 'm') {
        $start = DateTime->new(year=>$self->{year},
                               month=>OCT,
                               day=>1);
        $duration = EIGHTY_DAYS;
    }

# "The Lent Term shall begin on 5 January and shall consist of eighty
# days, ending on 25 March or in any leap year on 24 March"
    elsif ($self->{term} eq 'l') {
        $start = DateTime->new(year=>$self->{year},
                               month=>JAN,
                               day=>5);
        $duration = EIGHTY_DAYS;
    }

# "The Easter Term shall begin on 10 April and shall consist of seventy
# days ending on 18 June, provided that in any year in which Full
# Easter Term begins on or after 22 April the Easter Term shall begin
# on 17 April and end on 25 June"
    elsif ($self->{term} eq 'e') {
        if ($term_start >= 22) {
            $start = DateTime->new(year=>$self->{year},
                                   month=>APR,
                                   day=>17);
        }
        else {
            $start = DateTime->new(year=>$self->{year},
                                   month=>APR,
                                   day=>10);
        }
        $duration = SEVENTY_DAYS;
    }

    else {
        croak ('This can\'t happen - unrecognised term');
    }

    my $result = DateTime::Span->
        from_datetime_and_duration(start => $start,
                                   duration => $duration);

    # Cache the result and return it
    $self->{cache}->{term} = $result;
    return $result;

}

=item * $term->fullterm_dates()

Return the full term start/end dates for the object

   my $span = $term->fullterm_dates

Return a DateTime::Span representing the corresponding full term. This
runs from 00:00 on the first day of full term (inclusive) to 00:00 on
the day after full term ends (exclusive). Returns undef unless the
module has data for this term.

=cut

sub fullterm_dates {
    my $self = shift;

    my $term_start = FULL_TERM_START->{$self->{year}}->{$self->{term}};
    return undef unless defined($term_start);

    # Extract from cache if available
    return $self->{cache}->{fullterm} if $self->{cache}->{fullterm};

    my ($start,$duration);

# "Full Term shall consist of three-fourths of the whole term
# reckoned from the first day of Full Term as hereinafter determined"

    if ($self->{term} eq 'm') {
        $start = DateTime->new(year=>$self->{year},
                               month=>OCT,
                               day=>$term_start);
        $duration = SIXTY_DAYS;
    }

    elsif ($self->{term} eq 'l') {
        $start = DateTime->new(year=>$self->{year},
                                  month=>JAN,
                                  day=>$term_start);
        $duration = SIXTY_DAYS;
    }

    elsif ($self->{term} eq 'e') {
        $start = DateTime->new(year=>$self->{year},
                               month=>APR,
                               day=>$term_start);
        $duration = FIFTYTHREE_DAYS;
    }

    else {
        croak ('This can\'t happen - unrecognised term');
    }

    my $result = DateTime::Span->
        from_datetime_and_duration(start => $start,
                                   duration => $duration);


    # Cache the result and return it
    $self->{cache}->{fullterm} = $result;
    return $result;

}

=item * $term->division()

Returns the date of the division of term

  $division = $term->division

Returns a DateTime object representing 00:00 on the day corresponding
to the division of term.

=cut

sub division {
    my $self = shift;

    my $term_start = FULL_TERM_START->{$self->{year}}->{$self->{term}};
    return undef unless defined($term_start);

    # Extract from cache if available
    return $self->{cache}->{division} if $self->{cache}->{division};

# http://www.cam.ac.uk/univ/termdates.html: "Division of Term is
# half-way through Term (not Full Term). The dates are the same for
# every year except for Easter term: 9 November, 13 February, and 14
# May or 21 May depending on whether Easter Term starts on 10 April or
# 17 April"

    my $division;

    if ($self->{term} eq 'm') {
        $division = DateTime->new(year=>$self->{year},
                                  month=>NOV,
                                  day=>9);
    }

    elsif ($self->{term} eq 'l') {
        $division = DateTime->new(year=>$self->{year},
                                  month=>FEB,
                                  day=>13);
    }

    elsif ($self->{term} eq 'e') {
        if ($term_start >= 22) {
            $division = DateTime->new(year=>$self->{year},
                                      month=>MAY,
                                      day=>21);
        }
        else {
            $division = DateTime->new(year=>$self->{year},
                                      month=>MAY,
                                      day=>14);
        }
    }

    else {
        croak ('This can\'t happen - unrecognised term');
    }


    # Cache the result and return it
    $self->{cache}->{division} = $division;
    return $division;

}

=item * $term->general_admission()

Return the start/end dates for General Admission based on the table
that appears in Ordinances, Chapter II, Section 10 'Dates of Term and
Full Term' (see general_admission_alg() for what should be the same
data derived from the algorythm in Ordinances, Chapter II, Section 12
'Admission to Degrees')

   my $span = $term->general_admission

Return a DateTime::Span representing the period of General Admission
following an Easter term. The span runs from 00:00 on the first day of
General Admission (inclusive) to 00:00 on the day after the final day
(exclusive). Returns undef unless the module has data for this
term. Croaks if called on an object that doesn't represent an Easter
term.

=cut

sub general_admission {
    my $self = shift;

    croak "Can only call general_admission() on an Easter term object"
        unless $self->{term} eq 'e';

    my $term_start = FULL_TERM_START->{$self->{year}}->{$self->{term}};
    return undef unless defined($term_start);

    # Extract from cache if available
    return $self->{cache}->{ga} if $self->{cache}->{ga};

    # General admission can fall in June or July
    my $dayone = FULL_TERM_START->{$self->{year}}->{'g'};
    my $month = $dayone > 15 ? JUN : JUL;
    my $start = DateTime->new(year=>$self->{year}, 
                              month=>$month, 
                              day=>$dayone);

    # Upto 2013, GA was three day, from 2014 it's 4 dayss
    my $duration = $self->{year} <= 2013 ? THREE_DAYS : FOUR_DAYS;

    my $ga = DateTime::Span->
        from_datetime_and_duration(start => $start,
                                   duration => $duration);
    # Cache the result and return it
    $self->{cache}->{ga} = $ga;
    return $ga;

}

=item * $term->general_admission_alg()

Return the start/end dates for General Admission based on the
algorythm that appears in Ordinances, Chapter II, Section 12
'Admission to Degrees' (see general_admission() for what should be the
same data derived from the algorythm in Ordinances, Chapter II,
Section 10 'Dates of Trem and Full Term' )

   my $span = $term->general_admission_alg

Return a DateTime::Span representing the period of General Admission
following an Easter term. The span runs from 00:00 on the first day of
General Admission (inclusive) to 00:00 on the day after the final day
(exclusive). Returns undef unless the module has data for this
term. Croaks if called on an object that doesn't represent an Easter
term.

=cut

sub general_admission_alg {
    my $self = shift;

    croak "Can only call general_admission() on an Easter term object"
        unless $self->{term} eq 'e';

    my $term_start = FULL_TERM_START->{$self->{year}}->{$self->{term}};
    return undef unless defined($term_start);

    # Extract from cache if available
    return $self->{cache}->{ga_alg} if $self->{cache}->{ga_alg};
    
# In Ordnances upto the set published in 2013 the rule was:   
#
# "In every year the Thursday, Friday, and Saturday after the third
# Sunday in June shall be days of General Admission to Degrees, save
# that, in accordance with Regulation 3 for Terms and Long Vacation,
# in any year in which Full Easter Term begins on or after 22 April
# the days of General Admission shall be the Thursday, Friday, and
# Saturday after the fourth Sunday in June"
#
# adding "Wednesday" in 2013 itself. However this didn't actually
# produce the dates published (since 2010) elsewhere in Ordnances.
# To fix this the rule was changed from the 2014 edition onnward by
# Grace 2 of 5 February 2014 to be:  
#
# "Every year the Wednesday, Thursday, Friday, and Saturday in the
# week next but one following the last week of Full Easter Term shall
# be days of General Admission to Degrees."
#
# Conviniently this produces the same dates as the old algorythm
# (when adjusted for the inclusion of Wednesday only from 2013) for
# all years supported by this module.

    # Saturday after the last day of Full Easter Term
    my $start = $self->fullterm_dates->end;

    # Move to the week next but one
    $start->add (weeks => 2);
    
    # Thursday or Wednesday and three or four days 
    my $duration;
    if ($self->year <= 2013) {
	$start->subtract (days => 2);
	$duration = THREE_DAYS;
    }
    else {
	$start->subtract (days => 3);
	$duration = FOUR_DAYS;
    }

    my $ga = DateTime::Span->
        from_datetime_and_duration(start => $start,
                                   duration => $duration);
    # Cache the result and return it
    $self->{cache}->{ga_alg} = $ga;
    return $ga;

}

=item * $term->long_vac()

Return the start/end dates for the 'Long Vacation period of residence'

   my $span = $term->long_vac

Return a DateTime::Span representing the period of the 'Long Vacation
period of residence' that follows an Easter term. The span runs from
00:00 on the first day (inclusive) to 00:00 on the day after the final
day (exclusive). Returns undef unless the module has data for this
term. Croaks if called on an object that doesn't represent an Easter
term.

=cut

sub long_vac {
    my $self = shift;

    croak "Can only call long_vac() on an Easter term object"
        unless $self->{term} eq 'e';

    my $ga = $self->general_admission;
    return undef unless defined($ga);

    # Extract from cache if available
    return $self->{cache}->{lv} if $self->{cache}->{lv};

# "A course of instruction given during the Long Vacation shall not
# occupy more than four weeks.  Except with the approval of the
# Council on the recommendation of the General Board, no such course
# given within the Precincts of the University shall begin earlier
# than the second Monday after General Admission or end later than the
# sixth Saturday after the Saturday of General Admission"

    # "second Monday after General Admission" is 1 week
    # and 1 day after the last 'day' (Sunday) of General
    # Admission
    my $start = $ga->end->clone->add(days => 1, weeks => 1);
    # "sixth Saturday after the Saturday of General
    # Admission" is 6 weeks less 1 day after the first 'day'
    # (Sunday) of General Admission. Plus one to the next day
    my $end = $ga->end->clone->add(weeks => 6);

    my $lv = DateTime::Span->from_datetimes(start => $start, before => $end );

    # Cache the result and return it
    $self->{cache}->{lv} = $lv;
    return $lv;

}

=back

=head1 AUTHOR

Jon Warbrick, jw35@cam.ac.uk.

=head1 SEE ALSO

University of Cambridge Statutes and Ordnances, Chapter II
("Matriculation, Residence, Admission to Degrees")
(L<http://www.admin.cam.ac.uk/univ/so/>) contains most of the rules
implemented by this module:

=over 4

"Section 10: DATES OF TERM AND FULL TERM"

"1. The Michaelmas Term shall begin on 1 October and shall consist of
eighty days, ending on 19 December. The Lent Term shall begin on 5
January and shall consist of eighty days, ending on 25 March or in any
leap year on 24 March. The Easter Term shall begin on 10 April and
shall consist of seventy days ending on 18 June, provided that in any
year in which Full Easter Term begins on or after 22 April the Easter
Term shall begin on 17 April and end on 25 June.

"2. Full Term shall consist of three-fourths of the whole term
reckoned from the first day of Full Term as hereinafter determined.

"3. The dates on which Full Terms begin and end shall be as shown in
the table appended to these regulations.

"...

"8. A course of instruction given during the Long Vacation shall not
occupy more than four weeks.  Except with the approval of the Council
on the recommendation of the General Board, no such course given
within the Precincts of the University shall begin earlier than the
second Monday after General Admission or end later than the sixth
Saturday after the Saturday of General Admission."

"Section 12: ADMISSION TO DEGREES"

[Prior to 2013]:

"13. In every year the Thursday, Friday, and Saturday after the third
Sunday in June shall be days of General Admission to Degrees, save
that, in accordance with Regulation 3 for Terms and Long Vacation, in
any year in which Full Easter Term begins on or after 22 April the
days of General Admission shall be the Thursday, Friday, and Saturday
after the fourth Sunday in June. On each day of General Admission
there shall be one or more Congregations for General Admission to
Degrees at such hours as the Vice-Chancellor shall appoint."

[As ammended by Grace 1 of 13 February 2013 
(http://www.admin.cam.ac.uk/reporter/2012-13/weekly/6297/section6.shtml)
with effect from 1 October 2013]:

"13. Every year the Wednesday, Thursday, Friday, and Saturday after the
third Sunday in June shall be days of General Admission to Degrees,
save that, in accordance to Regulation 3 for Terms and Long Vacation,
in any year in which Full Easter Term begins on or after 22 April the
days of General Admission shall be the Wednesday, Thursday, Friday,
and Saturday after the fourth Sunday in June. On each day of General
Admission there shall be one or more Congregations for General
Admission to Degrees at such hours as the Vice-Chancellor shall
appoint."

[As ammended by Grace 2 of 5 February 2014
(http://www.admin.cam.ac.uk/reporter/2013-14/weekly/6336/section8.shtml)]

"14. Every year the Wednesday, Thursday, Friday, and Saturday in the
week next but one following the last week of Full Easter Term shall be
days of General Admission to Degrees."

[In practice, the dates of General Admission as given in the table in
Section 10: 'Dates of Term and Full Term' appear to be cannonical -
between 2010 and 2014 the dates in the table and the ordnance diagreed
and it was the ordanance that was updated]

=back

Division of Term is best described in
L<http://www.cam.ac.uk/univ/termdates.html>:

=over 4

"Division of Term is half-way through Term (not Full Term). The dates
are the same for every year except for Easter term: 9 November, 13
February, and 14 May or 21 May depending on whether Easter Term starts
on 10 April or 17 April."

=back

See also L<DateTime>, L<DateTime::Span>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2010, 2013, 2017 University of Cambridge Information
Services. This program is free software; you can distribute it and/or
modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.
