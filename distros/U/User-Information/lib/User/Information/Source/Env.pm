# Copyright (c) 2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: generic module for extracting information from user accounts


package User::Information::Source::Env;

use v5.20;
use strict;
use warnings;

use Carp;

use User::Information::Path;

our $VERSION = v0.03;

my %_cgi_var = map {$_ => 1} qw(AUTH_TYPE CONTENT_LENGTH CONTENT_TYPE PATH_INFO PATH_TRANSLATED QUERY_STRING REMOTE_ADDR REMOTE_HOST REMOTE_IDENT REMOTE_USER REQUEST_METHOD SCRIPT_NAME SERVER_NAME SERVER_PORT SERVER_PROTOCOL SERVER_SOFTWARE);

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
    my $matcher;

    if ($ENV{SERVER_PROTOCOL} =~ /^HTTP\//) {
        $opts{cgi} //= 1;
        $matcher = qr/^HTTP_/;
    }

    foreach my $key (keys %ENV) {
        if (!$opts{cgi} || $_cgi_var{$key} || (defined($matcher) && $key =~ $matcher)) {
            my $path = User::Information::Path->new($root, [environ => $key]);
            push(@info, {
                    path => $path,
                    loader => \&_raw_loader,
                });
        }
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

version v0.03

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
