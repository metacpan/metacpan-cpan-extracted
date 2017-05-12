package Text::Snippet::TabStop;
BEGIN {
  $Text::Snippet::TabStop::VERSION = '0.04';
}

# ABSTRACT: Abstract class for other tab stop classes

use strict;
use warnings;
use Carp qw(croak);
use overload '""' => sub { shift->to_string };


sub parse {
	croak "must be implemented in sub class" if(shift eq __PACKAGE__);
}

sub _new {
	my $class = shift;
	croak "this is an abstract class - please instantiate a sub-class of " . __PACKAGE__ if($class eq __PACKAGE__);

	my %args = @_;
	for my $k(qw(src index)){
		croak "$k is required" unless defined $args{$k};
	}
	return bless \%args, $class;
}


use Class::XSAccessor
		getters    => { src        => 'src', index => 'index', replacement => 'replacement' },
		setters    => { replace    => 'replacement' },
		accessors  => { parent     => 'parent' },
		predicates => { has_parent => 'parent', has_replacement => 'replacement' };


sub to_string {
	my $self = shift;
	return $self->parent->to_string if($self->has_parent);
	my $replacement = $self->replacement;
	return defined($replacement) ? $replacement : '';
}

1;

__END__
=pod

=head1 NAME

Text::Snippet::TabStop - Abstract class for other tab stop classes

=head1 VERSION

version 0.04

=head1 SYNOPSIS

This module provides some basic functionality as a base class for specific
tab stop implementations.  It requires the sub-class implement a C<parse>
method.  If an object is created directly, it requires a C<src> and <index>
parameter be passed.

=head1 CLASS METHODS

=head2 parse

This is a stub method that will die if the sub-class has not provided
a full implementation.  The method should accept a single argument and
take care of instantiating the object with the correct arguments.

=head1 INSTANCE METHODS

=over 4

=item * to_string

Returns the string representation of this object.  Also available via overloaded stringification.

=item * src

Returns the original source that was parsed to create this tab stop object.

=item * index

Returns the C<index> of this tab stop as specified on object creation.

=item * replacement

Returns C<replacement> (if any) that has been supplied for this tab stop.

=item * replace

Serves as a setter for the C<replacement> attribute.

=item * parent

Returns the parent tab stop (if any) that this tab stop reflects.

=item * has_parent

A "predicate" method that returns a boolean value indicating whether
the C<parent> attribute has a defined value.

=item * has_replacement

A "predicate" method that returns a boolean value indicating whether
the C<replacement> attribute has a defined value.

=back

=head1 AUTHOR

  Brian Phillips <bphillips@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Brian Phillips.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

