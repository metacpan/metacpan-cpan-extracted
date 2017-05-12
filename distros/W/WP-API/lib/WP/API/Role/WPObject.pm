package WP::API::Role::WPObject;
{
  $WP::API::Role::WPObject::VERSION = '0.01';
}
BEGIN {
  $WP::API::Role::WPObject::AUTHORITY = 'cpan:DROLSKY';
}

use strict;
use warnings;
use namespace::autoclean;

use DateTime;
use MooseX::Params::Validate qw( validated_hash );
use Scalar::Util qw( blessed );
use WP::API::Types qw( ArrayRef HashRef Maybe NonEmptyStr PositiveInt );

use MooseX::Role::Parameterized;

requires '_create_result_as_params';

parameter id_method => (
    isa      => NonEmptyStr,
    required => 1,
);

parameter xmlrpc_get_method => (
    isa      => NonEmptyStr,
    required => 1,
);

parameter xmlrpc_create_method => (
    isa      => NonEmptyStr,
    required => 1,
);

parameter fields => (
    isa      => HashRef,
    required => 1,
);

has api => (
    is       => 'ro',
    isa      => 'WP::API',
    required => 1,
);

has _raw_data => (
    is       => 'ro',
    isa      => HashRef,
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_raw_data',
);

my $_make_field_attrs = sub {
    my $fields = shift;

    my @optional;
    for my $field ( keys %{$fields} ) {
        my $spec = $fields->{$field};

        my %attr_p = (
            is       => 'ro',
            isa      => $spec,
            init_arg => undef,
            lazy     => 1,
        );

        if ( $spec eq 'DateTime' ) {
            my $datetime_method
                = $field =~ /_gmt$/ ? '_gmt_datetime' : '_floating_datetime';
            $attr_p{default} = sub {
                $_[0]->$datetime_method( $_[0]->_raw_data()->{$field} );
            };
        }
        else {
            my $default_if_missing
                = $spec->is_a_type_of(ArrayRef) ? []
                : $spec->is_a_type_of(HashRef)  ? {}
                :                                 undef;

            $attr_p{default} = sub {
                my $raw = $_[0]->_raw_data();
                defined $raw->{$field} ? $raw->{$field} : $default_if_missing;
            };

            if ( $spec->is_a_type_of(Maybe) ) {
                $attr_p{predicate} = 'has_' . $field;
                push @optional, $field;
            }

            if ( $spec->has_coercion() ) {
                $attr_p{coerce} = 1;
            }
        }

        has $field => %attr_p;
    }

    method _optional_fields => sub { @optional };
};

sub _gmt_datetime {
    my $self  = shift;
    my $value = shift;

    return $self->_parse_datetime($value)->set_time_zone('UTC');
}

sub _floating_datetime {
    my $self  = shift;
    my $value = shift;

    return $self->_parse_datetime($value)
        ->set_time_zone( $self->api()->server_time_zone() );
}

sub _parse_datetime {
    my $self  = shift;
    my $value = shift;

    my %parsed;
    @parsed{qw(year month day hour minute second)}
        = $value =~ /^(\d{4})(\d\d)(\d\d)T(\d\d):(\d\d):(\d\d)Z?/;

    return DateTime->new( %parsed, time_zone => 'floating' );
}

role {
    my $p = shift;

    $_make_field_attrs->( $p->{fields} );

    my $id_method = $p->id_method();

    has $id_method => ( is => 'ro', isa => PositiveInt, required => 1, );

    my $xmlrpc_get_method = $p->xmlrpc_get_method();

    method _build_raw_data => sub {
        my $self = shift;

        my $raw
            = $self->api()->call( $xmlrpc_get_method, $self->$id_method() );
        for my $field ( $self->_optional_fields() ) {
            delete $raw->{$field}
                unless defined $raw->{$field} && length $raw->{$field};
        }

        $self->_munge_raw_data($raw);

        return $raw;
    };

    my $xmlrpc_create_method = $p->xmlrpc_create_method();

    method create => sub {
        my $class = shift;
        my %p     = validated_hash(
            \@_,
            api                            => { isa => 'WP::API' },
            MX_PARAMS_VALIDATE_ALLOW_EXTRA => 1,
        );

        my $api = delete $p{api};

        $class->_munge_create_parameters( \%p );

        my $result = $api->call(
            $xmlrpc_create_method,
            \%p,
        );

        return $class->new(
            $class->_create_result_as_params($result),
            api => $api
        );
    };
};

sub _munge_create_parameters {
    return;
}

sub _munge_raw_data {
    return;
}

{
    my $format = q{YYYMMdd'T'HH:mm:ss};

    sub _deflate_datetimes {
        my $class  = shift;
        my $p      = shift;
        my @fields = @_;

        for my $field (@fields) {
            next unless $p->{$field} && blessed $p->{$field};

            if ( $field =~ /_gmt$/ ) {
                $p->{$field}
                    = $p->{$field}->clone()->set_time_zone('UTC')
                    ->format_cldr( $format );
            }
            else {
                $p->{$field}
                    = $p->{$field}->clone()
                    ->set_time_zone( $p->{api}->server_time_zone() )
                    ->format_cldr($format);
            }
        }

        return;
    }
}

1;

# ABSTRACT: A shared role for all WP::API::* objects

__END__

=pod

=head1 NAME

WP::API::Role::WPObject - A shared role for all WP::API::* objects

=head1 VERSION

version 0.01

=head1 DESCRIPTION

There are no user serviceable parts in here.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
