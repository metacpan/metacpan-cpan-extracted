package UID2::Client::IdentityScope;
use strict;
use warnings;
use Exporter 'import';

use constant {
    UID2 => 0,
    EUID => 1,
};

our @EXPORT_OK = qw(
    UID2
    EUID
);

1;
__END__

=encoding utf-8

=head1 NAME

UID2::Client::IdentityScope - Identity Scope Constants for UID2::Client

=head1 SYNOPSIS

  use UID2::Client::IdentityScope;

=head1 DESCRIPTION

This module defines constants for L<UID2::Client>.

=head1 CONSTANTS

=over

=item UID2

=item EUID

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
