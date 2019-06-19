package WebService::MinFraud::Data::Rx::Type::Hostname;

use 5.010;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '1.009001';

use Data::Validate::Domain qw( is_hostname );

use parent 'Data::Rx::CommonType::EasyNew';

use Role::Tiny::With;

with 'WebService::MinFraud::Role::Data::Rx::Type';

sub assert_valid {
    my ( $self, $value ) = @_;

    # We use is_hostname rather than is_domain as Net::Domain::TLD cannot keep
    # up with all of the new gTLDs
    return 1 if is_hostname($value);

    $self->fail(
        {
            error   => [qw(type)],
            message => 'Found value is not a valid host name.',
            value   => $value,
        }
    );
}

sub type_uri {
    'tag:maxmind.com,MAXMIND:rx/hostname';
}

1;

# ABSTRACT: A type to check for a valid host name

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::MinFraud::Data::Rx::Type::Hostname - A type to check for a valid host name

=head1 VERSION

version 1.009001

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/minfraud-api-perl/issues>.

=head1 AUTHOR

Mateu Hunter <mhunter@maxmind.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 - 2019 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
