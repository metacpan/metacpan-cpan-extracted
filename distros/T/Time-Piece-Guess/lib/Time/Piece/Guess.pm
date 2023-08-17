package Time::Piece::Guess;

use 5.006;
use strict;
use warnings;
use Time::Piece;

=head1 NAME

Time::Piece::Guess - Compares the passed string against common patterns and returns a format to use with Time::Piece or object

=head1 VERSION

Version 0.1.1

=cut

our $VERSION = '0.1.1';

=head1 SYNOPSIS

    use Time::Piece::Guess;
    use Time::Piece;

    my $string='2023-02-27T11:00:18.33';
    my ($format, $ms_clean_regex) = Time::Piece::Guess->guess('2023-02-27T11:00:18');
    # apply the regex if needed
    if (defined( $ms_clean_regex )){
        $string=~s/$ms_clean_regex//;
    }
    my $tp_object;
    if (!defined( $format )){
        print "No matching format found\n";
    }else{
        $tp_object = Time::Piece->strptime( '2023-02-27T11:00:18' , $format );
    }

    $tp_object = Time::Piece::Guess->guess_to_object('2023-02-27T11:00:18');
    if (!defined( $tp_object )){
        print "No matching format found\n";
    }

=head1 METHODS

=head2 guess

Compares it against various patterns and returns the matching string for use with
parsing that format.

If one can't be matched, undef is returned. Two values are returned. The first is the format
of it and the second is a regexp to remove microseconds if needed.

This will attempt to remove microseconds as below.

    my $string='2023-02-27T11:00:18.33';
    my ($format, $ms_clean_regex) = Time::Piece::Guess->guess('2023-02-27T11:00:18');
    # apply the regex if needed
    if (defined( $ms_clean_regex )){
        $string=~s/$ms_clean_regex//;
    }
    my $tp_object;
    if (!defined( $format )){
        print "No matching format found\n";
    }else{
        $tp_object = Time::Piece->strptime( '2023-02-27T11:00:18' , $format );
    }


Worth noting that Time::Piece as of the writing of this has a bug in which if just hours
are present for %z and minutes are not it will error.

    if ($format =~ /\%z/ && $string =~ /[-+]\d\d$/) {
        sstring=$string.'00';
    }


=cut

