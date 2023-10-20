package UID2::Client::AdvertisingTokenVersion;
use strict;
use warnings;
use Exporter 'import';

use constant {
    V3 => 112,
    V4 => 128,
};

our @EXPORT_OK = qw(
    V3
    V4
);

1;
__END__

=encoding utf-8

=head1 NAME

UID2::Client::AdvertisingTokenVersion - Advertising Token Version Constants for UID2::Client

=head1 SYNOPSIS

  use UID2::Client::AdvertisingTokenVersion;

=head1 DESCRIPTION

This module defines constants for L<UID2::Client>.

=head1 CONSTANTS

=over

=item V3

=item V4

=back

=head1 SEE ALSO

L<UID2::Client>

=head1 LICENSE

Copyright (C) Jiro Nishiguchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jiro Nishiguchi E<lt>jiro@cpan.orgE<gt>

=cut
