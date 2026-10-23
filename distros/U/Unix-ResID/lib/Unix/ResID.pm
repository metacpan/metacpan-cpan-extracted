package Unix::ResID;
$Unix::ResID::VERSION = '0.002';
use strict;
use warnings;

use XSLoader;

XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

use Exporter 'import';
our @EXPORT_OK = qw/getresuid setresuid getresgid setresgid/;

1;

# ABSTRACT: Set all UIDs/GIDs safely

__END__

=pod

=encoding UTF-8

=head1 NAME

Unix::ResID - Set all UIDs/GIDs safely

=head1 VERSION

version 0.002

=head1 FUNCTIONS

=head2 getresuid

 ($ruid, $euid, $suid) = getresuid();

This gets all user ID values for the current process.

=head2 setresuid

 setresuid($ruid, $euid, $suid) // die '...';

This sets the user ID values for the current process. Any value set to C<-1> will be left alone. On error, undef is returned and C<$!> will be set.

=head2 getresgid

 ($rgid, $egid, $sgid) = getresgid();

This gets the group id values for the current process, not including any supplemental groups.

=head2 setresgid

 setresgid($rgid, $egid, $sgid) // die '...';

This sets the group ID values for the current process. Any value set to C<-1> will be left alone. On error, undef is returned and C<$!> will be set.

=head2 DESCRIPTION

This module provides C<setresuid> and friends. These functions allow one to get and atomically set the user and group identifiers for the current process.

There are three types of identifiers: real (who owns the process, relevant for quotas and signalling), effective (relevant for permissions), and saved (relevant for changing the other ids).

Any user may change any of these IDs to any of the other current values. Only with appropriate administrative permissions (typically the effective user ID must be C<0>) one may change them to arbitrary values.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
