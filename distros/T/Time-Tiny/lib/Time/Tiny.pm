use strict;
use warnings;
package Time::Tiny;
# ABSTRACT: A time object, with as little code as possible

our $VERSION = '1.08';

use overload 'bool' => sub () { 1 };
use overload '""'   => 'as_string';
use overload 'eq'   => sub { "$_[0]" eq "$_[1]" };
use overload 'ne'   => sub { "$_[0]" ne "$_[1]" };





#####################################################################
# Constructor and Accessors

#pod =pod
#pod
#pod =method new
#pod
#pod   # Create a Time::Tiny object for midnight
#pod   my $midnight = Time::Tiny->new(
#pod       hour   => 0,
#pod       minute => 0,
#pod       second => 0,
#pod   );
#pod
#pod The C<new> constructor creates a new B<Time::Tiny> object.
#pod
#pod It takes three named parameters. C<hour> should be the hour of the day (0-23),
#pod C<minute> should be the minute of the hour (0-59), and C<second> should be
#pod the second of the minute (0-59).
#pod
#pod These are the only parameters accepted.
#pod
#pod Returns a new B<Time::Tiny> object.
#pod
#pod =cut

sub new {
	my $class = shift;
	bless { @_ }, $class;
}

#pod =pod
#pod
#pod =method now
#pod
#pod   my $current_time = Time::Tiny->now;
#pod
#pod The C<now> method creates a new date object for the current time.
#pod
#pod The time created will be based on localtime, despite the fact that
#pod the time is created in the floating time zone.
#pod
#pod This means that the time created by C<now> is somewhat lossy, but
#pod since the primary purpose of B<Time::Tiny> is for small transient
#pod time objects, and B<not> for use in calculations and comparisons,
#pod this is considered acceptable for now.
#pod
#pod Returns a new B<Time::Tiny> object.
#pod
#pod =cut

sub now {
	my @t = localtime time;
	$_[0]->new(
		hour   => $t[2],
		minute => $t[1],
		second => $t[0],
	);
}

#pod =pod
#pod
#pod =method hour
#pod
#pod The C<hour> accessor returns the hour component of the time as
#pod an integer from zero to twenty-three (0-23) in line with 24-hour
#pod time.
#pod
#pod =cut

sub hour {
	$_[0]->{hour} || 0;
}

#pod =pod
#pod
#pod =method minute
#pod
#pod The C<minute> accessor returns the minute component of the time
#pod as an integer from zero to fifty-nine (0-59).
#pod
#pod =cut

sub minute {
	$_[0]->{minute} || 0;
}

#pod =pod
#pod
#pod =method second
#pod
#pod The C<second> accessor returns the second component of the time
#pod as an integer from zero to fifty-nine (0-59).
#pod
#pod =cut

sub second {
	$_[0]->{second} || 0;
}





#####################################################################
# Type Conversion

#pod =pod
#pod
#pod =method from_string
#pod
#pod The C<from_string> method creates a new B<Time::Tiny> object from a string.
#pod
#pod The string is expected to be an "hh:mm:ss" type ISO 8601 time string.
#pod
#pod   my $almost_midnight = Time::Tiny->from_string( '23:59:59' );
#pod
#pod Returns a new B<Time::Tiny> object, or throws an exception on error.
#pod
#pod =cut

sub from_string {
	my $string = $_[1];
	unless ( defined $string and ! ref $string ) {
		require Carp;
		Carp::croak("Did not provide a string to from_string");
	}
	unless ( $string =~ /^(\d\d):(\d\d):(\d\d)$/ ) {
		require Carp;
		Carp::croak("Invalid time format (does not match ISO 8601 hh:mm:ss)");
	}
	$_[0]->new(
		hour   => $1 + 0,
		minute => $2 + 0,
		second => $3 + 0,
	);
}

#pod =pod
#pod
#pod =method as_string
#pod
#pod The C<as_string> method converts the time object to an ISO 8601
#pod time string, with separators (see example in C<from_string>).
#pod
#pod Returns a string.
#pod
#pod =cut

sub as_string {
	sprintf( "%02u:%02u:%02u",
		$_[0]->hour,
		$_[0]->minute,
		$_[0]->second,
	);
}

#pod =pod
#pod
#pod =method DateTime
#pod
#pod The C<DateTime> method is used to create a L<DateTime> object
#pod that is equivalent to the B<Time::Tiny> object, for use in
#pod conversions and calculations.
#pod
#pod As mentioned earlier, the object will be set to the 'C' locate,
#pod and the 'floating' time zone.
#pod
#pod If installed, the L<DateTime> module will be loaded automatically.
#pod
#pod Returns a L<DateTime> object, or throws an exception if L<DateTime>
#pod is not installed on the current host.
#pod
#pod =cut

