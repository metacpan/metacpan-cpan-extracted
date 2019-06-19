package WebService::MinFraud::Validator;

use Moo;
use namespace::autoclean;

our $VERSION = '1.009001';

use Data::Delete 0.05;
use Try::Tiny;
use Types::Standard qw( InstanceOf Object HashRef );

use WebService::MinFraud::Validator::Chargeback;
use WebService::MinFraud::Validator::Score;
use WebService::MinFraud::Validator::Insights;
use WebService::MinFraud::Validator::Factors;
use WebService::MinFraud::Validator::FraudService;

has _deleter => (
    is      => 'lazy',
    isa     => InstanceOf ['Data::Delete'],
    builder => sub { Data::Delete->new },
    handles => { _delete => 'delete' },
);

has _validator_chargeback => (
    is      => 'lazy',
    isa     => InstanceOf ['WebService::MinFraud::Validator::Chargeback'],
    builder => sub { WebService::MinFraud::Validator::Chargeback->new },
);

has _validator_score => (
    is      => 'lazy',
    isa     => InstanceOf ['WebService::MinFraud::Validator::Score'],
    builder => sub { WebService::MinFraud::Validator::Score->new },
);

has _validator_insights => (
    is      => 'lazy',
    isa     => InstanceOf ['WebService::MinFraud::Validator::Insights'],
    builder => sub { WebService::MinFraud::Validator::Insights->new },
);

has _validator_factors => (
    is      => 'lazy',
    isa     => InstanceOf ['WebService::MinFraud::Validator::Factors'],
    builder => sub { WebService::MinFraud::Validator::Factors->new },
);

has _validator_fraud_service => (
    is      => 'lazy',
    isa     => InstanceOf ['WebService::MinFraud::Validator::FraudService'],
    builder => sub { WebService::MinFraud::Validator::FraudService->new },
);

has _dispatch_validator => (
    is      => 'lazy',
    isa     => HashRef,
    builder => sub {
        my $self = shift;
        return {
            fraud_service => sub { $self->_validator_fraud_service },
            score         => sub { $self->_validator_score },
            chargeback    => sub { $self->_validator_chargeback },
            factors       => sub { $self->_validator_factors },
            insights      => sub { $self->_validator_insights },
        };
    },
);

sub validate_request {
    my ( $self, $request, $path ) = @_;

    if ( !defined $path ) {
        $path = 'fraud_service';
    }

    try {
        $self->_dispatch_validator->{$path}()->assert_valid($request);
    }
    catch {
        my @error_strings = map {
                  'VALUE: '
                . ( defined $_->value ? $_->value : 'undef' )
                . ' caused ERROR: '
                . $_->stringify
        } @{ $_->failures };
        my $all_error_strings = join "\n", @error_strings;
        die $all_error_strings;
    };
}

1;

# ABSTRACT: Validation for the minFraud requests

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::MinFraud::Validator - Validation for the minFraud requests

=head1 VERSION

version 1.009001

=head1 SYNOPSIS

    use 5.010;

    use WebService::MinFraud::Validator;

    my $validator = WebService::MinFraud::Validator->new;
    my $request = { device => { ip_address => '24.24.24.24' } };
    $validator->validate_request($request, 'score'); # takes an optional 'path'

=head1 DESCRIPTION

This module defines the request schema for the minFraud API. In addition, it
provides a C<validate_request> method that is used to validate any request
passed to the C<score>, C<insights>, C<factors>, or C<chargeback> methods.

=head1 METHODS

=head2 validate_request

    my $validator = WebService::MinFraud::Validator->new;
    my $request = { ip => '24.24.24.24' };
    $validator->validate_request($request, 'chargeback');

    $request = { device => { ip_address => '24.24.24.24'  } };
    $validator->validate_request($request); # by default will use WebService::MinFraud::Validator::FraudService

This method takes a minFraud request as a HashRef and validates it against the
minFraud request schema for the specified API endpoint. A second optional argument can be used
to specify the schema to use, C<socre>, C<insights>, C<factors>, C<chargeback>,
or C<fraud_service>. If the request HashRef fails validation, an exception
is thrown, which is a string containing all of the validation errors.

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/minfraud-api-perl/issues>.

=head1 AUTHOR

Mateu Hunter <mhunter@maxmind.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 - 2019 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
