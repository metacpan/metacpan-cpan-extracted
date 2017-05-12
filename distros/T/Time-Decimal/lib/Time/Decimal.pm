#! /usr/local/bin/perl

=encoding utf-8

=head1 NAME

Time::Decimal -- Handle french revolutionary ten hour days

L<I<Esperanto priskribo>|POD2::EO::Time::Decimal>



=head1 SYNOPSIS

    use Time::Decimal qw($precision h24s_h10 h24_h10 h10s_h24 h10_h24
			 transform now_h10 loop);
    $precision = 'ms';

    $dec = h24s_h10( 1234.5678 );
    $dec = h24_h10( 13, 23, 45, 345_678 );
    $bab = h10s_h24( 1234.5678 );
    $bab = h10_h24( 1, 50, 75, 345_678 );

    $dec = transform( '13:23' );
    $dec = transform( '1:23:45.345_678 pm' );
    $bab = transform( '1_50_75.345_678' );

    $dec = now_h10;
    $dec = now_h10( time + 60 );

    $precision = 's';
    loop { print "$_[0]\t" . localtime() . "\n" };

or

    perl <path>/Time/Decimal.pm [-option ...] [time ...]
    ln <path>/Time/Decimal.pm dectime
    dectime [-option ...] [time ...]



=head1 DESCRIPTION

The Babyloninan 24 hour clock is one of the last complicated vestiges of the
pre-decimal age.  The french revolution, when it created decimal measures for
everything, also invented a division of the day into ten hours of 100 minutes
and again 100 seconds each.  The nice thing is that seconds and (to a lesser
degree) minutes are roughly as long as those we know.  Hours are of course
more than twice as long.

So as to be able to automatically recognize decimal time, we use C<_> instead
of C<:> as a separator.  This character is usable in many more computer
contexts.  In Perl it is a possible separator between digits.  And that's what
it means here, because a decimal time H_MM is nothing else than a three digit
number of minutes.  The same applies to five digit numbers of seconds.

For the purpose of transformation it doesn't matter whether we see 1:30 as an
early morning time, or as a duration of one and a half hours.  Thus a time
like 84:00 or 35_00 meaning three and a half days is allowed.

=cut

package Time::Decimal;

use warnings;
use strict;

our $VERSION = 0.07;

sub FACTOR() { .86400 }		# One day has 86400 babylonian seconds.

=head2 Module Interface

Nothing is exported by default, but all of the following may be imported by
the C<use> statement:

=over

=item $precision

    ''		minutes (the default)
    's'		seconds
    'ds'	deciseconds
    'cs'	centiseconds
    'ms'	milliseconds
    'µs', 'us'	microseconds

Where the µ-sign may be in UTF-8, Latin-1, -3, -5, -7 or Latin-9.

=cut

our $precision = '';

# Format seconds in the range 0 <= $sec < $modulo as two digits plus fraction
# as mandated by $precision.  Seconds are truncated, but fractions are rounded.
# If seconds were almost $modulo, but for floating imprecision, they are incremented
# and the fraction becomes .0, which may lead to an overflow, which is why we want
# a reference to $min.  These rules are too complex to be handled by sprintf.
{
    my %fmt = qw(ds %.1f
		 cs %.2f
		 ms %.3f
		 µs %f
		 us %f);
    $fmt{"\xb5s"} = '%f';	# Latin-[13579] µ
    sub _seconds(\$$$) {
	my( $minref, $modulo, $sec ) = @_;
	if( $precision ) {
	    if( $precision eq 's' ) {
		my $usec = $sec - int $sec;
		$sec = int $sec;
		if( $usec > .999_999 && ++$sec == $modulo ) {  # Compensate float fuzzyness.
		    $sec = 0;
		    $$minref++;
		}
	    } else {
		$sec = sprintf $fmt{$precision}, $sec;
		if( $sec == $modulo ) {  # Rounding overflowed.
		    $sec = sprintf $fmt{$precision}, 0;
		    $$minref++;
		}
		substr( $sec, -3, 0 ) = '_'
		    if $precision eq 'µs' || $precision eq 'us';
	    }
	    $sec = "0$sec" if eval $sec < 10; # eval understands '_'
	    $sec;
	} else {
	    $$minref++ if sprintf( '%f', $sec ) == $modulo;
	    '';
	}
    }
}


