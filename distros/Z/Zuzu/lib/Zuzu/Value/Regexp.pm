package Zuzu::Value::Regexp;

use utf8;

our $VERSION = '0.007000';

use Moo;

has 'pattern' => ( is => 'rw', default => sub { '' } );
has 'flags' => ( is => 'rw', default => sub { '' } );

sub is_truthy { 1 }

sub to_String {
	my ( $self ) = @_;

	return $self->pattern // '';
}

1;

=pod

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Value::Regexp >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut
