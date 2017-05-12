package Ubic::Credentials;
$Ubic::Credentials::VERSION = '1.60';
use strict;
use warnings;

# ABSTRACT: base class for OS-specific credential methods


use List::MoreUtils qw(uniq);

use Params::Validate qw(:all);
use Carp;

our $OS_CLASS;

sub import {
    my %module = (
        MSWin32 => 'Windows',
        darwin  => 'MacOSX',
    );

    my $module = $ENV{UBIC_CREDENTIALS_OS} || $ENV{UBIC_OS} || $module{$^O} || 'POSIX';

    require "Ubic/Credentials/OS/$module.pm";
    $OS_CLASS = "Ubic::Credentials::OS::$module";
}


sub new {
    my $class = shift;
    return $OS_CLASS->new(@_) if $class eq 'Ubic::Credentials';
    croak 'constructor not implemented';
}

sub set_effective {
    croak 'not implemented';
}

sub reset_effective {
    croak 'not implemented';
}

sub eq {
    croak 'not implemented';
}

sub set {
    croak 'not implemented';
}

sub as_string {
    my $self = shift;
    return "$self"; # ugly default stringification; please override in subclasses
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Ubic::Credentials - base class for OS-specific credential methods

=head1 VERSION

version 1.60

=head1 SYNOPSIS

    $creds = Ubic::Credentials->new(user => "mmcleric", group => ["ppb"]);
    $creds = Ubic::Credentials->new(); # current credentials
    $creds = Ubic::Credentials->new(service => $service); # credentials from the given service

    $creds->set_effective; # change effective credentials only, enables tainted mode
    $creds->reset_effective; # back to normality

    $creds->eq(Ubic::Credentials->new); # check if set() call is required to apply the credentials
    $creds->set; # apply all credentials; there is no way back

=head1 METHODS

=over

=item B<< new() >>

=item B<< new(service => $service) >>

=item B<< new(user => $user, group => $group) >>

Constructor.

It constructs credentials with current user and group if no parameters are specified, takes user and group from given service if I<service> parameter is specified or uses any I<user> and I<group> which you pass directly to it.

=item B<< set_effective() >>

Set credentials user and group as effective user and group.

=item B<< reset_effective() >>

Restore effective user and group to their original values.

=item B<< eq($other_creds) >>

Compare current creds with other creds object.

Returns true value if credentials are equivalent.

=item B<< set() >>

Set credentials as effective and real group and user permanently.

=item B<< as_string() >>

Returns human-readable string representation.

=back

=head1 AUTHOR

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