sub h10s_h10($) {
    my $sec = $_[0];
    my $min = int $sec / 100;
    $sec = _seconds $min, 100, $sec - 100 * $min;
    $min = sprintf "%d_%02d", $min / 100, $min % 100;
    $min .= "_$sec" if $precision;
    $min;
}

sub h24s_h10($) {
    h10s_h10 $_[0] / FACTOR;
}

sub h24_h10(@) {
    my( $h, $min, $sec, $usec ) = (@_, 0, 0, 0, 0);
    h24s_h10 $h * 3600 + $min * 60 + $sec + .000_001 * $usec;
}


sub h10s_h24($) {
    my $sec = $_[0] * FACTOR;
    my $min = int $sec / 60;
    $sec = _seconds $min, 60, $sec - 60 * $min;
    $min = sprintf "%02d:%02d", $min / 60, $min % 60;
    $min .= ":$sec" if $precision;
    $min;
}

sub h10_h24(@) {
    my( $h, $min, $sec, $usec ) = (@_, 0, 0, 0, 0);
    h10s_h24 $h * 10000 + $min * 100 + $sec + .000_001 * $usec;
}


# Perl is fussy about what strings it accepts as a number.  We allow both
# leading zeroes(not as octal) and underscores, which Perl's @#!% string to
# number automatism refuses to accept, unlike in literal numbers.
sub _cleanup($) {
    if ( $_[0] ) {
	for ( my $copy = $_[0] ) {
	    tr/_//d;
	    s/^0+(?=.)//;
	    return $_ + 0;
	}
    } else {
	'00';
    }
}

my $h10re = qr/^(\d+) _ (\d\d) (?: _ (\d\d (?: \.\d+_?\d* )?) )?$/x;
sub transform($) {
    if( $_[0] =~ /^(\d+) : ([0-5]\d) (?: : ([0-5]\d (?: \.\d+_?\d* )?) )? \s*(?:(am)|(pm))? $/ix ) {
	h24_h10 $4 ? $1 % 12 : $5 ? $1 % 12 + 12 : $1, $2, _cleanup $3;
    } elsif( $_[0] =~ /$h10re/o ) {
	h10_h24 $1, $2, _cleanup $3;
    } else {
	die "$0: invalid time format `$_[0]'\n";
    }
}

sub h10_h10s($) {
    $_[0] =~ /$h10re/o;
    0 + ($1 . $2 . _cleanup $3);
}

sub difference(@) {
    my $acc;
    for( @_ ) {
	my $sec = h10_h10s( /:/ ? transform $_ : $_ );
	if( defined $acc ) {
	    $acc -= $sec;
	} else {
	    $acc = $sec;
	}
    }
    h10s_h10 $acc;
}

sub sum(@) {
    my $acc = 0;
    for( @_ ) {
	$acc += h10_h10s( /:/ ? transform $_ : $_ );
    }
    h10s_h10 $acc;
}


sub now_h10(;$) {
    my( $usec, $sec, $min, $h ) = @_ ? @_ :
	do { require Time::HiRes; Time::HiRes::time() };
    $sec = int $usec;
    $usec -= $sec;
    ($sec, $min, $h) = localtime $sec;
    h24_h10 $h, $min, $sec + $usec;
}

=item loop { I<perlcode> }



=cut

my %delta = ('' => 100,
	     s => 1,
	     ds => .1,
	     cs => .01,
	     ms => .001,
	     'µs' => .000_001,
	     us => .000_001,
	     "\xb5s" => .000_001);	# Latin-[13579] µ
