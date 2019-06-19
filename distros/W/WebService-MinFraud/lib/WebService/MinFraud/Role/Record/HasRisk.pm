package WebService::MinFraud::Role::Record::HasRisk;

use Moo::Role;
use namespace::autoclean;

our $VERSION = '1.009001';

use Types::Standard qw( Num );

has risk => (
    is        => 'ro',
    isa       => Num,
    predicate => 1,
);

1;

# ABSTRACT: A role to add a risk attribute

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::MinFraud::Role::Record::HasRisk - A role to add a risk attribute

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
