# Copyright (c) 2025 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: generic module for extracting information from user accounts


package User::Information::Source::LocalNodeMisc;

use v5.20;
use strict;
use warnings;

use Carp;
use Sys::Hostname;

use User::Information::Path;

our $VERSION = v0.05;

# ---- Private helpers ----

sub _discover {
    my ($pkg, $base, %opts) = @_;
    my $root = User::Information::Path->new('localnodemisc');
    my @info;

    if ($base->_is_local) {
        push(@info, {
                path => User::Information::Path->new($root => 'hostname'),
                loader => sub {[{raw => hostname()}]},
            });
    }

    return @info;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

User::Information::Source::LocalNodeMisc - generic module for extracting information from user accounts

=head1 VERSION

version v0.05

=head1 SYNOPSIS

    use User::Information::Source::LocalNodeMisc;

This is a provider for misc info on the local node.

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