sub loop(&) {
    my $callback = $_[0];
    require Time::HiRes;
    my $last = '';
    while( 1 ) {
	my( $usec, $sec, $min, $h ) = Time::HiRes::time();
	my $orig = $usec;
	$sec = int $usec;
	$usec -= $sec;
	($sec, $min, $h) = localtime $sec;
	$sec = $h * 3600 + $min * 60 + $sec + $usec;
	my $cur = h24s_h10( $sec );
	redo if $cur eq $last; # Rarely select sleeps a bit too short, how about T::HR::sleep?
	last if !&$callback( $cur );
	$last = $cur;
	$sec = ($sec / FACTOR + $delta{$precision}) / $delta{$precision};
	$sec = $orig + (1 - $sec + int $sec) * $delta{$precision} * FACTOR -
	    Time::HiRes::time(); # Compensate callback time and our overhead
	Time::HiRes::sleep( $sec ) if $sec > 0; # Callback may have taken longer than 1 unit
    }
}

=item See SYNOPSIS above

I<Documentation for the various functions remains to be written.>

=back



=head2 Command Line Interface

=over

=item -s, --seconds

=item -d, --ds, --deciseconds

=item -c, --cs, --centiseconds

=item -m, --ms, --milliseconds

=item -u, --us, --microseconds

Output times at the given precision, instead of minutes.


=item -e, --echo

Output the transformed time along with the transformation.


=item -r, --reverse

Retransform the transformation to see possible loss due to insufficient
precision.


=item -l, --loop

Output the time again each time the result changes at the wanted precision.
Can be used as a clock, but if the precision is too small, the terminal
emulation may have problems, either flickering or repeatedly stalling (C<rxvt>
family).


=item -o, --old, --old-table, --babylonian, --babylonian-table

=item -n, --new, --new-table, --decimal, --decimal-table

Supplies overviews of about 70 times of common interest each.  Implies
C<--echo>.

=back

=cut

if( caller ) {
    use Exporter 'import';
    our @EXPORT_OK = qw($precision h24s_h10 h24_h10 h10s_h24 h10_h24
			transform now_h10 loop);
} else {
    require Getopt::Long;
    Getopt::Long::config( qw(bundling no_getopt_compat require_order) );

    my( $echo, $reverse, $loop );
    Getopt::Long::GetOptions
	('s|seconds' => sub { $precision = 's' },
	 'd|ds|deciseconds' => sub { $precision = 'ds' },
	 'c|cs|centiseconds' => sub { $precision = 'cs' },
	 'm|ms|milliseconds' => sub { $precision = 'ms' },
	 'u|us|microseconds' => sub { $precision = 'µs' },

	 'e|echo' => \$echo,
	 'r|reverse' => \$reverse,
	 'l|loop' => \$loop,

	 'o|old|old-table|babylonian|babylonian-table' =>
	     sub { $echo = push @ARGV,
		       sort map( ("00:00:0$_", "00:0$_:00", "0$_:00:00", "0$_:30:00"), 1..9 ),
			   map( ("00:${_}0:00", "00:${_}5:00", "00:00:${_}0", "00:00:${_}5"), 1..5 ),
			   map "$_:00:00", 10..23 },
	 'n|new|new-table|decimal|decimal-table' =>
	     sub { $echo = push @ARGV,
		       sort map( ("0_00_0${_}", "0_00_${_}0", "0_00_${_}5",
				  "0_0${_}_00", "0_${_}0_00", "0_${_}5_00",
				  "${_}_00_00", "${_}_50_00"), 1..9 ) } );
    if( @ARGV ) {
	for( @ARGV ) {
	    print "$_ ->\t" if $echo;
	    print $_ = transform( $_ );
	    print " ->\t", transform( $_ ) if $reverse;
	    print "\n";
	}
    } elsif( $loop ) {
	$| = 1;
	my $callback = -t STDOUT ? sub { print "\r$_[0]" } : sub { print "$_[0]\n" };
	loop \&$callback;
    } else {
	print now_h10, "\n";
    }
}

1;
__END__

=head1 SEE ALSO

L<DateTime::Calendar::FrenchRevolutionary> fits nicely into the DateTime
hierarchy.  Alas that doesn't handle fractions, so they have a lossy
transformation.  Besides fractions seem even more natural in decimal time.


=head1 AUTHOR

Daniel Pfeiffer <occitan@esperanto.org>
