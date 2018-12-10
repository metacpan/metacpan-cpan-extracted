package Text::Trac::BlockNode;

use strict;
use warnings;

use base qw( Class::Accessor::Fast Class::Data::Inheritable );
use UNIVERSAL::require;
use Text::Trac::InlineNode;

our $VERSION = '0.24';

__PACKAGE__->mk_classdata( block_nodes => [qw( heading hr p ul ol blockquote pre table dl )] );

#__PACKAGE__->mk_classdata(
#    inline_nodes   => [ qw( bold_italic bold italic underline monospace strike sup sub br
#                            auto_link_http macro trac_links ) ]
#);
__PACKAGE__->mk_classdata( block_parsers => [] );

__PACKAGE__->mk_classdata( inline_parsers => [] );

__PACKAGE__->mk_accessors(qw( context pattern inline_parser ));

sub new {
	my ( $class, $params ) = @_;
	my $self = { %$params, };
	bless $self, $class;
	$self->init;
	$self->inline_parser( Text::Trac::InlineNode->new( $self->context ) );
	return $self;
}

sub init {
	my $self = shift;
	return $self;
}

sub parse {
	my $self = shift;
	my $c    = $self->context;

	$self->block_parsers( $self->_get_parsers('block') );

	#$self->inline_parsers( $self->_get_parsers('inline') );

	while ( defined( my $l = $c->shiftline ) ) {
		next if $l =~ /^$/;
		for my $parser ( @{ $self->_get_matched_parsers( 'block', $l ) } ) {
			$parser->parse($l);
		}
	}
}

sub escape {
	my ( $self, $l ) = @_;
	return $self->inline_parser->escape($l);
}

sub replace {
	my ( $self, $l ) = @_;
	return $self->inline_parser->parse($l);
}

sub _get_parsers {
	my ( $self, $type ) = @_;

	$type .= '_nodes';
	my @parsers;
	for ( @{ $self->$type } ) {
		my $class = 'Text::Trac::' . $self->_camelize($_);
		$class->require;
		push @parsers, $class->new( { context => $self->context } );
	}
	return \@parsers;
}

sub _get_matched_parsers {
	my ( $self, $type, $l ) = @_;
	my $c = $self->context;
	$type .= '_parsers';

	my @matched_parsers;

	for my $parser ( @{ $self->$type } ) {
		next
			if ( grep { ref($parser) eq 'Text::Trac::' . $self->_camelize($_) } @{ $c->in_block_of }
			and $type =~ /^block/ );
		my $pattern = $parser->pattern or next;

		if ( $l =~ /$pattern/ ) {
			push @matched_parsers, $parser;
		}
	}

	push @matched_parsers, Text::Trac::P->new( { context => $self->context } )
		if ( !@matched_parsers and $type =~ /^block/ );
	return \@matched_parsers;
}

sub _camelize {
	my ( $self, $word ) = @_;

	my $camelized_word;
	for ( split '_', $word ) {
		chomp($_);
		$camelized_word .= ucfirst($_);
	}

	return $camelized_word;
}

1;
