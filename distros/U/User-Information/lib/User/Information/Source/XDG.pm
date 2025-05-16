# Copyright (c) 2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: generic module for extracting information from user accounts


package User::Information::Source::XDG;

use v5.20;
use strict;
use warnings;

use Carp;
use File::HomeDir;
use File::BaseDir;

use User::Information::Path;

use constant PATH_HOMEDIR => User::Information::Path->new(['aggregate', 'homedir']);

our $VERSION = v0.02;

my @_homedir_keys = qw(home desktop documents music pictures videos data);

# ---- Private helpers ----

sub _load_homedir_me {
    my ($base, $info, $path) = @_;
    my $key = $path->_last_element_id;
    my $f = File::HomeDir->can('my_'.$key);
    my $v = defined($f) ? File::HomeDir->$f() : undef;

    return [{filename => $v // die}];
}
sub _load_homedir_user {
    my ($username, $base, $info, $path) = @_;
    my $key = $path->_last_element_id;
    my $f = File::HomeDir->can('users_'.$key);
    my $v = defined($f) ? File::HomeDir->$f($username) : undef;

    return [{filename => $v // die}];
}

sub _load_basedir_me {
    my ($base, $info, $path) = @_;
    state $basedir = File::BaseDir->new;
    my $key = $path->_last_element_id;
    my $f = $basedir->can('xdg_'.$key);

    if ($key =~ /_home$/) {
        # scalar
        my $v = defined($f) ? $basedir->$f() : undef;

        return [{filename => $v // die}];
    } else {
        # list
        my @v = defined($f) ? $basedir->$f() : undef;

        die unless scalar @v;
        return [map {{filename => $_ // die}} @v];
    }
}

sub _discover {
    my ($pkg, $base, %opts) = @_;
    my $root = User::Information::Path->new('xdg');
    my $homedir = User::Information::Path->new($root => 'homedir');
    my $basedir = User::Information::Path->new($root => 'basedir');
    my @info;

    if ($opts{me}) {
        foreach my $key (@_homedir_keys) {
            push(@info, {
                    path => User::Information::Path->new($homedir => $key),
                    loader => \&_load_homedir_me,
                });
        }

        foreach my $key (
            qw(data_home config_home cache_home),
            qw(data_dirs config_dirs),
        ) {
            push(@info, {
                    path => User::Information::Path->new($basedir => $key),
                    loader => \&_load_basedir_me,
                });
        }
    }

    if (defined $opts{username}) {
        foreach my $key (@_homedir_keys) {
            push(@info, {
                    path => User::Information::Path->new($homedir => $key),
                    loader => sub {_load_homedir_user($opts{username}, @_)},
                });
        }
    }

    {
        my $basedir = File::BaseDir->new;
        foreach my $filename ($basedir->config_files('user-dirs.defaults'), $basedir->config_files('user-dirs.dirs')) {
            open(my $fh, '<', $filename) or next;
            while (defined(my $line = <$fh>)) {
                if ($line =~ /^\s*XDG_([A-Z]+)_DIR="\$HOME\/([^"]+)"/) {
                    my ($key, $value) = ($1, $2);
                    push(@info, {
                            path => User::Information::Path->new($root => [userdir => $key]),
                            loader => sub { [{filename => $_[0]->file(PATH_HOMEDIR, extra => $value, directory => 1)}] },
                        });
                } elsif ($line =~ /^\s*([A-Z]+)=([^#]+)\s*(?:#.*)?\r?\n/) {
                    my ($key, $value) = ($1, $2);
                    push(@info, {
                            path => User::Information::Path->new($root => [defaultdir => $key]),
                            loader => sub { [{filename => $_[0]->file(PATH_HOMEDIR, extra => $value, directory => 1)}] },
                        });
                }
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

User::Information::Source::XDG - generic module for extracting information from user accounts

=head1 VERSION

version v0.02

=head1 SYNOPSIS

    use User::Information::Source::XDG;

This is a provider for filesystem configuration using the XDG standards.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