sub DateTime {
	require DateTime;
	my $self = shift;
	DateTime->new(
		year      => 1970,
		month     => 1,
		day       => 1,	
		hour      => $self->hour,
		minute    => $self->minute,
		second    => $self->second,
		locale    => 'C',
		time_zone => 'floating',
		@_,
	);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Time::Tiny - A time object, with as little code as possible

=head1 VERSION

version 1.08

=head1 SYNOPSIS

  # Create a time manually
  $christmas = Time::Tiny->new(
      hour   => 10,
      minute => 45,
      second => 0,
      );
  
  # Show the current time
  $now = Time::Tiny->now;
  print "Hour   : " . $now->hour   . "\n";
  print "Minute : " . $now->minute . "\n";
  print "Second : " . $now->second . "\n";

=head1 DESCRIPTION

B<Time::Tiny> is a member of the L<DateTime::Tiny> suite of time modules.

It implements an extremely lightweight object that represents a time,
without any time data.

=head2 The Tiny Mandate

Many CPAN modules which provide the best implementation of a concept
can be very large. For some reason, this generally seems to be about
3 megabyte of ram usage to load the module.

For a lot of the situations in which these large and comprehensive
implementations exist, some people will only need a small fraction of the
functionality, or only need this functionality in an ancillary role.

The aim of the Tiny modules is to implement an alternative to the large
module that implements a subset of the functionality, using as little
code as possible.

Typically, this means a module that implements between 50% and 80% of
the features of the larger module, but using only 100 kilobytes of code,
which is about 1/30th of the larger module.

=head2 The Concept of Tiny Date and Time

Due to the inherent complexity, Date and Time is intrinsically very
difficult to implement properly.

The arguably B<only> module to implement it completely correct is
L<DateTime>. However, to implement it properly L<DateTime> is quite slow
and requires 3-4 megabytes of memory to load.

The challenge in implementing a Tiny equivalent to DateTime is to do so
without making the functionality critically flawed, and to carefully
select the subset of functionality to implement.

If you look at where the main complexity and cost exists, you will find
that it is relatively cheap to represent a date or time as an object,
but much much more expensive to modify or convert the object.

As a result, B<Time::Tiny> provides the functionality required to
represent a date as an object, to stringify the date and to parse it
back in, but does B<not> allow you to modify the dates.

The purpose of this is to allow for date object representations in
situations like log parsing and fast real-time work.

The problem with this is that having no ability to modify date limits
the usefulness greatly.

To make up for this, B<if> you have L<DateTime> installed, any
B<Time::Tiny> module can be inflated into the equivalent L<DateTime>
as needed, loading L<DateTime> on the fly if necessary.

For the purposes of date/time logic, all B<Time::Tiny> objects exist
in the "C" locale, and the "floating" time zone (although obviously in a
pure date context, the time zone largely doesn't matter).

When converting up to full L<DateTime> objects, these locale and time
zone settings will be applied (although an ability is provided to
override this).

In addition, the implementation is strictly correct and is intended to
be very easily to sub-class for specific purposes of your own.

=head1 USAGE

In general, the intent is that the API be as close as possible to the
API for L<DateTime>. Except, of course, that this module implements
less of it.

=head1 METHODS

=head2 new

  # Create a Time::Tiny object for midnight
  my $midnight = Time::Tiny->new(
      hour   => 0,
      minute => 0,
      second => 0,
  );

The C<new> constructor creates a new B<Time::Tiny> object.

It takes three named parameters. C<hour> should be the hour of the day (0-23),
C<minute> should be the minute of the hour (0-59), and C<second> should be
the second of the minute (0-59).

These are the only parameters accepted.

Returns a new B<Time::Tiny> object.

=head2 now

  my $current_time = Time::Tiny->now;

The C<now> method creates a new date object for the current time.

The time created will be based on localtime, despite the fact that
the time is created in the floating time zone.

This means that the time created by C<now> is somewhat lossy, but
since the primary purpose of B<Time::Tiny> is for small transient
time objects, and B<not> for use in calculations and comparisons,
this is considered acceptable for now.

Returns a new B<Time::Tiny> object.

=head2 hour

The C<hour> accessor returns the hour component of the time as
an integer from zero to twenty-three (0-23) in line with 24-hour
time.

=head2 minute

The C<minute> accessor returns the minute component of the time
as an integer from zero to fifty-nine (0-59).

=head2 second

The C<second> accessor returns the second component of the time
as an integer from zero to fifty-nine (0-59).

=head2 from_string

The C<from_string> method creates a new B<Time::Tiny> object from a string.

The string is expected to be an "hh:mm:ss" type ISO 8601 time string.

  my $almost_midnight = Time::Tiny->from_string( '23:59:59' );

Returns a new B<Time::Tiny> object, or throws an exception on error.

=head2 as_string

The C<as_string> method converts the time object to an ISO 8601
time string, with separators (see example in C<from_string>).

Returns a string.

=head2 DateTime

The C<DateTime> method is used to create a L<DateTime> object
that is equivalent to the B<Time::Tiny> object, for use in
conversions and calculations.

As mentioned earlier, the object will be set to the 'C' locate,
and the 'floating' time zone.

If installed, the L<DateTime> module will be loaded automatically.

Returns a L<DateTime> object, or throws an exception if L<DateTime>
is not installed on the current host.

=head1 HISTORY

This module was written by Adam Kennedy in 2006.  In 2016, David Golden
adopted it as a caretaker maintainer.

=head1 SEE ALSO

L<DateTime>, L<DateTime::Tiny>, L<Time::Tiny>, L<Config::Tiny>, L<ali.as>

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/Time-Tiny/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/Time-Tiny>

  git clone https://github.com/dagolden/Time-Tiny.git

=head1 AUTHORS

=over 4

=item *

Adam Kennedy <adamk@cpan.org>

=item *

David Golden <dagolden@cpan.org>

=back

=head1 CONTRIBUTOR

=for stopwords Tim Heaney

Tim Heaney <oylenshpeegul@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Adam Kennedy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
