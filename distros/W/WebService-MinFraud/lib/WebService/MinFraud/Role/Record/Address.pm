package WebService::MinFraud::Role::Record::Address;

use Moo::Role;
use namespace::autoclean;

our $VERSION = '1.009001';

use WebService::MinFraud::Types qw( Bool BoolCoercion Num);

has distance_to_ip_location => (
    is        => 'ro',
    isa       => Num,
    predicate => 1,
);

has is_in_ip_country => (
    is        => 'ro',
    isa       => Bool,
    coerce    => BoolCoercion,
    predicate => 1,
);

has is_postal_in_city => (
    is        => 'ro',
    isa       => Bool,
    coerce    => BoolCoercion,
    predicate => 1,
);

has latitude => (
    is        => 'ro',
    isa       => Num,
    predicate => 1,
);

has longitude => (
    is        => 'ro',
    isa       => Num,
    predicate => 1,
);

1;

# ABSTRACT: This is an address role that shipping and billing will consume

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::MinFraud::Role::Record::Address - This is an address role that shipping and billing will consume

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
