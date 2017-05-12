package Tree::Persist::File::XMLWithSingleQuotes;

use strict;
use warnings;

use base qw( Tree::Persist::File );

use Module::Runtime;

use Scalar::Util qw( blessed refaddr );

use XML::Parser;

our $VERSION = '1.13';

# ----------------------------------------------

sub _reload
{
	my($self)    = shift;
	my($linenum) = 0;

	my @stack;
	my $tree;

	my $parser = XML::Parser -> new
	(
		Handlers =>
		{
			Start => sub
			{
				my($dummy, $name, %args) = @_;
				my($class)               = $args{class} ? $args{class} : $self->{_class};
				my($node)                = Module::Runtime::use_module($class)->new( $args{value} );

				if ( @stack )
				{
					$stack[-1] -> add_child( $node );
				}
				else
				{
					$tree = $node;
				}

				push @stack, $node;
			},
			End => sub
			{
				$linenum++;

				pop @stack;
			},
		},
	);

	$parser -> parsefile( $self->{_filename} );

	$self -> _set_tree( $tree );

	return $self;

} # End of _reload.

# ----------------------------------------------

my $pad = ' ' x 4;

# ----------------------------------------------

sub _build_string
{
	my($self)       = shift;
	my($tree)       = @_;
	my(%encode)     = ('<' => '&lt;', '>' => '&gt;', '&' => '&amp;', "'" => '&apos;', '"' => '&quot;');
	my($str)        = '';
	my($curr_depth) = $tree->depth;

	my(@char, @closer);
	my($new_depth);

	for my $node ( $tree->traverse )
	{
		$new_depth  = $node->depth;
		$str        .= pop(@closer) while @closer && $curr_depth-- >= $new_depth;
		$curr_depth = $new_depth;
		@char       = map{$encode{$_} ? $encode{$_} : $_} split(//, $node -> value);
		$str        .= ($pad x $curr_depth)
					. "<node class='"
					. blessed($node)
					. "' value='"
					. join('', @char)
					. "'>" . $/;

		push @closer, ($pad x $curr_depth) . "</node>\n";
	}

	$str .= pop(@closer) while @closer;

	return $str;

} # End of _build_string.

# ----------------------------------------------

1;

__END__

=head1 NAME

Tree::Persist::File::XMLWithSingleQuotes - A handler for Tree persistence

=head1 SYNOPSIS

See L<Tree::Persist/SYNOPSIS> or scripts/xml.demo.pl for sample code.

=head1 DESCRIPTION

This module is a plugin for L<Tree::Persist> to store a L<Tree> to an XML
file.

This module uses single-quotes around the values of tag attributes.

=head1 PARAMETERS

Parameters are used in the call to L<Tree::Persist/connect({%opts})> or L<Tree::Persist/create_datastore({%opts})>.

In addition to any parameters required by its parent L<Tree::Persist::File>, the following
parameters are used by C<connect()> or C<create_datastore()>:

=over 4

=item * class (optional)

This is the name of the deflator/inflator class.

The C<class> parameter takes precedence over the C<type> parameter.

If C<class> is not provided, C<type> is used, and defaults to 'File'. Then C<class> is determined using:

	$class = $type eq 'File' ? 'Tree::Persist::File::XML' : 'Tree::Persist::DB::SelfReferential';

See t/save_and_load.t for sample code.

=back

=head1 METHODS

Tree::Persist::File::XMLWithSingleQuotes is a sub-class of L<Tree::Persist::File>, and inherits all its methods.

=head1 XML SPEC

The XML used is very simple. Each element is called "node". The node contains
two attributes - "class", which represents the L<Tree> class to build this
node for, and "value", which is the serialized value contained in the node (as
retrieved by the C<value()> method.) Parent-child relationships are represented
by the parent containing the child.

NOTE: This plugin will currently only handle values that are strings or have a
stringification method.

The 5 build-in XML character entities (within the I<value> of the node) are encoded using this map:

	my(%encode) = ('<' => '&lt;', '>' => '&gt;', '&' => '&amp;', "'" => '&apos;', '"' => '&quot;');

They are decoded when L<XML::Parser> reads the value back in.

See L<http://www.w3.org/standards/xml/core> for details.

See t/save_and_load.t for sample code.

=head1 CODE COVERAGE

Please see the relevant section of L<Tree::Persist>.

=head1 SUPPORT

Please see the relevant section of L<Tree::Persist>.

=head1 AUTHORS

Rob Kinyon E<lt>rob.kinyon@iinteractive.comE<gt>

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

Thanks to Infinity Interactive for generously donating our time.

Co-maintenance since V 1.01 is by Ron Savage <rsavage@cpan.org>.
Uses of 'I' in previous versions is not me, but will be hereafter.

=head1 COPYRIGHT AND LICENSE

Copyright 2004, 2005 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
