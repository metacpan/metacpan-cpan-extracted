package XML::Schematron::Schema;

use Moose::Role;
use namespace::autoclean;

use MooseX::Types::Path::Class;
use XML::SAX::ParserFactory;
use XML::Schematron::SchemaReader;
use XML::Filter::BufferText;

requires qw( tests );

has sax_filter => (
    is          =>  'ro',
    isa         =>  'XML::Filter::BufferText',
    lazy_build  => 1,
);

sub _build_sax_filter {
    my $self = shift;
    return XML::Filter::BufferText->new( Handler => $self->sax_handler );
}

has sax_handler => (
    is          =>  'ro',
    isa         =>  'XML::Schematron::SchemaReader',
    default     => sub { return XML::Schematron::SchemaReader->new(); },
);

has sax_parser => (
    is          =>  'ro',
    isa         =>  'Object',
    lazy_build  =>  1,
);

sub _build_sax_parser {
    my $self = shift;
    return XML::SAX::ParserFactory->parser(Handler => $self->sax_filter);
}

sub parse_schema {
    my $self = shift;
    my $parser = $self->sax_parser;
    $parser->parse_file( $self->schema->stringify );
    
    my $tests = $self->sax_handler->test_stack || [];    
    $self->tests( $tests );
    
    return 1;
}

has schema => (
    is          =>  'rw',
    isa         => 'Path::Class::File',
    coerce      => 1,
    predicate   => 'has_schema',
);


1;