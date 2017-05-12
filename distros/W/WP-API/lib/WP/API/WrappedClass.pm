package WP::API::WrappedClass;
{
  $WP::API::WrappedClass::VERSION = '0.01';
}
BEGIN {
  $WP::API::WrappedClass::AUTHORITY = 'cpan:DROLSKY';
}

use strict;
use warnings;
use namespace::autoclean;

use WP::API::Types qw( ClassName );

use Moose;
use MooseX::StrictConstructor;

has api => (
    is       => 'ro',
    isa      => 'WP::API',
    required => 1,
);

has class => (
    is       => 'ro',
    isa      => ClassName,
    required => 1,
);

our $AUTOLOAD;

sub AUTOLOAD {
    my $self = shift;

    my ($method) = $AUTOLOAD =~ /::(\w+)$/;

    return $self->class()->$method( api => $self->api(), @_ );
}

__PACKAGE__->meta()->make_immutable();

# This is hack so we can make an immutablized constructor - Moose will not
# rename the constructor as part of inlining.
*wrap = \&new;

Package::Stash->new(__PACKAGE__)->remove_symbol('&new');

# Now we want ->new to call the method on the wrapped class, not on
# WrappedClass itself.
Package::Stash->new(__PACKAGE__)->add_symbol(
    '&new' => sub {
        my $self = shift;

        $self->class()->new( api => $self->api(), @_ );
    }
);

1;

# ABSTRACT: A shim to pass the WP::API object to Post/Media/etc objects

__END__

=pod

=head1 NAME

WP::API::WrappedClass - A shim to pass the WP::API object to Post/Media/etc objects

=head1 VERSION

version 0.01

=head1 DESCRIPTION

There are no user serviceable parts in here.

=for Pod::Coverage wrap

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
