# Copyright (c) 2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: generic module for extracting information from user accounts


package User::Information::Source::POSIX;

use v5.20;
use strict;
use warnings;

use Carp;
use List::Util qw(any);

use User::Information::Path;

our $VERSION = v0.01;

my %_keys_getpwuid = (
    dir     => 'filename',
    shell   => 'filename',
);
my @_keys_getpwuid = qw(name passwd uid gid quota comment gcos dir shell expire);
my @_keys_getgrgid = qw(name passwd gid members);
my @_keys_uname    = qw(sysname nodename release version machine);

# ---- Private helpers ----

sub _load_getpwuid {
    my ($base, $info, $qkey, $subroot, $uid, $root, $key) = @_;
    my @d = getpwuid($uid);

    for (my $i = 0; $i < scalar(@_keys_getpwuid); $i++) {
        if (defined($d[$i]) && length($d[$i])) {
            my $dkey = $_keys_getpwuid[$i];
            my $v = {($_keys_getpwuid{$dkey} // 'raw') => $d[$i]};

            $base->_value_add(User::Information::Path->new($subroot => $dkey), $v);
            if ($dkey eq 'name') {
                $base->_value_add(User::Information::Path->new($root => [$dkey => $key]), $v);
            } elsif ($dkey eq 'gcos') {
                my $fn = {%{$v}};
                $fn->{(keys %{$fn})[0]} =~ s/\s*,.*$//;
                $base->_value_add(User::Information::Path->new($root => [fullname => $key]), $fn);
            }
        }
    }

    return undef;
}

sub _load_getgrgid {
    my ($base, $info, $qkey, $subroot, $gid, $root, $key) = @_;
    my @d = getgrgid($gid);

    for (my $i = 0; $i < scalar(@_keys_getgrgid); $i++) {
        if (defined($d[$i]) && length($d[$i])) {
            my $dkey = $_keys_getgrgid[$i];
            my $v = {raw => $d[$i]};
            $base->_value_add(User::Information::Path->new($subroot => $dkey), $v);
            if ($dkey eq 'name') {
                $base->_value_add(User::Information::Path->new($root => [$dkey => $key]), $v);
            }
        }
    }

    return undef;
}

sub _load_uname {
    my ($base, $info, $qkey) = @_;
    my $subroot = User::Information::Path->new(['posix' => 'uname']);
    my @d;

    require POSIX;

    @d = POSIX::uname();

    for (my $i = 0; $i < scalar(@_keys_uname); $i++) {
        if (defined($d[$i]) && length($d[$i])) {
            my $dkey = $_keys_uname[$i];
            my $v = {raw => $d[$i]};
            $base->_value_add(User::Information::Path->new($subroot => $dkey), $v);
        }
    }
}

sub _discover {
    my ($pkg, $base, %opts) = @_;
    my $data = $opts{data};
    my $root = User::Information::Path->new('posix');
    my @info;

    foreach my $type (keys %{$data}) {
        my $value = $data->{$type};
        my @value = ($value);
        my $subroot = User::Information::Path->new($root => $type);

        if ($type eq 'user' || $type eq 'real_user' || $type eq 'effective_user') {
            @value = split(/\s+/, $value);
            $value = $value[0];

            foreach my $key (@_keys_getpwuid) {
                my $path = User::Information::Path->new($subroot => $key);
                push(@info, {
                        loadpath => $subroot,
                        path => $path,
                        loader => sub { my ($base, $info, $qkey) = @_; _load_getpwuid($base, $info, $qkey, $subroot, $value, $root, $type); },
                    });
            }
            push(@info, {
                    loadpath => $subroot,
                    path => User::Information::Path->new($root => ['name' => $type]),
                    loader => sub { my ($base, $info, $qkey) = @_; _load_getpwuid($base, $info, $qkey, $subroot, $value, $root, $type); },
                });
            push(@info, {
                    loadpath => $subroot,
                    path => User::Information::Path->new($root => ['fullname' => $type]),
                    loader => sub { my ($base, $info, $qkey) = @_; _load_getpwuid($base, $info, $qkey, $subroot, $value, $root, $type); },
                });
        } elsif ($type eq 'group' || $type eq 'real_group' || $type eq 'effective_group') {
            @value = split(/\s+/, $value);
            $value = $value[0];

            foreach my $key (@_keys_getgrgid) {
                my $path = User::Information::Path->new($subroot => $key);
                push(@info, {
                        loadpath => $subroot,
                        path => $path,
                        loader => sub { my ($base, $info, $qkey) = @_; _load_getgrgid($base, $info, $qkey, $subroot, $value, $root, $type); },
                    });
            }
            push(@info, {
                    loadpath => $subroot,
                    path => User::Information::Path->new($root => ['name' => $type]),
                    loader => sub { my ($base, $info, $qkey) = @_; _load_getgrgid($base, $info, $qkey, $subroot, $value, $root, $type); },
                });
        } elsif ($type eq 'uname') {
            foreach my $key (@_keys_uname) {
                my $path = User::Information::Path->new($subroot => $key);
                push(@info, {
                        loadpath => $subroot,
                        path => $path,
                        loader => \&_load_uname,
                    });
            }
        }

        push(@info, {
                path => User::Information::Path->new($root => [id => $type]),
                loader => sub { [map {{raw => $_}} @value] },
            }) if defined $value;
    }

    return @info;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

User::Information::Source::POSIX - generic module for extracting information from user accounts

=head1 VERSION

version v0.01

=head1 SYNOPSIS

    use User::Information::Source::POSIX;

This is a provider for account data via the POSIX API.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
