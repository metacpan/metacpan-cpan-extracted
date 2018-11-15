package Time::Moment::Ext;

use strict;
use warnings;
use Time::Piece;

use parent 'Time::Moment';

our $VERSION = '0.06';

my $SQL_FORMAT = '%Y-%m-%d %H:%M:%S';
my $SQL_DATE = '%Y-%m-%d';
my $SQL_TIME = '%H:%M:%S';

sub Time::Moment::strptime {
    my ($class, $str, $format) = @_;
    return unless ($str && $format);

    return $class->from_object(scalar localtime->strptime($str, $format));
}

sub Time::Moment::from_datetime {
    my ($class, $str) = @_;
	return unless $str;

    return $class->strptime($str, $SQL_FORMAT);
}

sub Time::Moment::to_datetime {
    return shift->strftime($SQL_FORMAT);
}

sub Time::Moment::to_date {
	return shift->strftime($SQL_DATE);
}

sub Time::Moment::to_time {
	return shift->strftime($SQL_TIME);
}

sub Time::Moment::day {
	return shift->day_of_month;
}

1;
__END__

=encoding utf-8

=head1 NAME

Time::Moment::Ext - Extend Time::Moment with strptime and SQL dates support

=head1 SYNOPSIS

	use Time::Moment::Ext;
	
	my $tm = Time::Moment::Ext->from_datetime('2015-01-18');
	
	my $tm2 = Time::Moment::Ext->from_datetime('2015-01-20 10:33:45');

	my $tm3 = Time::Moment::Ext->strptime('2015-01-20 10:33:45', '%Y-%m-%d %H:%M:%S');

	say $tm->to_datetime;

	say $tm2->to_date;

	say $tm3->to_time;

	say $tm->day;
	
	# (you can use all other methods from Time::Moment)

=head1 DESCRIPTION

Time::Moment::Ext - Extend Time::Moment with strptime and SQL dates support

=head1 SUBROUTINES/METHODS

=head2 strptime

The method use all strptime features from L<Time::Piece>

=head2 from_datetime

Converting SQL data/datetime string to Time::Moment object

=head2 to_datetime

Converting Time::Moment object to SQL datetime string

=head2 to_date

Converting Time::Moment object to date string

=head2 to_time

Converting Time::Moment object to time string

=head2 day

Return the day of month (alias to day_of_month)

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DIAGNOSTICS

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 DEPENDENCIES

=over

=item L<Time::Moment>

=item L<Time::Piece>

=back

=head1 VERSION

version 0.06

=head1 AUTHOR

Konstantin Cherednichenko E<lt>dshadowukraine@gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 (c) Konstantin Cherednichenko.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

=cut

