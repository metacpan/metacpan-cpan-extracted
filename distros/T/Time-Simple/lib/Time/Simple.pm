package Time::Simple;

use 5.008003;
our $VERSION = '0.06';
our $FATALS  = 1;

=head1 NAME

Time::Simple - A simple, light-weight ISO 8601 time object.

=head1 SYNOPSIS

	use Time::Simple;
	my $time   = Time::Simple->new('23:24:59');
	my $hour   = $time->hours;
	my $minute = $time->minutes;
	my $second = $time->seconds;

	my $time2  = Time::Simple->new($hour, $minute, $second);

	my $now = Time::Simple->new;
	my $nexthour = $now + (60*60);
	print "An hour from now is $nexthour.\n";

	if ($nexthour->hour > 23) {
		print "It'll be tomorrow within the next hour!\n";
	}

	# You can also do this:
	($time cmp "23:24:25")
	# ...and this:
	($time <=> [23, 24, 25])

	$time++; # Add a second
	$time--; # Subtract a second

	# Seconds of difference:
	$seconds = Time::Simple->new("00:00:02")
	         - Time::Simple->new("00:00:01");

	my $now  = Time::Simple->new;
	# A minute from now:
	my $then = Time::Simple->new( $now + 60 );
	# Or:
	my $soon = Time::Simple->new( '00:01:00' );

=head1 DESCRIPTION

A simple, light-weight time object.

B<This version should be considered an alpha developer release>.

How do you think this moudle should handle return values of multiplacation, where the
return value would be greater than 23:59:59?

=head2 FATAL ERRORS

Attempting to create an invalid time with this module will return C<undef> rather than an object.

Some operations can produce fatal errors: these can be replaced by warnings and the
return of C<undef> by switching the value of C<$FATALS>:

	$Time::Simple::FATALS = undef;

You will then only get warnings to C<STDERR>, and even then only if you asked perl for
warnings with C<use warnings> or by setting C<$^W> either directly or with the C<-w>
command-line switch.

=head2 EXPORT

None by default.

=cut

use strict;
use warnings;
use Carp;
use POSIX qw(strftime mktime);

use overload
	'='	  => '_copy',
    '+='  => '_increment',
	'++'  => '_increment_mod',
    '-='  => '_decrement',
    '--'  => '_decrement_mod',
    '+'   => '_add',
    '-'   => '_subtract',
    '<=>' => '_compare',
    'cmp' => '_compare',
    '""'  => '_stringify',
    '*'	  => '_multiply',
    '/'   => '_divide',
    # fallback=>1
;

=head1 METHODS

=cut

# http://rt.cpan.org/Public/Bug/Display.html?id=34710 :-
# 	Log: Make the isdst argument to asctime and mktime default to -1
# 	instead of 0, as suggested by Mike Schilli.
# 	Branch: perl
# 	! ext/POSIX/POSIX.pm ext/POSIX/POSIX.pod ext/POSIX/POSIX.xs
my $DST = $^V lt v5.10.0? 0 : 0;

=head2 CONSTRUCTOR (new)

    $_ = Time::Simple->new('21:10:09');
    $_ = Time::Simple->new( 11,10, 9 );
    Time::Simple->new() == Time::Simple->new( time() );

The constructor C<new> returns a C<Time::Simple> object if the supplied
values specify a valid time, otherwise returns C<undef>.

Valid times are either as supplied by the L<time|perlfunc/time>, or in ISO 8601
format. In the latter case, the values may be supplied as a colon-delimited scalar,
as a list, or as an anonymous array.

If nothing is supplied to the constructor, the current local time will be used.

=cut

