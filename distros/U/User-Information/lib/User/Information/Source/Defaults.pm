# Copyright (c) 2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: generic module for extracting information from user accounts


package User::Information::Source::Defaults;

use v5.20;
use strict;
use warnings;

use Carp;
use File::Spec;

use User::Information::Path;

our $VERSION = v0.03;

use constant PATH_HOMEDIR => User::Information::Path->new(['aggregate', 'homedir']);

my %_defaults = (
    files => {
        (map {my $x = $_; $x => sub {_load_file(@_[0..2], PATH_HOMEDIR, '.'.$x)}} qw(plan project netrc)),
    },
);

# ---- Private helpers ----

sub _load_file {
    my ($base, $info, $key, $prekey, $filename) = @_;
    my $v = $base->get($prekey, as => 'filename');

    return [{filename => File::Spec->catfile($v, $filename)}];
}

sub _discover__subpath {
    my ($info, $subroot, $subpath) = @_;

    if (ref($subpath) eq 'HASH') {
        foreach my $key (keys %{$subpath}) {
            _discover__subpath($info, User::Information::Path->new($subroot => $key), $subpath->{$key});
        }
        return;
    }

    if (ref($subpath) eq 'CODE') {
        push(@{$info}, {
                path => $subroot,
                loader => $subpath,
            });
    } else {
        push(@{$info}, {
                path => $subroot,
                values => {raw => $subpath},
            });
    }
}

sub _discover {
    my ($pkg, $base, %opts) = @_;
    my $root = User::Information::Path->new('defaults');
    my @info;

    _discover__subpath(\@info, $root, \%_defaults);

    return @info;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

User::Information::Source::Defaults - generic module for extracting information from user accounts

=head1 VERSION

version v0.03

=head1 SYNOPSIS

    use User::Information::Source::Defaults;

This is a provider for defaults.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
