# Copyright (c) 2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: generic module for extracting information from user accounts


package User::Information::Source::Tagpool;

use v5.20;
use strict;
use warnings;

use Carp;
use File::Spec;
use File::ValueFile::Simple::Reader;

use User::Information::Base;
use User::Information::Path;

our $VERSION = v0.03;

my %_typeinfo = (
    (map {$_ => 'bool'}             qw(directory-add-analyze file-on-unlink-to-tag pool-lazy-cache-reload pool-lazy-store-reload httpd-reuse-address)),
    (map {$_ => 'filename'}         qw(httpd-htdirectories httpd-htpasswd httpd-ng-webdir httpd-ng-webdir-assets httpd-webdir httpd-webdir-assets pool pool-path tags-package-dir tags-universal-dir)),
    (map {$_ => 'Data::Identifier'} qw(pool-uuid)),
);

# ---- Private helpers ----

sub _discover {
    my ($pkg, $base, %opts) = @_;
    my @info;

    if ($base->_is_local) {
        my $root = User::Information::Path->new('tagpool');
        my $home = $base->get([qw(aggregate homedir)], default => undef, as => 'filename');
        my @configs = ('/etc/tagpoolrc');
        my @poolpaths;
        my %pools;
        my %global;

        if (defined $home) {
            push(@configs, File::Spec->catfile($home => '.tagpoolrc'));
        }

        # find tagpool configs
        foreach my $filename (@configs) {
            my $hash = eval {File::ValueFile::Simple::Reader->new($filename)->read_as_hash};
            if (defined $hash) {
                %global = (%global, %{$hash});
            }
        }

        foreach my $key (keys %global) {
            my ($v, $type) = _cast($global{$key}, $key);

            push(@info, {
                    path => User::Information::Path->new($root => [global => config => $key]),
                    values => {$type => $v},
                    rawtype => $type,
                });
        }

        push(@poolpaths, grep {defined} @global{qw(pool-path pool)});

        foreach my $poolpath (@poolpaths) {
            my $filename = File::Spec->catfile($poolpath => 'config');
            my $hash = eval {File::ValueFile::Simple::Reader->new($filename)->read_as_hash};
            if (defined $hash) {
                %{$hash} = (%global, %{$hash});
                if (defined(my $uuid = $hash->{'pool-uuid'})) {
                    my $path = User::Information::Path->new($root => [pool => Data::Identifier->new(uuid => $uuid) => 'config']);

                    $pools{$uuid} = $poolpath;

                    foreach my $key (keys %{$hash}) {
                        my ($v, $type) = _cast($hash->{$key}, $key);

                        push(@info, {
                                path => User::Information::Path->new($path => $key),
                                values => {$type => $v},
                                rawtype => $type,
                            });
                    }
                }
            }
        }

        push(@info, {
                path => User::Information::Path->new($root => 'roots'),
                values => [map {{filename => $_}} values %pools],
            }) if scalar keys %pools;
    }

    return @info;
}

sub _cast {
    my ($value, $key) = @_;
    my $type = $_typeinfo{$key} // 'raw';

    if ($type eq 'bool') {
        $value = defined($value) && $value eq 'true';
    } elsif ($type eq 'Data::Identifier') {
        $value = Data::Identifier->new(ise => $value);
    }

    return ($value, $type);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

User::Information::Source::Tagpool - generic module for extracting information from user accounts

=head1 VERSION

version v0.03

=head1 SYNOPSIS

    use User::Information::Source::Tagpool;

This is a provider for tagpool data.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
