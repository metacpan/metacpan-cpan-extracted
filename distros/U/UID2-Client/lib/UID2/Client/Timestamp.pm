package UID2::Client::Timestamp;
use strict;
use warnings;

use Time::HiRes qw(gettimeofday);

sub now {
    my $class = shift;
    $class->from_epoch_milli(int(gettimeofday() * 1000));
}

sub from_epoch_second {
    my ($class, $epoch_second) = @_;
    $class->from_epoch_milli($epoch_second * 1000);
}

sub from_epoch_milli {
    my ($class, $epoch_milli) = @_;
    bless \$epoch_milli, $class;
}

sub get_epoch_second {
    my $self = shift;
    int($$self / 1000);
}

sub get_epoch_milli {
    my $self = shift;
    $$self;
}

sub is_zero {
    my $self = shift;
    $$self == 0;
}

sub add_seconds {
    my ($self, $seconds) = @_;
    ref($self)->from_epoch_milli($$self + ($seconds * 1000));
}

sub add_days {
    my ($self, $days) = @_;
    $self->add_seconds($days * 24 * 60 * 60);
}

1;
__END__

=encoding utf-8

=head1 NAME

UID2::Client::Timestamp - Timestamp object for UID2::Client

=head1 SYNOPSIS

  use UID2::Client::Timestamp;

  my $timestamp = UID2::Client::Timestamp->now();

=head1 DESCRIPTION

Timestamp object for UID2::Client.

=head1 CONSTRUCTOR METHODS

=head2 now

  my $now = UID2::Client::Timestamp->now();

=head2 from_epoch_second

  my $timestamp = UID2::Client::Timestamp->from_epoch_second($epoch_second);

=head2 from_epoch_milli

  my $timestamp = UID2::Client::Timestamp->from_epoch_milli($epoch_milli);

=head1 METHODS

=head2 get_epoch_second

  my $epoch_second = $timestamp->get_epoch_second();

=head2 get_epoch_milli

  my $epoch_milli = $timestamp->get_epoch_milli();

=head2 is_zero

  my $is_zero = $timestamp->is_zero();

=head2 add_days

  my $new_timestamp = $timestamp->add_days($days);

=head2 add_seconds

  my $new_timestamp = $timestamp->add_seconds($seconds);

=head1 SEE ALSO

L<UID2::Client>

=head1 AUTHOR

Jiro Nishiguchi E<lt>jiro@cpan.orgE<gt>

=cut
