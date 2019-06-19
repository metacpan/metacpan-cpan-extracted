package WebService::MinFraud::Validator::Base;

use Moo;
use namespace::autoclean;

our $VERSION = '1.009001';

use Carp;
use Data::Rx;
use Types::Standard qw( HashRef InstanceOf Object );

has _request_schema_definition => (
    is      => 'lazy',
    isa     => HashRef,
    builder => '_build_request_schema_definition',
);

has _rx => (
    is      => 'lazy',
    isa     => InstanceOf ['Data::Rx'],
    builder => '_build_rx_plugins',
);

has _schema => (
    is      => 'lazy',
    isa     => Object,
    builder => sub {
        my $self = shift;
        $self->_rx->make_schema( $self->_request_schema_definition );
    },
    handles => {
        assert_valid => 'assert_valid',
    },
);

sub _build_request_schema_definition {
    croak 'Abstract Base Class. This method is implemented in subclasses';
}

sub _build_rx_plugins {
    croak 'Abstract Base Class. This method is implemented in subclasses';

}

1;

# ABSTRACT: Abstract Base Validation for the minFraud requests

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::MinFraud::Validator::Base - Abstract Base Validation for the minFraud requests

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
