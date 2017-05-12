# vim: set sw=2 sts=2 ts=2 expandtab smarttab:
#
# This file is part of Time-Stamp
#
# This software is copyright (c) 2011 by Randy Stauner.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package Time::Stamp;
{
  $Time::Stamp::VERSION = '1.300';
}
# git description: v1.200-5-gd4b4217

BEGIN {
  $Time::Stamp::AUTHORITY = 'cpan:RWSTAUNER';
}
# ABSTRACT: Easy, readable, efficient timestamp functions

# TODO: use collector?

use Sub::Exporter 0.982 -setup => {
  -as => 'do_import',
  exports => [
    localstamp => \'_build_localstamp',
    gmstamp    => \'_build_gmstamp',
    parsegm    => \'_build_parsestamp',
    parselocal => \'_build_parsestamp',
  ],
  groups => [
    stamps => [qw(localstamp gmstamp)],
    parsers => [qw(parselocal parsegm)],
  ]
};

sub import {
  @_ = map {
    /(local|gm)(?:stamp)?((?:-\w+)+)/
    ? ($1.'stamp' => {
        map  {
          /^([um]s)$/ ? ($1 => 1)
            : (format => $_)
        }
        grep { $_ }
          split(/-/, $2)
      })
    : $_
  } @_;
  goto &do_import;
}

# set up named formats with default values
my $formats = do {
  # should we offer { prefix => '', suffix => '' } ? is that really useful?
  # the stamps are easy enough to parse as is (the whole point of this module)
  my %default = (
    date_sep => '-',
    dt_sep   => 'T', # ISO 8601
    time_sep => ':',
    tz_sep   => '',
    tz       => '',
  );
  my %blank = map { $_ => '' } keys %default;
  my $n = {
    default  => {%default},
    easy     => {%default, dt_sep => ' ', tz_sep => ' '}, # easier to read
    numeric  => {%blank},
    compact  => {
      %blank,
      dt_sep   => '_', # visual separation
    },
  };
  # aliases
  $n->{$_} = $n->{default} for qw(iso8601 rfc3339 w3cdtf);
  $n;
};

# we could offer a separate format_time_array() but currently
# I think the gain would be less than the cost of the extra function call:
# sub _build { return sub { format_time_array($arg, @_ or localtime) }; }
# sub format_time_array { sprintf(_format(shift), _ymdhms(@_)) }

sub _build_localstamp {
##my ( $class, $name, $arg, $col ) = @_;
  my ( undef, undef, $arg, undef ) = @_;

  return _generate_code(local => $arg);
}

sub _build_gmstamp {
##my ( $class, $name, $arg, $col ) = @_;
  my ( undef, undef, $arg, undef ) = @_;

  # add the Z for UTC (Zulu) time zone unless the numeric format is requested
  $arg = {tz => 'Z', %$arg}
    unless $arg->{format} && $arg->{format} eq 'numeric';

  return _generate_code(gm => $arg);
}

# TODO: could these subs be faster with a no_args option? would only save 2 if's
sub _generate_code {
  my ($which, $arg) = @_;
  $arg = { %$arg };
  # note: mu is 03BC
  $arg->{frac} ||= $arg->{us} ? 6 : $arg->{ms} ? 3 : 0;

  my $format = _format($arg);

  my $code;
  my $vars = {
    which => $which,
  };
  if( $arg->{frac} ){
    $vars->{frac} = $arg->{frac};
    # always display a fraction if requested
    $vars->{gettime} = _have_hires()
      # gettimeofday() returns microseconds, so we need six digits to stringify
      # which means we need a sprintf somewhere
      ? 'do { my @t = Time::HiRes::gettimeofday(); $t[1] = sprintf "%06d", $t[1]; @t }'
      # if HiRes fails to load use whole number precision
      : '(time(), 0)';

    $code = <<'CODE';
      sub {
        # localtime() will not preserve the fraction, so separate it
        my ($t, $f) = @_ ? (split(/\./, $_[0]), 0) : {{gettime}};

        my @lt = _ymdhms(@_ > 1 ? @_ : {{which}}time($t));

        # use %.6f for precision, but strip leading zero
        return sprintf($format, @lt, substr(sprintf('%.{{frac}}f', '.'.$f), 1));
      };
CODE
  }
  # if not using fraction return a more efficient sub
  else {
    $code = <<'CODE';
      sub {
        return sprintf($format,
          _ymdhms(@_ > 1 ? @_ : {{which}}time(@_ ? $_[0] : time))
        );
      };
CODE
  }
  # poor man's template (easier than sprintf or escaping sigils)
  $code =~ s/\{\{(\w+)\}\}/$vars->{$1}/g;

  return do { eval $code or die $@ }; ## no critic (StringyEval)
}

