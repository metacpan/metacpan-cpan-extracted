package Text::GooglewikiFormat::Blocks;

use warnings;
use strict;

sub import {
	my $caller = caller();
	no strict 'refs';
	*{ $caller . '::new_block' } = sub
	{
		my $type  = shift;
		my $class = "Text::GooglewikiFormat::Block::$type";
		my $ctor;
		
		unless ($ctor = $class->can( 'new' ))
		{
			@{ $class . '::ISA' } = ( 'Text::GooglewikiFormat::Block' );
			$ctor = $class->can( 'new' );
		}

		return $class->new( type => $type, @_ );
	};
}

package Text::GooglewikiFormat::Block;

use Scalar::Util qw( blessed reftype );

sub new
{
	my ($class, %args) = @_;

	$args{text}        =   $class->arg_to_ref( delete $args{text} || '' );
	$args{args}        = [ $class->arg_to_ref( delete $args{args} || [] ) ];

	bless \%args, $class;
}

sub arg_to_ref
{
	my ($class, $value) = @_;
	return   $value if ( reftype( $value ) || '' ) eq 'ARRAY';
	return [ $value ];
}

sub shift_args
{
	my $self = shift;
	my $args = shift @{ $self->{args} };
	return wantarray ? @$args : $args;
}

sub all_args
{ 
	my $args = $_[0]{args};
	return wantarray ? @$args : $args;
}

sub text
{
	my $text = $_[0]{text};
	return wantarray ? @$text : $text;
}

sub add_text
{
	my $self = shift;
	push @{ $self->{text} }, @_;
}

sub formatted_text
{
	my $self = shift;
	return map
	{
		blessed( $_ ) ? $_ : $self->formatter( $_ )
	} $self->text();
}

sub formatter
{
	my ($self, $line) = @_;
	Text::GooglewikiFormat::format_line( $line, $self->tags(), $self->opts() );
}

sub add_args
{
	my $self = shift;
	push @{ $self->{args} }, @_;
}

{
	no strict 'refs';
	for my $attribute (qw( level opts tags type ))
	{
		*{ $attribute } = sub { $_[0]{$attribute} };
	}
}

sub merge
{
	my ($self, $next_block) = @_;

	return $next_block unless $self->type()  eq $next_block->type();
	return $next_block unless $self->level() == $next_block->level();

	$self->add_text( $next_block->text() );
	$self->add_args( $next_block->all_args() );
	return;
}

sub nests
{
	my $self = shift;
	return exists $self->{tags}{nests}{ $self->type() };
}

sub nest
{
	my ($self, $next_block) = @_;

	return unless $next_block = $self->merge( $next_block );
	return $next_block unless $self->nests() and $next_block->nests();
	return $next_block unless $self->level()  <  $next_block->level();

	# if there's a nested block at the end, maybe it can nest too
	my $last_item = ( $self->text() )[-1];
	return $last_item->nest( $next_block ) if blessed( $last_item );

	$self->add_text( $next_block );
	return;
}

package Text::GooglewikiFormat::Block::code;

use base 'Text::GooglewikiFormat::Block';

sub formatter { $_[1] }

package Text::GooglewikiFormat::Blocks;

1;
__END__

=head1 NAME

Text::GooglewikiFormat::Blocks - blocktypes for Text::GooglewikiFormat

=head1 SYNOPSIS

None.  Use L<Text::GooglewikiFormat> as the public interface, unless you want to
create your own block type.

=head1 DESCRIPTION

This module merely creates subclasses of Text::GooglewikiFormat::Block, which is the
interesting code.  A block is a collection of related lines, such as a code
block (text to display verbatim in a monospaced font), a header, an unordered
list, an ordered list, and a paragraph (text to display in a proportional
font).

Every block extends C<Text::GooglewikiFormat::Block>.

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

Formats the C<$line> using C<Text::GooglewikiFormat::format_line()>.  You can add
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

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 BUGS

L<http://code.google.com/p/fayland/issues/list>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut