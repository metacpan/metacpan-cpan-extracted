package WebService::PayPal::PaymentsAdvanced::Role::HasTokens;

use Moo::Role;

our $VERSION = '0.000021';

use Types::Common::String qw( NonEmptyStr );

has secure_token => (
    is       => 'lazy',
    isa      => NonEmptyStr,
    init_arg => undef,
);

has secure_token_id => (
    is       => 'lazy',
    isa      => NonEmptyStr,
    init_arg => undef,
);

sub _build_secure_token {
    my $self = shift;
    return $self->params->{SECURETOKEN};
}

sub _build_secure_token_id {
    my $self = shift;
    return $self->params->{SECURETOKENID};
}

1;

=pod

=head1 NAME

WebService::PayPal::PaymentsAdvanced::Role::HasTokens - Provides roles for dealing with secure tokens

=head1 VERSION

version 0.000021

=head2 secure_token

Returns C<SECURETOKEN> param

=head2 secure_token_id

Returns C<SECURETOKENID> param

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Provides roles for dealing with secure tokens