sub _build_parsestamp {
##my ($class, $name, $arg, $col) = @_;
  my ( undef, $name, $arg, undef ) = @_;

  # pre-compile the regexp
  my $regexp = exists $arg->{regexp}
    ? qr/$arg->{regexp}/
    : qr/^ (\d{4}) \D* (\d{2}) \D* (\d{2}) \D*
           (\d{2}) \D* (\d{2}) \D* (\d{2}) (?:\.(\d+))? .* $/x;

  require Time::Local; # core
  my $time = $name eq 'parsegm'
    ? \&Time::Local::timegm
    : \&Time::Local::timelocal;

  return sub {
    my ($stamp) = @_;
    my ($frac, @time) = reverse ($stamp =~ $regexp);

    # if the regexp didn't match (empty list) give up now
    return
      if !@time;

    # regexp didn't have 7th capture group (for fraction)
    if( @time < 6 ){
      unshift @time, $frac;
      # if there was a fraction in group 6 separate it
      # or timelocal may produce something unexpected.
      # if there was no fraction $frac will be undef
      ($time[0], $frac) = split(/\./, $time[0]);
    }

    # coerce strings into numbers (map { int } would not work for fractions)
    @time = map { $_ + 0 } @time;

    $time[5] -= 1900; # year
    $time[4] -= 1;    # month

    # make sure it starts with a dot (whether it has one or not)
    $frac =~ s/^0?\.?/./
      if defined $frac;

    if( wantarray ){
      $time[0] .= $frac
        if defined $frac;
      return @time;
    }
    else {
      my $ts = &$time(@time);
      $ts .= $frac
        if defined $frac;
      return $ts;
    }
  };
}

sub _format {
  my ($arg) = @_;

  my $name = $arg->{format} || ''; # avoid undef
  # we could return $arg->{format} unless exists $formats->{$name}; warn if no % found?
  # or just return $arg->{sprintf} if exists $arg->{sprintf};
  $name = 'default'
    unless exists $formats->{$name};

  # start with named format, overwrite with any explicitly specified options
  my %opt = (%{ $formats->{$name} }, %$arg);

  # TODO: $opt{tz} = tz_offset() if $opt{guess_tz};

  # sadly "%02.6f" does not zero-pad the integer portion, so we have to be trickier

  return
    join($opt{date_sep}, qw(%04d %02d %02d)) .
    $opt{dt_sep} .
    join($opt{time_sep}, qw(%02d %02d %02d)) .
    ($opt{frac} ? '%s' : '') .
    ($opt{tz} ? $opt{tz_sep} . $opt{tz} : '')
  ;
}

# convert *time() arrays to something ready to send to sprintf
sub _ymdhms {
  return ($_[5] + 1900, $_[4] + 1, @_[3, 2, 1, 0]);
}

my $_have_hires;
sub _have_hires {
  if( !defined($_have_hires) ){
    local $@;
    $_have_hires = eval { require Time::HiRes; 1 } || do {
      warn "Time::HiRes requested but failed to load: $@";
      0;
    };
  }
  return $_have_hires;
}

# define default localstamp and gmstamp in this package
# so that exporting is not strictly required
__PACKAGE__->import(qw(
  localstamp
  gmstamp
  parsegm
  parselocal
));

1;

__END__

=pod

=encoding utf-8

=for :stopwords Randy Stauner ACKNOWLEDGEMENTS TODO timestamp gmstamp localstamp UTC
parsegm parselocal 6th 7th cpan testmatrix url annocpan anno bugtracker rt
cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 NAME

Time::Stamp - Easy, readable, efficient timestamp functions

=head1 VERSION

version 1.300