sub guess {
	my $string = $_[1];

	if ( !defined($string) ) {
		return undef;
	}

	# remove micro seconds if they are present
	my $regex;
	if ( $string =~ /\.\d+/ ) {
		$regex = qr/\.\d+/;
		$string =~ s/$regex//;
	}

	my $format;
	if ( $string =~ /^\d+$/ ) {
		$format = '%s';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\ [0-2][0-9]\:[0-5][0-9][-+]\d+$/ ) {
		$format = '%Y-%m-%d %H:%M%z';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\ [0-2][0-9]\:[0-5][0-9]Z$/ ) {
		$format = '%Y-%m-%d %H:%MZ';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\ [0-2][0-9]\:[0-5][0-9]\ .+$/ ) {
		$format = '%Y-%m-%d %H:%M %Z';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\ [0-2][0-9]\:[0-5][0-9]\:[0-5][0-9][-+]\d+$/ ) {
		$format = '%Y-%m-%d %H:%M:%S%z';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\ [0-2][0-9]\:[0-5][0-9]\:[0-5][0-9]Z$/ ) {
		$format = '%Y-%m-%d %H:%M:%SZ';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\ [0-2][0-9]\:[0-5][0-9]\:[0-5][0-9]\ .+$/ ) {
		$format = '%Y-%m-%d %H:%M:%S %Z';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\dT[0-2][0-9]\:[0-5][0-9][-+]\d+$/ ) {
		$format = '%Y-%m-%dT%H:%M%z';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\dT[0-2][0-9]\:[0-5][0-9]Z$/ ) {
		$format = '%Y-%m-%dT%H:%MZ';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\dT[0-2][0-9]\:[0-5][0-9]\ .+$/ ) {
		$format = '%Y-%m-%dT%H:%M %Z';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\dT[0-2][0-9]\:[0-5][0-9]\:[0-5][0-9][-+]\d+$/ ) {
		$format = '%Y-%m-%dT%H:%M:%S%z';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\dT[0-2][0-9]\:[0-5][0-9]\:[0-5][0-9]Z$/ ) {
		$format = '%Y-%m-%dT%H:%M:%SZ';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\dT[0-2][0-9]\:[0-5][0-9]\:[0-5][0-9]\ .+$/ ) {
		$format = '%Y-%m-%dT%H:%M:%S %Z';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\/[0-2][0-9]\:[0-5][0-9][-+]\d+$/ ) {
		$format = '%Y-%m-%dT%H:%M%z';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\/[0-2][0-9]\:[0-5][0-9]Z$/ ) {
		$format = '%Y-%m-%dT%H:%MZ';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\/[0-2][0-9]\:[0-5][0-9]\ .+$/ ) {
		$format = '%Y-%m-%dT%H:%M %Z';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\/[0-2][0-9]\:[0-5][0-9]\:[0-5][0-9][-+]\d+$/ ) {
		$format = '%Y-%m-%d/%H:%M:%S%z';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\/[0-2][0-9]\:[0-5][0-9]\:[0-5][0-9]Z$/ ) {
		$format = '%Y-%m-%d/%H:%M:%SZ';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\/[0-2][0-9]\:[0-5][0-9]\:[0-5][0-9]\ .+$/ ) {
		$format = '%Y-%m-%d/%H:%M:%S %Z';
	} elsif ( $string =~ /^\d\d\d\d\d\d\d\d\ [0-2][0-9]\:[0-5][0-9][-+]\d+$/ ) {
		$format = '%Y%m%d %H:%M%z';
	} elsif ( $string =~ /^\d\d\d\d\d\d\d\d\ [0-2][0-9]\:[0-5][0-9]Z$/ ) {
		$format = '%Y%m%d %H:%M%Z';
	} elsif ( $string =~ /^\d\d\d\d\d\d\d\d\ [0-2][0-9]\:[0-5][0-9]\ .+$/ ) {
		$format = '%Y%m%d %H:%M %Z';
	} elsif ( $string =~ /^\d\d\d\d\d\d\d\d\ [0-2][0-9]\:[0-5][0-9]\:[0-5][0-9][-+]\d+$/ ) {
		$format = '%Y%m%d %H:%M:%S%z';
	} elsif ( $string =~ /^\d\d\d\d\d\d\d\d\ [0-2][0-9]\:[0-5][0-9]\:[0-5][0-9]Z$/ ) {
		$format = '%Y%m%d %H:%M:%SZ';
	} elsif ( $string =~ /^\d\d\d\d\d\d\d\d\ [0-2][0-9]\:[0-5][0-9]\:[0-5][0-9]\ .+$/ ) {
		$format = '%Y%m%d %H:%M:%S %Z';
	} elsif ( $string =~ /\^d\d\d\d\d\d\d\dT[0-2][0-9]\:[0-5][0-9][-+]\d+$/ ) {
		$format = '%Y%m%dT%H:%M%z';
	} elsif ( $string =~ /\^d\d\d\d\d\d\d\dT[0-2][0-9]\:[0-5][0-9]Z$/ ) {
		$format = '%Y%m%dT%H:%MZ';
	} elsif ( $string =~ /\^d\d\d\d\d\d\d\dT[0-2][0-9]\:[0-5][0-9]\ .+$/ ) {
		$format = '%Y%m%dT%H:%M %Z';
	} elsif ( $string =~ /^\d\d\d\d\d\d\d\dT[0-2][0-9]\:[0-5][0-9]\:[0-5][0-9][-+]\d+$/ ) {
		$format = '%Y%m%dT%H:%M:%S%z';
	} elsif ( $string =~ /^\d\d\d\d\d\d\d\dT[0-2][0-9]\:[0-5][0-9]\:[0-5][0-9]Z$/ ) {
		$format = '%Y%m%dT%H:%M:%SZ';
	} elsif ( $string =~ /^\d\d\d\d\d\d\d\dT[0-2][0-9]\:[0-5][0-9]\:[0-5][0-9]\ .+$/ ) {
		$format = '%Y%m%dT%H:%M:%S %Z';
	} elsif ( $string =~ /^\d\d\d\d\d\d\d\d\/[0-2][0-9]\:[0-5][0-9][-+]\d+$/ ) {
		$format = '%Y%m%dT%H:%M%z';
	} elsif ( $string =~ /^\d\d\d\d\d\d\d\d\/[0-2][0-9]\:[0-5][0-9]Z$/ ) {
		$format = '%Y%m%dT%H:%MZ';
	} elsif ( $string =~ /^\d\d\d\d\d\d\d\d\/[0-2][0-9]\:[0-5][0-9]\ .+$/ ) {
		$format = '%Y%m%dT%H:%M %Z';
	} elsif ( $string =~ /^\d\d\d\d\d\d\d\d\/[0-2][0-9]\:[0-5][0-9]\:[0-5][0-9][-+]\d+$/ ) {
		$format = '%Y%m%d/%H:%M:%S%z';
	} elsif ( $string =~ /^\d\d\d\d\d\d\d\d\/[0-2][0-9]\:[0-5][0-9]\:[0-5][0-9]Z$/ ) {
		$format = '%Y%m%d/%H:%M:%SZ';
	} elsif ( $string =~ /^\d\d\d\d\d\d\d\d\/[0-2][0-9]\:[0-5][0-9]\:[0-5][0-9]\ .+$/ ) {
		$format = '%Y%m%d/%H:%M:%S %Z';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\ [0-2][0-9]\:[0-5][0-9]$/ ) {
		$format = '%Y-%m-%d %H:%M';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\ [0-2][0-9]\:[0-5][0-9]\:[0-5][0-9]$/ ) {
		$format = '%Y-%m-%d %H:%M:%S';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\dT[0-2][0-9]\:[0-5][0-9]$/ ) {
		$format = '%Y-%m-%dT%H:%M';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\dT[0-2][0-9]\:[0-5][0-9]\:[0-5][0-9]$/ ) {
		$format = '%Y-%m-%dT%H:%M:%S';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\/[0-2][0-9]\:[0-5][0-9]$/ ) {
		$format = '%Y-%m-%dT%H:%M';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\/[0-2][0-9]\:[0-5][0-9]\:[0-5][0-9]$/ ) {
		$format = '%Y-%m-%d/%H:%M:%S';
	} elsif ( $string =~ /^\d\d\d\d\d\d\d\d\ [0-2][0-9]\:[0-5][0-9]$/ ) {
		$format = '%Y%m%d %H:%M';
	} elsif ( $string =~ /^\d\d\d\d\d\d\d\d\ [0-2][0-9]\:[0-5][0-9]\:[0-5][0-9]$/ ) {
		$format = '%Y%m%d %H:%M:%S';
	} elsif ( $string =~ /^\d\d\d\d\d\d\d\dT[0-2][0-9]\:[0-5][0-9]$/ ) {
		$format = '%Y%m%dT%H:%M';
	} elsif ( $string =~ /^\d\d\d\d\d\d\d\dT[0-2][0-9]\:[0-5][0-9]\:[0-5][0-9]$/ ) {
		$format = '%Y%m%dT%H:%M:%S';
	} elsif ( $string =~ /^\d\d\d\d\d\d\d\d\/[0-2][0-9]\:[0-5][0-9]$/ ) {
		$format = '%Y%m%dT%H:%M';
	} elsif ( $string =~ /^\d\d\d\d\d\d\d\d\/[0-2][0-9]\:[0-5][0-9]\:[0-5][0-9]$/ ) {
		$format = '%Y%m%d/%H:%M:%S';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\ [0-2][0-9][0-5][0-9][-+]\d+$/ ) {
		$format = '%Y-%m-%d %H%M%z';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\ [0-2][0-9][0-5][0-9]Z$/ ) {
		$format = '%Y-%m-%d %H%MZ';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\ [0-2][0-9][0-5][0-9]\ .+$/ ) {
		$format = '%Y-%m-%d %H%M %Z';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\ [0-2][0-9][0-5][0-9][0-5][0-9][-+]\d+$/ ) {
		$format = '%Y-%m-%d %H%M%S%z';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\ [0-2][0-9][0-5][0-9][0-5][0-9]Z$/ ) {
		$format = '%Y-%m-%d %H%M%SZ';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\ [0-2][0-9][0-5][0-9][0-5][0-9]\ .+$/ ) {
		$format = '%Y-%m-%d %H%M%S %Z';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\dT[0-2][0-9][0-5][0-9][-+]\d+$/ ) {
		$format = '%Y-%m-%dT%H%M%z';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\dT[0-2][0-9][0-5][0-9]Z$/ ) {
		$format = '%Y-%m-%dT%H%MZ';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\dT[0-2][0-9][0-5][0-9]\ .+$/ ) {
		$format = '%Y-%m-%dT%H%M %Z';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\dT[0-2][0-9][0-5][0-9][0-5][0-9][-+]\d+$/ ) {
		$format = '%Y-%m-%dT%H%M%S%z';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\dT[0-2][0-9][0-5][0-9][0-5][0-9]Z$/ ) {
		$format = '%Y-%m-%dT%H%M%SZ';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\dT[0-2][0-9][0-5][0-9][0-5][0-9]\ .+$/ ) {
		$format = '%Y-%m-%dT%H%M%S %Z';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\/[0-2][0-9][0-5][0-9][-+]\d+$/ ) {
		$format = '%Y-%m-%dT%H%M%z';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\/[0-2][0-9][0-5][0-9]Z$/ ) {
		$format = '%Y-%m-%dT%H%MZ';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\/[0-2][0-9][0-5][0-9]\ .+$/ ) {
		$format = '%Y-%m-%dT%H%M %Z';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\/[0-2][0-9][0-5][0-9][0-5][0-9][-+]\d+$/ ) {
		$format = '%Y-%m-%d/%H%M%S%z';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\/[0-2][0-9][0-5][0-9][0-5][0-9]Z$/ ) {
		$format = '%Y-%m-%d/%H%M%SZ';
	} elsif ( $string =~ /^\d\d\d\d\d\d\d\d\ [0-2][0-9][0-5][0-9][-+]\d+$/ ) {
		$format = '%Y%m%d %H%M%z';
	} elsif ( $string =~ /^\d\d\d\d\d\d\d\d\ [0-2][0-9][0-5][0-9]Z$/ ) {
		$format = '%Y%m%d %H%M%Z';
	} elsif ( $string =~ /^\d\d\d\d\d\d\d\d\ [0-2][0-9][0-5][0-9][0-5][0-9][-+]\d+$/ ) {
		$format = '%Y%m%d %H%M%S%z';
	} elsif ( $string =~ /^\d\d\d\d\d\d\d\d\ [0-2][0-9][0-5][0-9][0-5][0-9]Z$/ ) {
		$format = '%Y%m%d %H%M%SZ';
	} elsif ( $string =~ /\^d\d\d\d\d\d\d\dT[0-2][0-9][0-5][0-9][-+]\d+$/ ) {
		$format = '%Y%m%dT%H%M%z';
	} elsif ( $string =~ /\^d\d\d\d\d\d\d\dT[0-2][0-9][0-5][0-9]Z$/ ) {
		$format = '%Y%m%dT%H%MZ';
	} elsif ( $string =~ /^\d\d\d\d\d\d\d\dT[0-2][0-9][0-5][0-9][0-5][0-9][-+]\d+$/ ) {
		$format = '%Y%m%dT%H%M%S%z';
	} elsif ( $string =~ /^\d\d\d\d\d\d\d\dT[0-2][0-9][0-5][0-9][0-5][0-9]Z$/ ) {
		$format = '%Y%m%dT%H%M%SZ';
	} elsif ( $string =~ /^\d\d\d\d\d\d\d\d\/[0-2][0-9][0-5][0-9][-+]\d+$/ ) {
		$format = '%Y%m%dT%H%M%z';
	} elsif ( $string =~ /^\d\d\d\d\d\d\d\d\/[0-2][0-9][0-5][0-9]Z$/ ) {
		$format = '%Y%m%dT%H%MZ';
	} elsif ( $string =~ /^\d\d\d\d\d\d\d\d\/[0-2][0-9][0-5][0-9][0-5][0-9][-+]\d+$/ ) {
		$format = '%Y%m%d/%H%M%S%z';
	} elsif ( $string =~ /^\d\d\d\d\d\d\d\d\/[0-2][0-9][0-5][0-9][0-5][0-9]Z$/ ) {
		$format = '%Y%m%d/%H%M%SZ';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\ [0-2][0-9][0-5][0-9]$/ ) {
		$format = '%Y-%m-%d %H%M';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\ [0-2][0-9][0-5][0-9][0-5][0-9]$/ ) {
		$format = '%Y-%m-%d %H%M%S';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\dT[0-2][0-9][0-5][0-9]$/ ) {
		$format = '%Y-%m-%dT%H%M';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\dT[0-2][0-9][0-5][0-9][0-5][0-9]$/ ) {
		$format = '%Y-%m-%dT%H%M%S';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\/[0-2][0-9][0-5][0-9]$/ ) {
		$format = '%Y-%m-%dT%H%M';
	} elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\/[0-2][0-9][0-5][0-9][0-5][0-9]$/ ) {
		$format = '%Y-%m-%d/%H%M%S';
	} elsif ( $string =~ /^\d\d\d\d\d\d\d\d\ [0-2][0-9][0-5][0-9]$/ ) {
		$format = '%Y%m%d %H%M';
	} elsif ( $string =~ /^\d\d\d\d\d\d\d\d\ [0-2][0-9][0-5][0-9][0-5][0-9]$/ ) {
		$format = '%Y%m%d %H%M%S';
	} elsif ( $string =~ /^\d\d\d\d\d\d\d\dT[0-2][0-9][0-5][0-9]$/ ) {
		$format = '%Y%m%dT%H%M';
	} elsif ( $string =~ /^\d\d\d\d\d\d\d\dT[0-2][0-9][0-5][0-9][0-5][0-9]$/ ) {
		$format = '%Y%m%dT%H%M%S';
	} elsif ( $string =~ /^\d\d\d\d\d\d\d\d\/[0-2][0-9][0-5][0-9]$/ ) {
		$format = '%Y%m%dT%H%M';
	} elsif ( $string =~ /^\d\d\d\d\d\d\d\d\/[0-2][0-9][0-5][0-9][0-5][0-9]$/ ) {
		$format = '%Y%m%d/%H%M%S';

	}

	return $format, $regex;
} ## end sub guess