sub new {
    my ($that, @hms) = (@_);
    my $time;

    my $class = ref($that) || $that;

	# From time()
	if (scalar(@hms) and
		($hms[0] =~ /^\d{10}$/g or scalar(@hms) == 10 or scalar(@hms) == 9)
	) {
		$time = join'',@hms;
		if ($time =~ /\D/g){
			if ($FATALS){
				croak "Could not make a time from $time - please read the documentation";
			} else {
				Carp::cluck("Could not make a time from $time - please read the documentation") if $^W;
				return undef;
			}
		}
	}

	elsif (@hms == 1) {
        if(ref $hms[0] eq 'ARRAY') {
            @hms = join':',@{$hms[0]};
		}
		@hms = $hms[0] =~ /^(\d{1,2})(:\d{1,2})?(:\d{1,2})?$/;
		$hms[1] ||= '00';
		$hms[2] ||= '00';
		s/^:// foreach @hms[1..2];
		if (not defined $hms[0]){
			if ($FATALS){
				croak"'$_[1]' is not a valid ISO 8601 formated time" ;
			} else {
				Carp::cluck("'$_[1]' is not a valid ISO 8601 formated time") if $^W;
				return undef;
			}
        }
    }

	if (not defined $time){
		if (@hms == 3) {
			unless (validate(@hms)){
				if ($FATALS){
					croak "Could not make a time - please read the documentation";
				} else {
					Carp::cluck("Could not make a time - please read the documentation") if $^W;
					return undef;
				}
			}

			# mktime(sec, min, hour, mday, mon, year, wday = 0, yday = 0, isdst = 0/-1)
			my @localtime = localtime;
			$time = mktime (
				$hms[2],
				$hms[1],
				$hms[0]   - ($localtime[8]? 1 : 0),	# Daylight saving time xxx
				$localtime[3],
				$localtime[4],
				$localtime[5],
				0,0,
				$localtime[8]? $DST : 0
			);
			confess 'Can not mktime' if not $time;
		}

		elsif (@hms == 0) {
			$time = time;
		}

		elsif ($FATALS){
			croak "Could not make a time - please read the documentation";
		}

		else {
			Carp::cluck("Could not make a time - please read the documentation") if $^W;
			return undef;
		}
	}
    return bless \$time, $class;
}

sub next { return $_[0] + 1 }
sub prev { return $_[0] - 1 }

sub _mktime_seconds($) {
	my $t = shift;
	my $h = int( $t / (60*60));
	my $m = int(($t % (60*60)) / 60);
	my $s = int( $t % (60));
	return $h, $m, $s;
}

# Return the number of seoncds in time
sub total_seconds($){
	my $self = shift;
	my ($sh, $sm, $ss) = $self =~ /^0?(\d+?).0?(\d+?).0?(\d+?)$/;
    $ss += ($sm * 60) + ($sh * 60 * 60);
}

sub hour    { return (localtime ${$_[0]})[2] }
sub hours   { return (localtime ${$_[0]})[2] }

sub minute  { return (localtime ${$_[0]})[1] }
sub minutes { return (localtime ${$_[0]})[1] }

sub second  { return (localtime ${$_[0]})[0] }
sub seconds { return (localtime ${$_[0]})[0] }

sub format {
    my $self = shift;
    my $format = shift || '%H:%M:%S';
	# strftime(fmt, sec, min, hour, mday, mon, year, wday = -1, yday = -1, isdst = -1)
    my $test;
    eval { $test = scalar localtime $$self };
    Carp::confess("Invalid time ($$self)") unless defined $test;
    my $return = eval {strftime($format, localtime($$self));};
    Carp::confess "You supplied $$self: ".$@ if $@;
    return $return;
}

sub validate ($$$) {
    my ($h, $m, $s)= @_;
	foreach my $i (@_){
		return 0 if $i != abs int $i or $i < 0;
	}
    return 0 if $h > 23
    		 or $m > 59
    		 or $s > 59;
	return 1;
}


#------------------------------------------------------------------------------
# the following methods are called by the overloaded operators, so they should
# not normally be called directly.
#------------------------------------------------------------------------------
sub _stringify { $_[0]->format }

sub _copy {
    my $self = shift;
	my $v = $$self;
    my $copy = \$v;
    bless $copy, ref $self;
    return $copy;
}

sub _increment {
    my ($self, $n) = @_;
    if (UNIVERSAL::isa($n, ref($self))) {
		$n = $$n;
	}
	my $copy = $self->_copy;
    $$copy+= $n;
    return $copy;
}

sub _increment_mod {
    my ($self, $n) = @_;
    $n = $$n if UNIVERSAL::isa($n, ref($self));
	$$self ++;
    return $self;
}

sub _decrement {
    my ($self, $n, $reverse) = @_;
    $n = $$n if UNIVERSAL::isa($n, ref($self));
	my $copy = $self->_copy;
    $$copy -= $n;
    return $copy;
}

sub _decrement_mod {
    my ($self, $n, $reverse) = @_;
    $n = $$n if UNIVERSAL::isa($n, ref($self));
	$$self --;
	return $self;
}

sub _add {
    my ($self, $n, $reverse) = @_;
    if (UNIVERSAL::isa($n, ref($self))) {
		my $s = ($n->hour * 60 * 60)
			+ ($n->minute * 60)
			+ $n->seconds;
		$n = $s;
    }
	my $copy = $self->_copy;
	$$copy += $n;
	return $copy;
}