=head1 SYNOPSIS

  # import customized functions to make easy-to-use timestamps

  use Time::Stamp 'gmstamp';
  my $now = gmstamp();
  my $mtime = gmstamp( (stat($file))[9] );
    # $mtime is something like "2012-05-18T10:52:32Z"


  use Time::Stamp localstamp => { -as => 'ltime', format => 'compact' };
    # ltime() will return something like "20120518_105232"

  use Time::Stamp -stamps => { dt_sep => ' ', date_sep => '/', us => 1 };
    # localstamp() will return something like "2012/05/18 10:52:32.123456"


  # inverse functions to parse the stamps

  use Time::Stamp 'parsegm';
  my $seconds = parsegm($stamp);

  use Time::Stamp parselocal => { -as => 'parsel', regexp => qr/$pattern/ };

  use Time::Stamp -parsers => { regexp => qr/$pattern/ };


  # the default configurations of each function
  # are available without importing into your namespace

  $stamp = Time::Stamp::gmstamp($time);
  $time  = Time::Stamp::parsegm($stamp);


  # use shortcuts for specifying desired format, useful for one-liners:
  qx/perl -MTime::Stamp=local-compact -E 'say localstamp'/;
  # with milliseconds:
  qx/perl -MTime::Stamp=local-compact-ms -E 'say localstamp'/;
  # with microseconds:
  qx/perl -MTime::Stamp=local-compact-us -E 'say localstamp'/;

=head1 DESCRIPTION

This module makes it easy to include timestamp functions
that are simple, easy to read, easy to parse, and fast.
For simple timestamps perl's built-in functions are all you need:
L<time|perlfunc/time>,
L<gmtime|perlfunc/gmtime> (or L<localtime|perlfunc/localtime>),
and L<sprintf|perlfunc/sprintf>...

Sometimes you desire a simple timestamp to add to a file name
or use as part of a generated data identifier.
The fastest and easiest thing to do is call L<time()|perlfunc/time>
to get a seconds-since-epoch integer.

Sometimes you get a seconds-since-epoch integer from another function
(like L<stat()|perlfunc/stat> for instance)
and maybe you want to store that in a database or send it across the network.

This integer timestamp works for these purposes,
but it's not easy to read.

If you're looking at a list of timestamps you have to fire up a perl
interpreter and copy and paste the timestamp into
L<localtime()|perlfunc/localtime> to figure out when that actually was.

You can pass the timestamp to C<scalar localtime($sec)>
(or C<scalar gmtime($sec)>)
but that doesn't sort well or parse easily,
isn't internationally friendly,
and contains characters that aren't friendly for file names or URIs
(or other places you may want to use it).

See L<perlport/Time and Date> for more discussion on useful timestamps.

For simple timestamps you can get the data you need from
L<localtime|perlfunc/localtime> and L<gmtime|perlfunc/gmtime>
without incurring the resource cost of L<DateTime>
(or any other object for that matter).

So the aim of this module is to provide simple timestamp functions
so that you can have easy-to-use, easy-to-read timestamps efficiently.

=for test_synopsis my ( $file, $pattern, $stamp, $time );

=head1 FORMAT

For reasons listed elsewhere
the timestamps are always in order from largest unit to smallest:
year, month, day, hours, minutes, seconds
and are always two digits, except the year which is always four.

The other characters of the stamp are configurable:

=over 4

=item *

C<date_sep> - Character separating date components; Default: C<'-'>

=item *

C<dt_sep>   - Character separating date and time;   Default: C<'T'>

=item *

C<time_sep> - Character separating time components; Default: C<':'>

=item *

C<tz_sep>   - Character separating time and timezone; Default: C<''>

=item *

C<tz> - Time zone designator;  Default: C<''>

=item *

C<frac> - Digits of fractional seconds to show; Default: no fraction

=item *

C<ms> - Boolean shortcut: milliseconds; If true, same as C<< frac => 3 >>

=item *

C<us> - Boolean shortcut: microseconds; If true, same as C<< frac => 6 >>

=back

The following formats are predefined:

  default => see above descriptions
  iso8601 => \%default
  rfc3339 => \%default
  w3cdtf  => \%default
    "2010-01-02T13:14:15"    # local
    "2010-01-02T13:14:15Z"   # gm

  easy    => like default but with a space as dt_sep and tz_sep (easier to read)
    "2010-01-02 13:14:15"    # local
    "2010-01-02 13:14:15 Z"  # gm

  compact => condense date and time components and set dt_sep to '_'
    "20100102_131415"        # local
    "20100102_131415Z"       # gm

  numeric => all options are '' so that only numbers remain
    "20100102131415"         # both

