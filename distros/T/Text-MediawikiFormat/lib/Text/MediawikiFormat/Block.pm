package Text::MediawikiFormat::Block;

use strict;
use warnings::register;

use Scalar::Util qw( blessed reftype );

our $VERSION = '1.04';

sub new {
	my ( $class, %args ) = @_;

	$args{text} = $class->arg_to_ref( delete $args{text} || '' );
	$args{args} = [ $class->arg_to_ref( delete $args{args} || [] ) ];

	bless \%args, $class;
}

sub arg_to_ref {
	my ( $class, $value ) = @_;
	return $value if ( reftype($value) || '' ) eq 'ARRAY';
	return [$value];
}

sub shift_args {
	my $self = shift;
	my $args = shift @{ $self->{args} };
	return wantarray ? @$args : $args;
}

sub all_args {
	my $args = $_[0]{args};
	return wantarray ? @$args : $args;
}

sub text {
	my $text = $_[0]{text};
	return wantarray ? @$text : $text;
}

sub add_text {
	my $self = shift;
	push @{ $self->{text} }, @_;
}

sub formatted_text {
	my $self = shift;
	return map { blessed($_) ? $_ : $self->formatter($_) } $self->text();
}

sub formatter {
	my ( $self, $line ) = @_;
	Text::MediawikiFormat::format_line( $line, $self->tags(), $self->opts() );
}

sub add_args {
	my $self = shift;
	push @{ $self->{args} }, @_;
}

{
	no strict 'refs';
	for my $attribute (qw( level opts tags type )) {
		*{$attribute} = sub { $_[0]{$attribute} };
	}
}

sub merge {
	my ( $self, $next_block ) = @_;

	return $next_block unless $self->type() eq $next_block->type();
	return $next_block unless $self->level() == $next_block->level();

	$self->add_text( $next_block->text() );
	$self->add_args( $next_block->all_args() );
	return;
}

sub nests {
	my ( $self, $maynest ) = @_;
	my $tags = $self->{tags};

	return
		   exists $tags->{nests}{ $self->type() }
		&& exists $tags->{nests}{ $maynest->type() }
		&& $self->level()
		< $maynest->level()

		# <nowiki> tags nest anywhere, regardless of level and parent
		|| exists $tags->{nests_anywhere}{ $maynest->type() };
}

sub nest {
	my ( $self, $next_block ) = @_;

	return unless $next_block = $self->merge($next_block);
	return $next_block unless $self->nests($next_block);

	# if there's a nested block at the end, maybe it can nest too
	my $last_item = ( $self->text() )[-1];
	return $last_item->nest($next_block) if blessed($last_item);

	$self->add_text($next_block);
	return;
}

1;

__END__

=head1 NAME

Text::MediawikiFormat::Block - blocktype for Text::MediawikiFormat

=head1 SYNOPSIS

None.  Use L<Text::MediawikiFormat> as the public interface, unless you want to
create your own block type. See also L<Text::MediawikiFormat::Blocks>.

=head1 AUTHOR

chromatic, C<< chromatic at wgz dot org >>

=head1 BUGS

No known bugs.

=head1 COPYRIGHT

Copyright (c) 2006, chromatic.  Some rights reserved.

This module is free software; you can use, redistribute, and modify it under
the same terms as Perl 5.8.x.
