# Copyright (c) 2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: generic module for extracting information from user accounts


package User::Information::Source::CGI;

use v5.20;
use strict;
use warnings;

use Carp;
use List::Util qw(any);

use User::Information::Base;
use User::Information::Path;

our $VERSION = v0.03;

# ---- Private helpers ----

sub _discover {
    my ($pkg, $base, %opts) = @_;
    my @info;

    push(@info, {
            path => User::Information::Path->new([qw(cgi iscgi)]),
            values => {bool => 1},
            rawtype => 'bool',
        });

    push(@info, {
            path => User::Information::Path->new([qw(cgi username)]),
            values => {raw => $ENV{REMOTE_USER}},
        }) if defined($ENV{REMOTE_USER}) && length($ENV{REMOTE_USER});

    return @info;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

User::Information::Source::CGI - generic module for extracting information from user accounts

=head1 VERSION

version v0.03

=head1 SYNOPSIS

    use User::Information::Source::CGI;

This is a provider for CGI (Common Gateway Interface) data.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
