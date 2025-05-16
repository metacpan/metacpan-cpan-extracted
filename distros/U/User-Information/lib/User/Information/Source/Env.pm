# Copyright (c) 2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: generic module for extracting information from user accounts


package User::Information::Source::Env;

use v5.20;
use strict;
use warnings;

use Carp;

use User::Information::Path;

our $VERSION = v0.02;

# ---- Private helpers ----

sub _raw_loader {
    my ($base, $info, $key) = @_;
    my $v = $ENV{$key->_last_element_id} // die;

    return [{raw => $v}];
}

sub _discover {
    my ($pkg, $base, %opts) = @_;
    my $root = User::Information::Path->new('env');
    my @info;

    foreach my $key (keys %ENV) {
        my $path = User::Information::Path->new($root, [environ => $key]);
        push(@info, {
                path => $path,
                loader => \&_raw_loader,
            });
    }

    return @info;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

User::Information::Source::Env - generic module for extracting information from user accounts

=head1 VERSION

version v0.02

=head1 SYNOPSIS

    use User::Information::Source::Env;

This is a provider using C<%ENV>

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
