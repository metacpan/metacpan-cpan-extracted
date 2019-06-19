package WebService::MinFraud::Data::Rx::Type::IPAddress;

use 5.010;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '1.009001';

use Data::Validate::IP;

use parent 'Data::Rx::CommonType::EasyNew';

use Role::Tiny::With;

with 'WebService::MinFraud::Role::Data::Rx::Type';

sub assert_valid {
    my ( $self, $value ) = @_;

    return 1
        if $value
        && ( Data::Validate::IP::is_ipv4($value)
        || Data::Validate::IP::is_ipv6($value) );

    $self->fail(
        {
            error => [qw(type)],
            message =>
                'Found value is not an IP address, neither version 4 nor 6.',
            value => $value,
        }
    );
}

sub type_uri {
    ## no critic(ValuesAndExpressions::ProhibitCommaSeparatedStatements)
    'tag:maxmind.com,MAXMIND:rx/ip';
}

1;

# ABSTRACT: A type to check for a valid IP address, version 4 or 6

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::MinFraud::Data::Rx::Type::IPAddress - A type to check for a valid IP address, version 4 or 6

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
