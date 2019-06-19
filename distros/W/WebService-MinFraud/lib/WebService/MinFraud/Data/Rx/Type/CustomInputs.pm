package WebService::MinFraud::Data::Rx::Type::CustomInputs;

use 5.010;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '1.009001';

use JSON::MaybeXS qw( is_bool );
use Scalar::Util qw( looks_like_number );

use parent 'Data::Rx::CommonType::EasyNew';

use Role::Tiny::With;

with 'WebService::MinFraud::Role::Data::Rx::Type';

sub assert_valid {
    my $self  = shift;
    my $value = shift;

    return
           $self->_hash_is_valid($value)
        && $self->_keys_are_valid($value)
        && $self->_values_are_valid($value);
}

sub _hash_is_valid {
    my $self  = shift;
    my $value = shift;

    return 1 if ref $value eq 'HASH';

    $self->fail(
        {
            error => [qw(type)],
            message =>
                'Found invalid custom_inputs value that is not a hashref.',
            value => $value,
        }
    );

    return 0;
}

sub _keys_are_valid {
    my $self  = shift;
    my $value = shift;

    my @invalid_keys = grep { !/^[a-z0-9_]{1,25}\Z/ } keys %{$value};

    return 1 unless @invalid_keys;

    $self->fail(
        {
            error   => [qw(type)],
            message => "Found invalid custom input keys [@invalid_keys].",
            value   => $value,
        }
    );

    return 0;
}

sub _values_are_valid {
    my $self  = shift;
    my $value = shift;

    # We can't reliably tell the difference between a string, a boolean, and
    # a number in Perl. As such, we only do the string check.

    my @invalid_values
        = grep { ( ref && !is_bool($_) ) || length > 255 || /\n/ }
        values %{$value};

    return 1 unless @invalid_values;

    $self->fail(
        {
            error   => [qw(type)],
            message => "Found invalid custom input value [@invalid_values].",
            value   => $value,
        }
    );

    return 0;
}

sub type_uri {
    'tag:maxmind.com,MAXMIND:rx/custom_inputs';
}

1;

# ABSTRACT: A type to check for a valid IP address, version 4 or 6

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::MinFraud::Data::Rx::Type::CustomInputs - A type to check for a valid IP address, version 4 or 6

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
