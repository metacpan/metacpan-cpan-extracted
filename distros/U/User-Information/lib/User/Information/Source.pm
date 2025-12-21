# Copyright (c) 2025 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: generic module for extracting information from user accounts


package User::Information::Source;

use v5.20;
use strict;
use warnings;

use Carp;

our $VERSION = v0.05;

# ---- Private helpers ----
sub import {
    my ($pkg, @args) = @_;

    foreach my $mod (@args) {
        if ($mod =~ /^User::Information::Source:/ && $mod =~ s#::#/#g) {
            require $mod.'.pm';
        }
    }
}

sub _discover {
    my ($pkg, $base, %opts) = @_;
    croak 'BUG: Not implemented';
}

sub _load {
    my ($pkg, $source, $base, %opts) = @_;
    $pkg->import($source);
    return $source->_discover($base, %opts);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

User::Information::Source - generic module for extracting information from user accounts

=head1 VERSION

version v0.05

=head1 SYNOPSIS

    use User::Information::Source;

This module is the base package for data providers (sources).
All of it's API is internal.

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
