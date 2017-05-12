package Text::Xslate::Syntax::Any;

our $VERSION = '1.5015';

use Any::Moose;

extends qw(Text::Xslate::Parser);

has args_of_new => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { +[] },
);

has parser_table => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { +{} },
);

no Any::Moose;

our $DETECT_SYNTAX  = generate_syntax_detecter__by_suffix({
    tx  => 'Kolon',
    mtx => 'Metakolon',
    tt  => 'TTerse',
});
our $DEFAULT_SYNTAX = 'Kolon';
our $INPUT_FILTER;

__PACKAGE__->meta->make_immutable();

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->args_of_new([ @_ ]);
    $self;
}

sub parse {
    my($self, $input, %args) = @_;

    if($INPUT_FILTER){
        $input = $INPUT_FILTER->($input);
    }
    $self->_load_parser($self->compiler->file, \$input)->parse($input, %args);
}

sub _load_parser {
    my($self, $name, $input_ref) = @_;

    my $syntax = $DETECT_SYNTAX->($name, $input_ref);

    unless($self->parser_table->{$syntax}){
        my $parser_class = Any::Moose::load_first_existing_class(
            "Text::Xslate::Syntax::" . $syntax,
            $syntax,
        );
        $self->parser_table->{$syntax} = $parser_class->new(@{ $self->args_of_new });
    }
    return $self->parser_table->{$syntax};
}

sub generate_syntax_detecter__by_suffix {
    my $suffx_map = shift;

    sub {
        my($name, undef) = @_;

        my($suffix) = ($name =~ /\.([^.]+)\z/);
        $suffx_map->{$suffix || 'default'} || $DEFAULT_SYNTAX;
    };
}

1;
__END__

=head1 NAME

Text::Xslate::Syntax::Any -

=head1 SYNOPSIS

  use Text::Xslate::Syntax::Any;

=head1 DESCRIPTION

Text::Xslate::Syntax::Any is

=head1 AUTHOR

mixi-inc E<lt>shigeki.morimoto@mixi.co.jpE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
