package Text::MediawikiFormat::Blocks;

use strict;
use warnings::register;

use Text::MediawikiFormat::Block;

our $VERSION = '1.04';

sub import {
	my $caller = caller();
	no strict 'refs';
	*{ $caller . '::new_block' } = sub {
		my $type  = shift;
		my $class = "Text::MediawikiFormat::Block::$type";

		*{ $class . '::ISA' } = ['Text::MediawikiFormat::Block']
			unless $class->can('new');

		return $class->new( type => $type, @_ );
	};
}

1;
__END__
=head1 NAME

Text::MediawikiFormat::Blocks - blocktypes for Text::MediawikiFormat

=head1 SYNOPSIS

None.  Use L<Text::MediawikiFormat> as the public interface, unless you want to
create your own block type.

=head1 DESCRIPTION

This module merely creates subclasses of Text::MediawikiFormat::Block, which is
the interesting code.  A block is a collection of related lines, such as a code
block (text to display verbatim in a monospaced font), a header, an unordered
list, an ordered list, and a paragraph (text to display in a proportional
font).

Every block extends C<Text::MediawikiFormat::Block>.

=head1 METHODS

The following methods exist:

=over 4

=item * C<new( %args )>

Creates and returns a new block.  The valid arguments are:

=over 4

=item * C<text>

The text of the line found in the block.

=item * C<args>

The arguments captured by the block-identifying regular expression.

=item * C<level>

The level of indentation for the block (usually only useful for list blocks).

=item * C<tags>

The tags in effect for the current type of wiki formatting.

=item * C<opts>

The options in effect for the current type of wiki formatting.

=back

Use the accessors of the same names to retrieve the values of the attributes.

=item * C<add_text( @lines_of_text )>

Adds a list of lines of text to the current text for the block.  This is very
useful when you encounter a block and want to merge it with the previous block
of the same type

=item * C<add_args( @arguments )>

Adds further arguments to the block; useful when merging blocks.

=item * C<formatted_text()>

Returns text formatted appropriately for this block.  Blocks don't have to have
formatters, but they may.

=item * C<formatter( $line_of_text )>

Formats the C<$line> using C<Text::MediawikiFormat::format_line()>.  You can add
your own formatter here; this is worth overriding.

=item * C<merge( $next_block )>

Merges the current block with C<$next_block> (the next block encountered) if
they're of the same type and are at the same level.  This adds the text and
args of C<$next_block> to the current block.  It's your responsibility to
remove C<$next_block> from whatever your code iterates over.

=item * C<nests()>

Returns true if this block should nest (as in lists and unordered lists) for
the active wiki formatting.

=item * C<nest( $next_block )>

Nests C<$next_block> under this block if the both nest and if C<$next_block>
has a level greater than the current block.  This actually adds C<$next_block>
as a text item within the current block.  Beware.

=back

=head1 AUTHOR

chromatic, C<< chromatic at wgz dot org >>

=head1 BUGS

No known bugs.

=head1 COPYRIGHT

Copyright (c) 2006, chromatic.  Some rights reserved.

This module is free software; you can use, redistribute, and modify it under
the same terms as Perl 5.8.x.
