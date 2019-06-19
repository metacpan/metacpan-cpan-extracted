package WebService::MinFraud::Data::Rx::Type::Hex32;

use 5.010;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '1.009001';

use parent 'Data::Rx::CommonType::EasyNew';

use Role::Tiny::With;

with 'WebService::MinFraud::Role::Data::Rx::Type';

sub assert_valid {
    my ( $self, $value ) = @_;

    return 1 if $value && ( $value =~ m/^[0-9A-Fa-f]{32}$/ );

    $self->fail(
        {
            error   => [qw(type)],
            message => 'Found value is not a 32 digit hexadecimal number.',
            value   => $value,
        }
    );
}

sub type_uri {
    ## no critic(ValuesAndExpressions::ProhibitCommaSeparatedStatements)
    'tag:maxmind.com,MAXMIND:rx/hex32';
}

1;

# ABSTRACT: A type to check for a 32 digit hexadecimal

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::MinFraud::Data::Rx::Type::Hex32 - A type to check for a 32 digit hexadecimal

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
