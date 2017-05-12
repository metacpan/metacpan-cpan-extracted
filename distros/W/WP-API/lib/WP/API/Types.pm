package WP::API::Types;
{
  $WP::API::Types::VERSION = '0.01';
}
BEGIN {
  $WP::API::Types::AUTHORITY = 'cpan:DROLSKY';
}

use strict;
use warnings;
use namespace::autoclean;

use MooseX::Types::Common::String;
use MooseX::Types::Moose;
use MooseX::Types::Path::Class;
use MooseX::Types::URI;

use parent 'MooseX::Types::Combine';

__PACKAGE__->provide_types_from(
    qw(
        MooseX::Types::Common::Numeric
        MooseX::Types::Common::String
        MooseX::Types::Moose
        MooseX::Types::Path::Class
        MooseX::Types::URI
        )
);

1;

# ABSTRACT: Type library for the WP-API distro

__END__

=pod

=head1 NAME

WP::API::Types - Type library for the WP-API distro

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
