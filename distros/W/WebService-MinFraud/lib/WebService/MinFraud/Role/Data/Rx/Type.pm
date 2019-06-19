package WebService::MinFraud::Role::Data::Rx::Type;

use strict;
use warnings;
use Role::Tiny;
use namespace::autoclean;

our $VERSION = '1.009001';

use Carp ();

requires 'type_uri';

sub guts_from_arg {
    my ( $class, $arg ) = @_;
    $arg ||= {};

    if ( my @unexpected = keys %$arg ) {
        Carp::croak sprintf 'Unknown arguments %s in constructing %s',
            ( join ',' => @unexpected ), $class->type_uri;
    }

    return {};
}

1;

# ABSTRACT: A role that helps build Data::Rx Types

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::MinFraud::Role::Data::Rx::Type - A role that helps build Data::Rx Types

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
