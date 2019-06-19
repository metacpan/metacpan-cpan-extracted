package WebService::MinFraud::Role::HasCommonAttributes;

use Moo::Role;
use namespace::autoclean;

our $VERSION = '1.009001';

use Types::Standard qw( ArrayRef InstanceOf Num Str );
use Types::UUID;
use WebService::MinFraud::Record::Warning;
use WebService::MinFraud::Types qw( NonNegativeInt NonNegativeNum );

requires 'raw';

has funds_remaining => (
    is        => 'lazy',
    isa       => NonNegativeNum,
    init_arg  => undef,
    builder   => sub { $_[0]->raw->{funds_remaining} },
    predicate => 1,
);

has id => (
    is        => 'lazy',
    isa       => Uuid,
    init_arg  => undef,
    builder   => sub { $_[0]->raw->{id} },
    predicate => 1,
);

has queries_remaining => (
    is        => 'lazy',
    isa       => NonNegativeInt,
    init_arg  => undef,
    builder   => sub { $_[0]->raw->{queries_remaining} },
    predicate => 1,
);

has risk_score => (
    is        => 'lazy',
    isa       => Num,
    init_arg  => undef,
    builder   => sub { $_[0]->raw->{risk_score} },
    predicate => 1,
);

has warnings => (
    is  => 'lazy',
    isa => ArrayRef [ InstanceOf ['WebService::MinFraud::Record::Warning'] ],
    init_arg => undef,
    builder  => sub {
        [ map { WebService::MinFraud::Record::Warning->new($_) }
                @{ $_[0]->raw->{warnings} } ];
    },
    predicate => 1,
);

1;

# ABSTRACT: A role for attributes common to both the Insights and Score models

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::MinFraud::Role::HasCommonAttributes - A role for attributes common to both the Insights and Score models

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
