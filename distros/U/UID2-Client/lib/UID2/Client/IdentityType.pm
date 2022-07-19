package UID2::Client::IdentityType;
use strict;
use warnings;
use Exporter 'import';

use constant {
    EMAIL => 0,
    PHONE => 1,
};

our @EXPORT_OK = qw(
    EMAIL
    PHONE
);

1;
__END__

=encoding utf-8

=head1 NAME

UID2::Client::IdentityType - Identity Type Constants for UID2::Client

=head1 SYNOPSIS

  use UID2::Client::IdentityType;

=head1 DESCRIPTION

This module defines constants for L<UID2::Client>.

=head1 CONSTANTS

=over

=item EMAIL

=item PHONE

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
