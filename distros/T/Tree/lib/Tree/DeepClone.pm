package Tree::DeepClone;

use 5.006;

use base 'Tree';
use strict;
use warnings;

our $VERSION = '1.14';

use Scalar::Util qw(blessed);

sub _clone_self {
    my $self = shift;
	my $node = $self->SUPER::_clone_self;

	$node->meta($self->meta);

    return $node;
}

=head1 NAME

Tree::DeepClone - A subclass of Tree::Fast which does deep cloning

=head1 SYNOPSIS

	#!/usr/bin/env perl

	use 5.010;
	use strict;
	use warnings FATAL => 'all';

	use Tree::DeepClone;

	# -----------------------

	my(@alphabet) = (qw/a b c d e f g h i j k l m n o p q r s t u v w x y z/);
	my($tree)     = Tree::DeepClone -> new('root');

	$tree -> add_child({}, map {Tree::DeepClone -> new($_)} 1..3);

	my($value);

	say 'Tree:';

	for ($tree -> traverse)
	{
		$value = $_ -> value;

		$_ -> meta({$value => ($value eq 'root') ? '0' : $alphabet[$value - 1]});

		say $_ -> value, '. meta: ', ${$_ -> meta}{$value};
	}

	my($clone) = $tree -> clone;

	say 'Clone:';

	for ($clone -> traverse)
	{
		$value = $_ -> value;

		say $_ -> value, '. meta: ', ${$_ -> meta}{$value};
	}

=head1 DESCRIPTION

This module simply adds deep cloning to Tree::Fast. As per the Synopsis, you must use
Tree::DeepClone everywhere you want this feature.

=head1 METHODS

All methods in <Tree::Fast> are available in Tree::DeepClone.

=head1 SUPPORT

L<https://github.com/ronsavage/Tree>.

=head1 ACKNOWLEDGEMENTS

=over 4

=item * Stevan Little for writing L<Tree>, upon which this module is based.

=back

=head1 AUTHOR

Ron Savage <rsavage@cpan.org>.

L<https://savage.net.au/>.

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