Currently there is no attempt to guess the time zone.
By default C<gmstamp> sets C<tz> to C<'Z'> (which you can override if desired).
If you are using C<gmstamp> (recommended for transmitting to another computer)
you don't need anything else.  If you are using C<localstamp> you are probably
keeping the timestamp on that computer (like the stamp in a log file)
and you probably aren't concerned with time zone since it isn't likely to change.

If you want to include a time zone (other than C<'Z'> for UTC)
the standards suggest using the offset value (like C<-0700> or C<+12:00>).
If you would like to determine the time zone offset you can do something like:

  use Time::Zone (); # or Time::Timezone
  use Time::Stamp localtime => { tz => Time::Zone::tz_offset() };

If, despite the recommendations, you want to use the local time zone code:

  use POSIX (); # included in perl core
  use Time::Stamp localtime => { tz => POSIX::strftime('%Z', localtime) };

These options are not included in this module since they are not recommended
and introduce unnecessary overhead (loading the aforementioned modules).

=head1 EXPORTS

This module uses L<Sub::Exporter>
to enable you to customize your timestamp function
but still create it as easily as possible.

The customizations are done at import
and stored in the custom function returned
to make the resulting function as fast as possible.

The following groups and functions are available for export
(nothing is exported by default):

=head2 -stamps

This is a convenience group for importing both L</gmstamp> and L</localstamp>.

Each timestamp export accepts any of the keys listed in L</FORMAT>
as well as C<format> which can be the name of a predefined format.

  use Time::Stamp '-stamps';
  use Time::Stamp  -stamps => { format => 'compact' };

  use Time::Stamp gmstamp => { dt_sep => ' ', tz => ' UTC' };

  use Time::Stamp localstamp => { -as => shorttime, format => 'compact' };

Each timestamp function will return a string according to the time as follows:

=over 4

=item *

If called with no arguments C<time()> (I<now>) will be used

(or L<Time::HiRes/gettimeofday> for fractional seconds).

=item *

A single argument should be an integer
(like that returned from C<time()> or C<stat()>).

If a floating point number is provided
(and fractional seconds were part of the format)
the fraction will be preserved (according to the specified precision).

B<Note>: You may want to stringify a floating point number yourself
in order to control the precision rather than be subject
to the rounding of the default stringification:

  localstamp(sprintf "%.6f", $timestamp)

See "NOTE 2" in the description of C<time()> in L<Time::HiRes>
for more information.

=item *

More than one argument is assumed to be the list returned from
C<gmtime()> or C<localtime()> which can be useful if you previously called
the function and don't want to do it again.

If the first argument (seconds) is a floating point number
(and fractional seconds were part of the format)
the fraction will be preserved (according to the specified precision).

=back

Most commonly the 0 or 1 argument form would be used,
but the shortcut of using a time array is provided
in case you already have the array so that you don't have to use
L<Time::Local> just to get the integer back.

=head2 gmstamp

  $stamp = gmstamp(); # equivalent to gmstamp(time())
  $stamp = gmstamp($seconds);
  $stamp = gmstamp(@gmtime);

This returns a string according to the format specified in the import call.

By default this function sets C<tz> to C<'Z'>
since C<gmtime()> returns values in C<UTC> (no time zone offset).

This is the recommended stamp as it is by default unambiguous
and useful for transmitting to another computer.

=head2 localstamp

  $stamp = localstamp(); # equivalent to localstamp(time())
  $stamp = localstamp($seconds);
  $stamp = localstamp(@localtime);

This returns a string according to the format specified in the import call.

By default this function does not include a time zone indicator.

This function can be useful for log files or other values that stay
on the machine where time zone is not important and/or is constant.

=head2 -parsers

This is a convenience group for importing both L</parsegm> and L</parselocal>.

  use Time::Stamp '-parsers';
  use Time::Stamp  -parsers => { regexp => qr/pattern/ };

  use Time::Stamp 'parsegm';

  use Time::Stamp  parselocal => { -as => 'parsestamp', regexp => qr/pattern/ };

The parser functions are the inverse of the stamp functions.
They accept a timestamp and use the appropriate function from L<Time::Local>
to turn it back into a seconds-since-epoch integer.

