package Time::Piece::Guess;

use 5.006;
use strict;
use warnings;
use Time::Piece;

=head1 NAME

Time::Piece::Guess - Compares the passed string against common patterns and returns a format to use with Time::Piece or object

=head1 VERSION

Version 0.0.3

=cut

our $VERSION = '0.0.3';

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


=cut

sub guess {
	my $string = $_[1];

	if ( !defined($string) ) {
		return undef;
	}

	# remove micro seconds if they are present
	my $regex;
	if ($string =~ /\.\d+/) {
		$regex=qr/\.\d+/;
		$string=~s/$regex//;
	}

	my $format;
	if ( $string =~ /^\d+$/ ) {
		$format = '%s';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\ [0-2][0-9]\:[0-5][0-9][-+]\d+$/ ) {
		$format = '%Y-%m-%d %H:%M%z';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\ [0-2][0-9]\:[0-5][0-9]Z$/ ) {
		$format = '%Y-%m-%d %H:%MZ';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\ [0-2][0-9]\:[0-5][0-9]\ .+$/ ) {
		$format = '%Y-%m-%d %H:%M %Z';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\ [0-2][0-9]\:[0-5][0-9]\:[0-5][0-9][-+]\d+$/ ) {
		$format = '%Y-%m-%d %H:%M:%S%z';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\ [0-2][0-9]\:[0-5][0-9]\:[0-5][0-9]Z$/ ) {
		$format = '%Y-%m-%d %H:%M:%SZ';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\ [0-2][0-9]\:[0-5][0-9]\:[0-5][0-9]\ .+$/ ) {
		$format = '%Y-%m-%d %H:%M:%S %Z';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\dT[0-2][0-9]\:[0-5][0-9][-+]\d+$/ ) {
		$format = '%Y-%m-%dT%H:%M%z';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\dT[0-2][0-9]\:[0-5][0-9]Z$/ ) {
		$format = '%Y-%m-%dT%H:%MZ';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\dT[0-2][0-9]\:[0-5][0-9]\ .+$/ ) {
		$format = '%Y-%m-%dT%H:%M %Z';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\dT[0-2][0-9]\:[0-5][0-9]\:[0-5][0-9][-+]\d+$/ ) {
		$format = '%Y-%m-%dT%H:%M:%S%z';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\dT[0-2][0-9]\:[0-5][0-9]\:[0-5][0-9]Z$/ ) {
		$format = '%Y-%m-%dT%H:%M:%SZ';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\dT[0-2][0-9]\:[0-5][0-9]\:[0-5][0-9]\ .+$/ ) {
		$format = '%Y-%m-%dT%H:%M:%S %Z';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\/[0-2][0-9]\:[0-5][0-9][-+]\d+$/ ) {
		$format = '%Y-%m-%dT%H:%M%z';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\/[0-2][0-9]\:[0-5][0-9]Z$/ ) {
		$format = '%Y-%m-%dT%H:%MZ';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\/[0-2][0-9]\:[0-5][0-9]\ .+$/ ) {
		$format = '%Y-%m-%dT%H:%M %Z';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\/[0-2][0-9]\:[0-5][0-9]\:[0-5][0-9][-+]\d+$/ ) {
		$format = '%Y-%m-%d/%H:%M:%S%z';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\/[0-2][0-9]\:[0-5][0-9]\:[0-5][0-9]Z$/ ) {
		$format = '%Y-%m-%d/%H:%M:%SZ';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\/[0-2][0-9]\:[0-5][0-9]\:[0-5][0-9]\ .+$/ ) {
		$format = '%Y-%m-%d/%H:%M:%S %Z';
	}
	elsif ( $string =~ /^\d\d\d\d\d\d\d\d\ [0-2][0-9]\:[0-5][0-9][-+]\d+$/ ) {
		$format = '%Y%m%d %H:%M%z';
	}
	elsif ( $string =~ /^\d\d\d\d\d\d\d\d\ [0-2][0-9]\:[0-5][0-9]Z$/ ) {
		$format = '%Y%m%d %H:%M%Z';
	}
	elsif ( $string =~ /^\d\d\d\d\d\d\d\d\ [0-2][0-9]\:[0-5][0-9]\ .+$/ ) {
		$format = '%Y%m%d %H:%M %Z';
	}
	elsif ( $string =~ /^\d\d\d\d\d\d\d\d\ [0-2][0-9]\:[0-5][0-9]\:[0-5][0-9][-+]\d+$/ ) {
		$format = '%Y%m%d %H:%M:%S%z';
	}
	elsif ( $string =~ /^\d\d\d\d\d\d\d\d\ [0-2][0-9]\:[0-5][0-9]\:[0-5][0-9]Z$/ ) {
		$format = '%Y%m%d %H:%M:%SZ';
	}
	elsif ( $string =~ /^\d\d\d\d\d\d\d\d\ [0-2][0-9]\:[0-5][0-9]\:[0-5][0-9]\ .+$/ ) {
		$format = '%Y%m%d %H:%M:%S %Z';
	}
	elsif ( $string =~ /\^d\d\d\d\d\d\d\dT[0-2][0-9]\:[0-5][0-9][-+]\d+$/ ) {
		$format = '%Y%m%dT%H:%M%z';
	}
	elsif ( $string =~ /\^d\d\d\d\d\d\d\dT[0-2][0-9]\:[0-5][0-9]Z$/ ) {
		$format = '%Y%m%dT%H:%MZ';
	}
	elsif ( $string =~ /\^d\d\d\d\d\d\d\dT[0-2][0-9]\:[0-5][0-9]\ .+$/ ) {
		$format = '%Y%m%dT%H:%M %Z';
	}
	elsif ( $string =~ /^\d\d\d\d\d\d\d\dT[0-2][0-9]\:[0-5][0-9]\:[0-5][0-9][-+]\d+$/ ) {
		$format = '%Y%m%dT%H:%M:%S%z';
	}
	elsif ( $string =~ /^\d\d\d\d\d\d\d\dT[0-2][0-9]\:[0-5][0-9]\:[0-5][0-9]Z$/ ) {
		$format = '%Y%m%dT%H:%M:%SZ';
	}
	elsif ( $string =~ /^\d\d\d\d\d\d\d\dT[0-2][0-9]\:[0-5][0-9]\:[0-5][0-9]\ .+$/ ) {
		$format = '%Y%m%dT%H:%M:%S %Z';
	}
	elsif ( $string =~ /^\d\d\d\d\d\d\d\d\/[0-2][0-9]\:[0-5][0-9][-+]\d+$/ ) {
		$format = '%Y%m%dT%H:%M%z';
	}
	elsif ( $string =~ /^\d\d\d\d\d\d\d\d\/[0-2][0-9]\:[0-5][0-9]Z$/ ) {
		$format = '%Y%m%dT%H:%MZ';
	}
	elsif ( $string =~ /^\d\d\d\d\d\d\d\d\/[0-2][0-9]\:[0-5][0-9]\ .+$/ ) {
		$format = '%Y%m%dT%H:%M %Z';
	}
	elsif ( $string =~ /^\d\d\d\d\d\d\d\d\/[0-2][0-9]\:[0-5][0-9]\:[0-5][0-9][-+]\d+$/ ) {
		$format = '%Y%m%d/%H:%M:%S%z';
	}
	elsif ( $string =~ /^\d\d\d\d\d\d\d\d\/[0-2][0-9]\:[0-5][0-9]\:[0-5][0-9]Z$/ ) {
		$format = '%Y%m%d/%H:%M:%SZ';
	}
	elsif ( $string =~ /^\d\d\d\d\d\d\d\d\/[0-2][0-9]\:[0-5][0-9]\:[0-5][0-9]\ .+$/ ) {
		$format = '%Y%m%d/%H:%M:%S %Z';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\ [0-2][0-9]\:[0-5][0-9]$/ ) {
		$format = '%Y-%m-%d %H:%M';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\ [0-2][0-9]\:[0-5][0-9]\:[0-5][0-9]$/ ) {
		$format = '%Y-%m-%d %H:%M:%S';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\dT[0-2][0-9]\:[0-5][0-9]$/ ) {
		$format = '%Y-%m-%dT%H:%M';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\dT[0-2][0-9]\:[0-5][0-9]\:[0-5][0-9]$/ ) {
		$format = '%Y-%m-%dT%H:%M:%S';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\/[0-2][0-9]\:[0-5][0-9]$/ ) {
		$format = '%Y-%m-%dT%H:%M';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\/[0-2][0-9]\:[0-5][0-9]\:[0-5][0-9]$/ ) {
		$format = '%Y-%m-%d/%H:%M:%S';
	}
	elsif ( $string =~ /^\d\d\d\d\d\d\d\d\ [0-2][0-9]\:[0-5][0-9]$/ ) {
		$format = '%Y%m%d %H:%M';
	}
	elsif ( $string =~ /^\d\d\d\d\d\d\d\d\ [0-2][0-9]\:[0-5][0-9]\:[0-5][0-9]$/ ) {
		$format = '%Y%m%d %H:%M:%S';
	}
	elsif ( $string =~ /^\d\d\d\d\d\d\d\dT[0-2][0-9]\:[0-5][0-9]$/ ) {
		$format = '%Y%m%dT%H:%M';
	}
	elsif ( $string =~ /^\d\d\d\d\d\d\d\dT[0-2][0-9]\:[0-5][0-9]\:[0-5][0-9]$/ ) {
		$format = '%Y%m%dT%H:%M:%S';
	}
	elsif ( $string =~ /^\d\d\d\d\d\d\d\d\/[0-2][0-9]\:[0-5][0-9]$/ ) {
		$format = '%Y%m%dT%H:%M';
	}
	elsif ( $string =~ /^\d\d\d\d\d\d\d\d\/[0-2][0-9]\:[0-5][0-9]\:[0-5][0-9]$/ ) {
		$format = '%Y%m%d/%H:%M:%S';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\ [0-2][0-9][0-5][0-9][-+]\d+$/ ) {
		$format = '%Y-%m-%d %H%M%z';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\ [0-2][0-9][0-5][0-9]Z$/ ) {
		$format = '%Y-%m-%d %H%MZ';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\ [0-2][0-9][0-5][0-9]\ .+$/ ) {
		$format = '%Y-%m-%d %H%M %Z';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\ [0-2][0-9][0-5][0-9][0-5][0-9][-+]\d+$/ ) {
		$format = '%Y-%m-%d %H%M%S%z';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\ [0-2][0-9][0-5][0-9][0-5][0-9]Z$/ ) {
		$format = '%Y-%m-%d %H%M%SZ';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\ [0-2][0-9][0-5][0-9][0-5][0-9]\ .+$/ ) {
		$format = '%Y-%m-%d %H%M%S %Z';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\dT[0-2][0-9][0-5][0-9][-+]\d+$/ ) {
		$format = '%Y-%m-%dT%H%M%z';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\dT[0-2][0-9][0-5][0-9]Z$/ ) {
		$format = '%Y-%m-%dT%H%MZ';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\dT[0-2][0-9][0-5][0-9]\ .+$/ ) {
		$format = '%Y-%m-%dT%H%M %Z';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\dT[0-2][0-9][0-5][0-9][0-5][0-9][-+]\d+$/ ) {
		$format = '%Y-%m-%dT%H%M%S%z';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\dT[0-2][0-9][0-5][0-9][0-5][0-9]Z$/ ) {
		$format = '%Y-%m-%dT%H%M%SZ';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\dT[0-2][0-9][0-5][0-9][0-5][0-9]\ .+$/ ) {
		$format = '%Y-%m-%dT%H%M%S %Z';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\/[0-2][0-9][0-5][0-9][-+]\d+$/ ) {
		$format = '%Y-%m-%dT%H%M%z';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\/[0-2][0-9][0-5][0-9]Z$/ ) {
		$format = '%Y-%m-%dT%H%MZ';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\/[0-2][0-9][0-5][0-9]\ .+$/ ) {
		$format = '%Y-%m-%dT%H%M %Z';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\/[0-2][0-9][0-5][0-9][0-5][0-9][-+]\d+$/ ) {
		$format = '%Y-%m-%d/%H%M%S%z';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\/[0-2][0-9][0-5][0-9][0-5][0-9]Z$/ ) {
		$format = '%Y-%m-%d/%H%M%SZ';
	}
	elsif ( $string =~ /^\d\d\d\d\d\d\d\d\ [0-2][0-9][0-5][0-9][-+]\d+$/ ) {
		$format = '%Y%m%d %H%M%z';
	}
	elsif ( $string =~ /^\d\d\d\d\d\d\d\d\ [0-2][0-9][0-5][0-9]Z$/ ) {
		$format = '%Y%m%d %H%M%Z';
	}
	elsif ( $string =~ /^\d\d\d\d\d\d\d\d\ [0-2][0-9][0-5][0-9][0-5][0-9][-+]\d+$/ ) {
		$format = '%Y%m%d %H%M%S%z';
	}
	elsif ( $string =~ /^\d\d\d\d\d\d\d\d\ [0-2][0-9][0-5][0-9][0-5][0-9]Z$/ ) {
		$format = '%Y%m%d %H%M%SZ';
	}
	elsif ( $string =~ /\^d\d\d\d\d\d\d\dT[0-2][0-9][0-5][0-9][-+]\d+$/ ) {
		$format = '%Y%m%dT%H%M%z';
	}
	elsif ( $string =~ /\^d\d\d\d\d\d\d\dT[0-2][0-9][0-5][0-9]Z$/ ) {
		$format = '%Y%m%dT%H%MZ';
	}
	elsif ( $string =~ /^\d\d\d\d\d\d\d\dT[0-2][0-9][0-5][0-9][0-5][0-9][-+]\d+$/ ) {
		$format = '%Y%m%dT%H%M%S%z';
	}
	elsif ( $string =~ /^\d\d\d\d\d\d\d\dT[0-2][0-9][0-5][0-9][0-5][0-9]Z$/ ) {
		$format = '%Y%m%dT%H%M%SZ';
	}
	elsif ( $string =~ /^\d\d\d\d\d\d\d\d\/[0-2][0-9][0-5][0-9][-+]\d+$/ ) {
		$format = '%Y%m%dT%H%M%z';
	}
	elsif ( $string =~ /^\d\d\d\d\d\d\d\d\/[0-2][0-9][0-5][0-9]Z$/ ) {
		$format = '%Y%m%dT%H%MZ';
	}
	elsif ( $string =~ /^\d\d\d\d\d\d\d\d\/[0-2][0-9][0-5][0-9][0-5][0-9][-+]\d+$/ ) {
		$format = '%Y%m%d/%H%M%S%z';
	}
	elsif ( $string =~ /^\d\d\d\d\d\d\d\d\/[0-2][0-9][0-5][0-9][0-5][0-9]Z$/ ) {
		$format = '%Y%m%d/%H%M%SZ';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\ [0-2][0-9][0-5][0-9]$/ ) {
		$format = '%Y-%m-%d %H%M';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\ [0-2][0-9][0-5][0-9][0-5][0-9]$/ ) {
		$format = '%Y-%m-%d %H%M%S';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\dT[0-2][0-9][0-5][0-9]$/ ) {
		$format = '%Y-%m-%dT%H%M';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\dT[0-2][0-9][0-5][0-9][0-5][0-9]$/ ) {
		$format = '%Y-%m-%dT%H%M%S';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\/[0-2][0-9][0-5][0-9]$/ ) {
		$format = '%Y-%m-%dT%H%M';
	}
	elsif ( $string =~ /^\d\d\d\d\-\d\d-\d\d\/[0-2][0-9][0-5][0-9][0-5][0-9]$/ ) {
		$format = '%Y-%m-%d/%H%M%S';
	}
	elsif ( $string =~ /^\d\d\d\d\d\d\d\d\ [0-2][0-9][0-5][0-9]$/ ) {
		$format = '%Y%m%d %H%M';
	}
	elsif ( $string =~ /^\d\d\d\d\d\d\d\d\ [0-2][0-9][0-5][0-9][0-5][0-9]$/ ) {
		$format = '%Y%m%d %H%M%S';
	}
	elsif ( $string =~ /^\d\d\d\d\d\d\d\dT[0-2][0-9][0-5][0-9]$/ ) {
		$format = '%Y%m%dT%H%M';
	}
	elsif ( $string =~ /^\d\d\d\d\d\d\d\dT[0-2][0-9][0-5][0-9][0-5][0-9]$/ ) {
		$format = '%Y%m%dT%H%M%S';
	}
	elsif ( $string =~ /^\d\d\d\d\d\d\d\d\/[0-2][0-9][0-5][0-9]$/ ) {
		$format = '%Y%m%dT%H%M';
	}
	elsif ( $string =~ /^\d\d\d\d\d\d\d\d\/[0-2][0-9][0-5][0-9][0-5][0-9]$/ ) {
		$format = '%Y%m%d/%H%M%S';

	}

	return $format, $regex;
}

=head2 guess_to_object

Takes the string, calles guess on it. If it gets a hit, it then returns
the Time::Piece object.

If it fails, undef is returned.

    $tp_object = Time::Piece::Guess->guess_to_object('2023-02-27T11:00:18');
    if (!defined( $tp_object )){
        print "No matching format found\n";
    }

=cut

sub guess_to_object {
	my $string = $_[1];

	if ( !defined($string) ) {
		return undef;
	}

	my ($format, $ms_clean_regex) = Time::Piece::Guess->guess($string);

	if ( !defined($format) ) {
		return undef;
	}

	if (defined( $ms_clean_regex )){
        $string=~s/$ms_clean_regex//;
    }

	my $t;
	eval { $t = Time::Piece->strptime( $string, $format ); };
	if ($@) {
		return undef;
	}

	return $t;
}

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
