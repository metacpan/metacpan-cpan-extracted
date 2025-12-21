# Copyright (c) 2025 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: generic module for extracting information from user accounts


package User::Information::Source::Local;

use v5.20;
use strict;
use warnings;

use Carp;
use List::Util qw(any);

use User::Information::Base;
use User::Information::Path;

our $VERSION = v0.05;

# ---- Private helpers ----

sub _discover {
    my ($pkg, $base, %opts) = @_;
    my @info;

    push(@info, {
            path => User::Information::Base->PATH_LOCAL_ISLOCAL,
            values => {bool => 1},
            rawtype => 'bool',
        });
    push(@info, {
            path => User::Information::Base->PATH_LOCAL_SYSAPI,
            loader => sub {
                my $v;

                if (any {$^O eq $_} qw(linux openbsd freebsd haiku)) {
                    $v = 'posix';
                } elsif ($^O eq 'MSWin32') {
                    $v = 'win32';
                }

                return [{raw => $v // die}];
            }
        });

    return @info;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

User::Information::Source::Local - generic module for extracting information from user accounts

=head1 VERSION

version v0.05

=head1 SYNOPSIS

    use User::Information::Source::Local;

This is a provider for local account meta configuration.

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