In list context they return the list that would have been sent to L<Time::Local>
which is similar to the one returned by
L<gmtime|perlfunc/gmtime> and L<localtime|perlfunc/localtime>:
seconds, minutes, hours, day, month (0-11), year (-1900).
B<NOTE> that the C<wday>, C<yday>, and C<isdst> parameters
(the last three elements returned from C<localtime> or C<gmtime>)
are not returned because they are not easily determined from the stamp.
Besides L<Time::Local> only takes the first 6 anyway.

If the stamp doesn't match the pattern
the function will return undef in scalar context
or an empty list in list context.

An alternate regular expression can be supplied as the C<regexp> parameter
during import.  The default pattern will match any of the named formats.

The pattern must capture 6 groups in the appropriate order:
year, month, day, hour, minute, second.
If you're doing something more complex you probably ought to be using
one of the modules listed in L<SEE ALSO>.

An optional 7th group can be used to capture the fractional seconds.
If only 6 groups are used, the 6th capture (seconds)
will be checked for a fraction.
The fraction will be separated from the whole number
before being passed through the L<Time::Local> functions
then appended to the result
(the number returned in scalar context,
or to the first element returned in list context)
in an attempt to provide the most expected/reliable result.

=head2 parsegm

  $seconds = parsegm($stamp);
  @gmtime  = parsegm($stamp);

This is the inverse of L</gmstamp>.
It parses a timestamp (like the ones created by this module) and uses
L<Time::Local/timegm> to turn it back into a seconds-since-epoch integer.

=head2 parselocal

  $seconds   = parselocal($stamp);
  @localtime = parselocal($stamp);

This is the inverse of L</localstamp>.
It parses a timestamp (like the ones created by this module) and uses
L<Time::Local/timelocal> to it them back into a seconds-since-epoch integer.

=head2 SHORTCUTS

There are also shortcuts available in the format of C<< type-format >>
that export the appropriate function using the named format.

For example:

=over 4

=item *

C<local-compact> exports a L</localstamp> function using the C<compact> format

=item *

C<gm-easy> exports a L</gmstamp> function using the C<easy> format

=back

This makes the module easier to use on the command line:

  perl -MTime::Stamp=local-compact -E 'say localstamp'

Rather than:

  perl -E 'use Time::Stamp localstamp => { format => "compact" }; say localstamp'

Any of the predefined formats named in L</FORMAT>
can be used in the shortcut notation.

Additionally recognized flags include:

=over 4

=item *

C<us> adds microseconds (6 digit precision): C<< local-easy-us >>

=item *

C<ms> adds milliseconds (3 digit precision): C<< gm-ms >>

=back

=head1 SEE ALSO

=over 4

=item *

L<perlport/Time and Date> - discussion on using portable, readable timestamps

=item *

L<perlfunc/localtime> - built-in function

=item *

L<perlfunc/gmtime> - built-in function

=item *

L<Timestamp::Simple> - small, less efficient, non-customizable stamp

=item *

L<Time::Piece> - object-oriented module for working with times

=item *

L<DateTime::Tiny> - object-oriented module "with as little code as possible"

=item *

L<DateTime> - large, powerful object-oriented system

=item *

L<Time::localtime> - small object-oriented/named interface to C<localtime()>

=item *

L<Time::gmtime> - small object-oriented/named interface to C<gmtime()>

=item *

L<POSIX> - large module containing standard methods including C<strftime()>

=item *

L<http://www.cl.cam.ac.uk/~mgk25/iso-time.html> - summary of C<ISO 8601>

=item *

L<http://www.w3.org/TR/NOTE-datetime> - C<W3CDTF> profile of C<ISO 8601>

=item *

L<http://www.ietf.org/rfc/rfc3339.txt> - C<RFC3339> profile of C<ISO 8601>

=back

=head1 TODO

=over 4

=item *

Allow an option for overwriting the globals
so that calling C<localtime> in scalar context will return
a stamp in the desired format.
The normal values will be returned in list context.

=back

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Time::Stamp

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Time-Stamp>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Time-Stamp>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Time-Stamp>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/T/Time-Stamp>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Time-Stamp>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Time::Stamp>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-time-stamp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Time-Stamp>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code


L<https://github.com/rwstauner/Time-Stamp>

  git clone https://github.com/rwstauner/Time-Stamp.git

=head1 AUTHOR

Randy Stauner <rwstauner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Randy Stauner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
