package Zuzu::Value::Boolean;

use utf8;

our $VERSION = '0.001002';

use Moo;

use overload
	'0+' => sub { $_[0]->value ? 1 : 0 },
	'""' => sub { $_[0]->value ? '1' : '0' },
	'bool' => sub { $_[0]->value ? 1 : 0 },
	fallback => 1;

has 'value' => ( is => 'rw', default => sub { 0 } );

sub is_truthy {
	my ( $self ) = @_;

	return $self->value ? 1 : 0;
}

1;

=pod

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Value::Boolean >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut
