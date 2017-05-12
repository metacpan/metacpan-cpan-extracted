package Time::Piece::DB2;

use strict;

use vars qw($VERSION);

$VERSION = '0.05';

use Time::Piece;

sub import { shift; @_ = ('Time::Piece', @_); goto &Time::Piece::import }

package Time::Piece;

use Time::Seconds;

# BEGIN
# {
#     my $has_dst_bug =
# 	Time::Piece->strptime( '20000601120000', '%Y%m%d%H%M%S' )->hour != 12;
#     sub HAS_DST_BUG () { $has_dst_bug }
# }

sub db2_date
{
    my $self = shift;
    my $old_sep = $self->date_separator('-');
    my $ymd = $self->ymd;
    $self->date_separator($old_sep);
    return $ymd;
}

sub db2_time
{
    my $self = shift;
    my $old_sep = $self->time_separator(':');
    my $hms = $self->hms;
    $self->time_separator($old_sep);
    return $hms;
}

sub db2_timestamp
{
    my $self = shift;
    return join ' ', $self->db2_date, $self->db2_time;
}

sub from_db2_date
{
    my $class = shift;
    return $class->strptime( shift, '%Y-%m-%d' );
}

sub from_db2_time
{
    my ($class,$tstamp) = @_;
    $tstamp = substr($tstamp,0,length($tstamp)-7);
    return $class->strptime( $tstamp, '%H:%M:%S' );
}

sub from_db2_timestamp
{
    my ($class,$tstamp) = @_;
    $tstamp = substr($tstamp,0,length($tstamp)-7);
    my $time = $class->strptime( $tstamp, '%Y-%m-%d %H:%M:%S' );
    return $time;
}

1;

__END__

=head1 NAME

Time::Piece::DB2 - Adds DB2-specific methods to Time::Piece

=head1 SYNOPSIS

  use Time::Piece::DB2;

  my $time = localtime;

  print $time->db2_date;
  print $time->db2_time;
  print $time->db2_timestamp;

  my $time = Time::Piece->from_db2_date( $db2_date );
  my $time = Time::Piece->from_db2_time( $db2_time );
  my $time = Time::Piece->from_db2_timestamp( $db2_timestamp );

=head1 DESCRIPTION

Using this module instead of, or in addition to C<Time::Piece> adds a
few DB2-specific date/time methods to C<Time::Piece> objects.

=head1 OBJECT METHODS

=over 4

=item * db2_date

=item * db2_time

=item * db2_timestamp

Returns the date and/or time in a format suitable for use by DB2.

=back

=head1 CONSTRUCTORS

=over 4

=item * from_db2_date

=item * from_db2_time

=item * from_db2_timestamp

Given a date, time, or timestamp as returned from DB2, these
constructors return a new Time::Piece object.

=back

=head1 BUGS

C<Time::Piece> itself only works with times in the Unix epoch, this
module has the same limitation.  However, DB2 itself handles date
and timestamp columns from '1000-01-01'.  Feeding in
times outside of the Unix epoch to any of the constructors has
unpredictable results.

=head1 AUTHOR

Author: Mark Ferris <m.ferris@geac.com>

=head1 COPYRIGHT

(c) 2004 Mark Ferris

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Time::Piece>

=cut
