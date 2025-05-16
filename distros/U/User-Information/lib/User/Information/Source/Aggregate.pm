# Copyright (c) 2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: generic module for extracting information from user accounts


package User::Information::Source::Aggregate;

use v5.20;
use strict;
use warnings;

use Carp;

use User::Information::Path;

our $VERSION = v0.02;

my %_paths = (
    username    => [qw(posix/real_user/name     posix/user/name)],
    fullname    => [qw(git/global/user/name posix/fullname/real_user posix/fullname/user)],
    email       => [qw(git/global/user/email)],
    homedir     => [qw(xdg/homedir/home posix/real_user/dir posix/user/dir)],
    hostname    => [qw(localnodemisc/hostname posix/uname/nodename)],
    displayname => [qw(aggregate/fullname aggregate/username aggregate/email aggregate/hostname)],
);

my %_storage = (
    rw => {
        home        => [qw(aggregate/homedir)],
        desktop     => [qw(xdg/homedir/desktop      xdg/userdir/DESKTOP     xdg/defaultdir/DESKTOP)],
        documents   => [qw(xdg/homedir/documents    xdg/userdir/DOCUMENTS   xdg/defaultdir/DOCUMENTS)],
        music       => [qw(xdg/homedir/music        xdg/userdir/MUSIC       xdg/defaultdir/MUSIC)],
        pictures    => [qw(xdg/homedir/pictures     xdg/userdir/PICTURES    xdg/defaultdir/PICTURES)],
        videos      => [qw(xdg/homedir/videos       xdg/userdir/VIDEOS      xdg/defaultdir/VIDEOS)],
        downloads   => [qw(                         xdg/userdir/DOWNLOAD    xdg/defaultdir/DOWNLOAD)],
        templates   => [qw(                         xdg/userdir/TEMPLATES   xdg/defaultdir/TEMPLATES)],
        publicshare => [qw(                         xdg/userdir/PUBLICSHARE xdg/defaultdir/PUBLICSHARE)],
        cache       => [qw(xdg/basedir/cache_home)],
        config      => [qw(xdg/basedir/config_home)],
    },
    ro => {},
);

$_storage{ro}{$_} //= $_storage{rw}{$_} foreach keys %{$_storage{rw}};

foreach my $b (values %_storage) {
    foreach my $v (values %{$b}) {
        $v = {directory => $v} if ref($v) eq 'ARRAY';
    }
}

foreach my $v (values(%_paths), map {values %{$_}} map {values %{$_}} values %_storage) {
    foreach my $p (@{$v}) {
        $p = User::Information::Path->new([split(m#/#, $p)]) unless ref $p;
    }
}

# ---- Private helpers ----
sub _load_paths {
    my ($base, $paths) = @_;

    foreach my $source (@{$paths}) {
        eval {$base->get($source, default => [], list => 1)};
        if (defined(my $values = $base->{data}{$source->_hashkey})) { # steal values!
            return $values;
        }
    }

    die;
}

sub _load_paths_nohome {
    my ($base, $paths) = @_;
    my $home = eval {$base->get([qw(aggregate homedir)], default => undef, as => 'filename')};

    unless ($home) {
        goto &_load_paths;
    }

    outer:
    foreach my $source (@{$paths}) {
        foreach my $c (eval {$base->get($source, default => [], list => 1, as => 'filename')}) {
            if ($c eq $home) {
                next outer;
            }
        }

        if (defined(my $values = $base->{data}{$source->_hashkey})) { # steal values!
            return $values;
        }
    }

    die;
}

sub _load {
    my ($base, $info, $path) = @_;
    my $key = $path->_last_element_id;

    return _load_paths($base, $_paths{$key});
}

sub _discover {
    my ($pkg, $base, %opts) = @_;
    my $root = User::Information::Path->new('aggregate');
    my @info;

    foreach my $subpath (keys %_paths) {
        push(@info, {
                path => User::Information::Path->new($root => $subpath),
                loader => \&_load,
            });
    }

    foreach my $dir (keys %_storage) {
        my $b = $_storage{$dir};

        foreach my $key (keys %{$b}) {
            my $d = $b->{$key};
            foreach my $dkey (keys %{$d}) {
                push(@info, {
                        path => User::Information::Path->new($root => [storage => $key => $dir => $dkey]),
                        loader => $key eq 'home' ? sub {_load_paths($_[0], $d->{$dkey})} : sub {_load_paths_nohome($_[0], $d->{$dkey})},
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

User::Information::Source::Aggregate - generic module for extracting information from user accounts

=head1 VERSION

version v0.02

=head1 SYNOPSIS

    use User::Information::Source::Aggregate;

This is a provider for aggregated values.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
