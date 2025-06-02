# Copyright (c) 2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: generic module for extracting information from user accounts


package User::Information::Source::VFS;

use v5.20;
use strict;
use warnings;

use Carp;
use File::Spec;

use User::Information::Path;

our $VERSION = v0.03;

# ---- Private helpers ----

sub _discover {
    my ($pkg, $base, %opts) = @_;
    my $root = User::Information::Path->new('vfs');
    my @info;

    if ($base->_is_local) {
        foreach my $key (qw(curdir updir tmpdir rootdir devnull)) {
            my $f = File::Spec->can($key);
            my $v = defined($f) ? File::Spec->$f() : undef;
            if (defined $v) {
                push(@info, {
                        path => User::Information::Path->new($root, $key),
                        values => {filename => $v},
                    });
            }
        }
    }

    return @info;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

User::Information::Source::VFS - generic module for extracting information from user accounts

=head1 VERSION

version v0.03

=head1 SYNOPSIS

    use User::Information::Source::VFS;

This is a provider for filesystem configuration.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