sub _subtract {
    my ($self, $n, $reverse) = @_;
    if (UNIVERSAL::isa($n, ref($self))) {
        my $copy = $self->_copy;
        my $diff = $$copy - $$n;
        # $diff /= 86400;
        # $reverse should probably always be false here, but...
		$diff = -$diff if $diff < 0;
        return $reverse ? -$diff : $diff;
    } else {
        my $copy = $self->_copy;
        $$copy -= $n;
        return $copy;
    }
}

sub _compare {
    my ($self, $x, $reverse) = @_;
    $x = ref($self)->new($x) unless UNIVERSAL::isa($x, ref($self));
    my $c = (int(${$self}) <=> int(${$x}));
    return $reverse ? -$c : $c;
}



sub _multiply {
    my ($self, $n, $reverse) = @_;

    if (UNIVERSAL::isa($n, ref($self))) {
		Carp::cluck "Cannot multiply a time by a time, only a time by a number.";
	}

	# Convert time to seconds
	my $ss = $self->total_seconds;
	$ss *= $n;
	my @hms = _mktime_seconds($ss);
	return ref($self)->new( @hms );
}

sub _divide {
    my ($self, $n, $reverse) = @_;

    if (UNIVERSAL::isa($n, ref($self) )) {
		Carp::cluck "Cannot multiply a time by a time, only a time by a number.";
	}

	# Convert time to seconds
	my $ss = $self->total_seconds;
	my $return = $ss /= $n;

	# Convert return value to time
	my @hms = _mktime_seconds($return);
	return ref($self)->new( @hms );
}

1;

__END__


=head1 INSTANCE METHODS

=head2 METHOD next

    my $will_be_by_one_second = $now->next;

Returns the next time by incrementing the caller's time by one second.

=head2 METHOD prev

    my $was_by_one_second = $now->prev;

Returns the last time by decrementing the caller's time by one second.

=head2 METHOD hour

    my $hr = $time->hour;

The hour. Alias: C<hours>.

=head2 METHOD minute

    my $min = $time->minute;

The minutes. Alias: C<minutes>.

=head2 METHOD second

    my $sec = $time->second;

The seconds. Alias: C<seconds>.

=head2 format

Returns a string representing the time, in the format specified.
If you don't pass a parameter, an ISO 8601 formatted time is returned.

    $date->format;
    $date->format("%H hours, %M minutes, and %S seconds");
    $date->format("%H-%M-%S");

The formatting parameter is as you would pass to C<strftime(3)>:
L<POSIX/strftime>.

=head1 OPERATORS

Some operators can be used with C<Time::Simple> objects:

=over 4

=item += -=

You can increment or decrement a time by a number of seconds using the
C<+=> and C<-=> operators

=item + -

You can construct new times offset by a number of seconds using the
C<+> and C<-> operators.

=item -

You can subtract two times (C<$t1 - $t2>) to find the number of seconds between them.

=item comparison

You can compare two times using the arithmetic and/or string comparison operators:
C<lt le ge gt E<lt> E<lt>= E<gt>= E<gt>>.

=item ""

You can interpolate a time instance directly into a string, in the format
specified by ISO 8601 (eg: 23:24:25).

=item *

You can multiply a time by a number: C<00:00:30 * 2 = 00:01:00>.

=item /

You can divide a time by a number: C<00:02:00 * 2 = 00:01:00>.


=back

=head2 DIAGNOSTICS

=item C<Illegal octal digit ....>

You probably used an anonymous array and prefixed a number with a leading zero, as you would
if you supplied a scalar string: C<[11,10,09]>.

=head1 TODO

Suggestions welcome. How should operators not mentioend behave? Can one C<verbar> times?

=head1 SEE ALSO

L<Time::HiRes>, L<Date::Time>,
L<Date::Simple>,
L<perlfunc/localtime>,
L<perlfunc/time>.
L<POSIX/strftime>, L<POSIX/mktime>.

=head1 LATEST CHANGES

Version 0.05 Sun 02 July 16:52 2006 - Added multiply and division

=head1 CREDITS

This module is a rewrite of Marty Pauley's excellent and very useful C<Date::Simple>
object. If you're reading, Marty: many thanks. For support, though, please contact
Lee Goddard (lgoddard -at- cpan -dot- org) or use rt.cpan.org.

Thanks to Zsolt for testing, and 'Agent' for the patch.

=head1 AUTHOR

Lee Goddard (lgoddard -at- cpan -dot- org) after Marty Pauley.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Lee Goddard. Parts Copyright (C) 2001, I<Kasei>.

This program is free software; you can redistribute it and/or modify it
under the terms of either:
a) the GNU General Public License;
 either version 2 of the License, or (at your option) any later version.
b) the Perl Artistic License.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.