=head2 guess_to_object

Takes the string, calles guess on it. If it gets a hit, it then returns
the Time::Piece object.

Optionally there is the option to enable specials as well. See the section
on specials further down.

If it fails, undef is returned.

    $tp_object = Time::Piece::Guess->guess_to_object('2023-02-27T11:00:18');
    if (!defined( $tp_object )){
        print "No matching format found\n";
    }

The same thing, but enabling specials and, resulting in it appending the local timezone
offset data that would correspond to %z.

    $tp_object = Time::Piece::Guess->guess_to_object('2023-02-27T11:00:18zz', 1);

=cut

sub guess_to_object {
	my $string  = $_[1];
	my $special = $_[2];

	if ( !defined($string) ) {
		return undef;
	}

	# if special is enabled and it looks like a now special
	# return the current time with the diffence applied
	if (
		$special
		&& (   $string =~ /^now$/
			|| $string =~ /^now[\-\+]\d+[mhdw]?$/
			|| $string =~ /^[\-\+]\d+[mhdw]?$/ )
		)
	{
		my $t = localtime;

		# if just now, it is asking for the current time, so just return that
		if ( $string eq 'now' ) {
			return $t;
		}

		# since this is more than just now, remove the now part and proceed to
		# figure out what the off set is
		$string =~ s/^now//;

		# figure out what to multiply the offset by
		# nothing, seconds
		my $multiplier = 1;
		if ( $string =~ /m$/ ) {
			# minutes
			$multiplier = 60;
			$string =~ s/m$//;
		} elsif ( $string =~ /h$/ ) {
			# hours
			$multiplier = 60 * 60;
			$string =~ s/h$//;
		} elsif ( $string =~ /d$/ ) {
			# days
			$multiplier = 60 * 60 * 24;
			$string =~ s/d$//;
		} elsif ( $string =~ /w$/ ) {
			# weeks
			$multiplier = 60 * 60 * 24 * 7;
			$string =~ s/w$//;
		}

		# figure out the direction we are going
		# multiply it
		# apply the offset
		if ( $string =~ /^\-/ ) {
			$string =~ s/^\-//;
			$string = $string * $multiplier;
			$t      = $t - $string;
		} else {
			$string =~ s/^\+//;
			$string = $string * $multiplier;
			$t      = $t + $string;
		}

		return $t;
	} ## end if ( $special && ( $string =~ /^now$/ || $string...))

	# if special is enabled and ZZ or zz is used at the end
	# append the timezone abbreviation
	my $make_local = 0;
	if (   $special
		&& $string =~ /zz$/ )
	{
		my $t    = localtime;
		my $zone = $t->strftime("%z");
		$string =~ s/zz$/$zone/;
		$make_local = 1;
	} elsif ( $special
		&& $string =~ /ZZ$/ )
	{
		my $t    = localtime;
		my $zone = $t->strftime("%Z");
		$string =~ s/\ ?ZZ$/\ $zone/;
		$make_local = 1;
	}

	my ( $format, $ms_clean_regex ) = Time::Piece::Guess->guess($string);

	if ( !defined($format) ) {
		return undef;
	}

	if ( defined($ms_clean_regex) ) {
		$string =~ s/$ms_clean_regex//;
	}

	# append 00 for minutes if %z is on the end
	# as Time::Piece does not handle it properly if it
	# is just hours
	if ($format =~ /\%z/ && $string =~ /[-+]\d\d$/) {
		$string=$string.'00';
	}

	my $t;
	eval { $t = Time::Piece->strptime( $string, $format ); };
	if ($@) {
		return undef;
	}

	# unfortunately Time::Piece lakes the ability to set this currently
	if ($make_local) {
		$t->[10] = 1;
	}

	return $t;
} ## end sub guess_to_object

=head1 SPECIAL FORMATS

=head2 now

Now is returns current time.

=head2 now[-+]\d+[mhdw]?

Returns the current time after adding or subtracting the specified number of seconds.

The following may be applied to the end to act as a multipler.

    - m :: The specified number is minutes.

    - h :: The specified number is hours.

    - d :: The specified number is hours.

    - w :: The specified number is weeks.

So 'now-5' would be now minus five seconds and 'now-5m' would be now minus five minutes.

=head2 zz

Apply the current time zone to the end prior to parsing. Offset is determined by %z.

'2023-07-23T17:34:00zz' if in -0500 would become '2023-07-23T17:34:00-0500'.

=head2 ZZ

Apply the current time zone name to the end prior to parsing. The name is determined
by %Z.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-time-piece-guess at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Time-Piece-Guess>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Time::Piece::Guess


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Time-Piece-Guess>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Time-Piece-Guess>

=item * Search CPAN

L<https://metacpan.org/release/Time-Piece-Guess>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;    # End of Time::Piece::Guess
