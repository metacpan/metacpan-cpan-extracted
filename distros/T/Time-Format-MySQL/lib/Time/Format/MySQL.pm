package Time::Format::MySQL;
use 5.008005;
use strict;
use warnings;
use Carp qw(croak);
use Time::Piece ();
use parent qw(Exporter);
our @EXPORT_OK = qw(from_unixtime unix_timestamp);
our $VERSION = "0.03";

my $DEFAULT_FORMAT = '%Y-%m-%d %H:%M:%S';

sub from_unixtime {
    my $unixtime = shift or croak('Incorrect parameter count');
    my $format   = shift || $DEFAULT_FORMAT;
    Time::Piece::localtime($unixtime)->strftime($format);
}

sub unix_timestamp {
    my $datetime = shift or return time;
    my $format   = shift || $DEFAULT_FORMAT;
    Time::Piece::localtime->strptime($datetime, $format)->epoch;
}

1;
__END__

=encoding utf-8

=head1 NAME

Time::Format::MySQL - provides from_unixtime() and unix_timestamp()

=head1 SYNOPSIS

    use Time::Format::MySQL qw(from_unixtime unix_timestamp)

    print from_unixtime(time); #=> 2013-01-11 12:03:28
    print unix_timestamp('2013-01-11 12:03:28'); #=> 1357873408

=head1 DESCRIPTION

Time::Format::MySQL provides mysql-like functions, from_unixtime() and unix_timestamp().

=head1 FUNCTIONS

=over

=item from_unixtime($unixtime [, $format])

unix timestamp -> date time

=item unix_timestamp($datetime [, $format])

date time -> unix timestamp

=back

=head1 SEE ALSO

=over

=item L<DateTime::Format::MySQL>

=item L<Time::Piece::MySQL>

=back

=head1 LICENSE

Copyright (C) Hiroki Honda.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Hiroki Honda E<lt>cside.story@gmail.comE<gt>

=cut

