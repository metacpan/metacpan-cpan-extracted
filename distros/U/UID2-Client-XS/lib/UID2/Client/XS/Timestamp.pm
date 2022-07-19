package UID2::Client::XS::Timestamp;
use strict;
use warnings;

1;
__END__

=encoding utf-8

=head1 NAME

UID2::Client::XS::Timestamp - Timestamp object for UID2::Client::XS

=head1 SYNOPSIS

  use UID2::Client::XS;

  my $timestamp = UID2::Client::XS::Timestamp->now();

=head1 DESCRIPTION

Timestamp object for UID2::Client::XS.

=head1 CONSTRUCTOR METHODS

=head2 now

  my $now = UID2::Client::XS::Timestamp->now();

=head2 from_epoch_second

  my $timestamp = UID2::Client::XS::Timestamp->from_epoch_second($epoch_second);

=head2 from_epoch_milli

  my $timestamp = UID2::Client::XS::Timestamp->from_epoch_milli($epoch_milli);

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

L<UID2::Client::XS>

=head1 AUTHOR

Jiro Nishiguchi E<lt>jiro@cpan.orgE<gt>

=cut
