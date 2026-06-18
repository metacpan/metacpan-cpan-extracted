package Zuzu::Parser;

use utf8;

our $VERSION = '0.005000';

use Zuzu::Error;
use Zuzu::Lexer;
use Zuzu::Parser::_Impl;
use Zuzu::AST::Visitor::TypeCheckHints;
use Zuzu::AST::Visitor::SuperHints;
use Zuzu::AST::Visitor::LexicalEnvHints;
use Zuzu::Util ();

use Moo;

has 'disabled_visitors' => ( is => 'rw', default => sub { [] } );

my @VISITOR_CLASSES = (
	TypeCheckHints => 'Zuzu::AST::Visitor::TypeCheckHints',
	SuperHints => 'Zuzu::AST::Visitor::SuperHints',
	LexicalEnvHints => 'Zuzu::AST::Visitor::LexicalEnvHints',
);
my %VISITOR_CLASS_FOR = @VISITOR_CLASSES;

sub available_visitors {
	return map { $VISITOR_CLASSES[ $_ * 2 ] } 0 .. ( @VISITOR_CLASSES / 2 ) - 1;
}

sub normalize_disabled_visitors {
	my ( $class, @names ) = @_;

	my @out;
	my %seen;
	for my $name ( @names ) {
		next if !defined $name or $name eq '';
		if ( !exists $VISITOR_CLASS_FOR{$name} ) {
			my $expected = join ', ', $class->available_visitors;
			die "Unknown visitor '$name' (expected one of: $expected)";
		}
		push @out, $name if !$seen{$name}++;
	}

	return @out;
}

sub _disabled_visitor_set {
	my ( $self ) = @_;

	return {
		map { $_ => 1 }
		Zuzu::Parser->normalize_disabled_visitors(
			@{ $self->disabled_visitors // [] },
		)
	};
}

sub visitor_cache_key {
	my ( $self ) = @_;

	return join ',',
		Zuzu::Parser->normalize_disabled_visitors(
			@{ $self->disabled_visitors // [] },
		);
}

sub apply_visitors {
	my ( $self, $ast ) = @_;

	my $disabled = $self->_disabled_visitor_set;
	for ( my $i = 0; $i < @VISITOR_CLASSES; $i += 2 ) {
		my ( $name, $class ) = @VISITOR_CLASSES[ $i, $i + 1 ];
		next if $disabled->{$name};
		$class->new->apply($ast);
	}

	return $ast;
}

sub BUILD {
	my ( $self ) = @_;

	$self->disabled_visitors([
		Zuzu::Parser->normalize_disabled_visitors(
			@{ $self->disabled_visitors // [] },
		),
	]);

	return;
}

sub parse {
	my ($self, $src, $filename) = @_;

	my $ast;
	eval {
		my $lx = Zuzu::Lexer->new(src => $src, filename => $filename);
		my $p = Zuzu::Parser::_Impl->new(lexer => $lx, filename => $filename);
		$ast = $p->parse_program;
		$self->apply_visitors($ast);
		1;
	} or do {
		my $err = $@;
		die $err if ref($err) and eval { $err->isa('Zuzu::Error') };
		die $self->_compile_error_from_parse_exception( $err, $filename );
	};

	return $ast;
}

sub _compile_error_from_parse_exception {
	my ( $self, $err, $filename ) = @_;

	my $message = "$err";
	chomp $message;
	$message =~ s/\s+at \S+ line \d+\.?\z//;

	my $code = $message =~ /\A(?:Unterminated|Invalid)\b/
		? 'E_COMPILE_SYNTAX'
		: 'E_COMPILE_INTERNAL';
	$message = "Internal parser failure: $message"
		if $code eq 'E_COMPILE_INTERNAL';

	return Zuzu::Error->new_compile(
		code => $code,
		message => $message,
		file => ( defined $filename ? $filename : '<input>' ),
		line => 1,
	);
}

=pod

=head1 NAME

Zuzu::Parser - entry point for parsing source text into an AST

=head1 DESCRIPTION

Converts source text into a C<Zuzu::AST::Program> by lexing and delegating to C<Zuzu::Parser::_Impl>.

=head1 INHERITANCE

Inherits from C<Moo::Object>.

=head1 ROLES

None.

=head1 METHODS

=head2 parse

Parses source text and returns a C<Zuzu::AST::Program>.

=head1 SEE ALSO

Subclasses: none in this distribution.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Parser >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
