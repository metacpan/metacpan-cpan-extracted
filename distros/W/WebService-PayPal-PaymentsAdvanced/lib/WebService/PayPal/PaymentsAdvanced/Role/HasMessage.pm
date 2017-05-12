package WebService::PayPal::PaymentsAdvanced::Role::HasMessage;

use Moo::Role;

our $VERSION = '0.000021';

use Types::Common::String qw( NonEmptyStr );

has message => (
    is       => 'lazy',
    isa      => NonEmptyStr,
    init_arg => undef,
);

sub _build_message {
    my $self = shift;
    return $self->params->{RESPMSG};
}

1;

=pod

=head1 NAME

WebService::PayPal::PaymentsAdvanced::Role::HasMessage - Role which provides message attribute to exception and response classes.

=head1 VERSION

version 0.000021

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
#ABSTRACT: Role which provides message attribute to exception and response classes.
