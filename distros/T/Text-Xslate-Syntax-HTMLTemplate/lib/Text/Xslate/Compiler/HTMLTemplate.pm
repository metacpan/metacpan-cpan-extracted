package Text::Xslate::Compiler::HTMLTemplate;

use 5.008_001;

use strict;
use warnings FATAL => 'recursion';

use Any::Moose;

extends qw(Text::Xslate::Compiler);

sub _generate_call {
    my($self, $node) = @_;
    my $callable = $node->first; # function or macro
    my $args     = $node->second;

    my @code = $self->SUPER::_generate_call($node);

    if($callable->arity eq 'name'){
        my @code_fetch_symbol = $self->compile_ast($callable);
        @code = (
            $self->opcode( pushmark => undef, comment => $callable->id ),
            (map { $self->push_expr($_) } @{$args}),

            $self->opcode( fetch_s => $callable->value, line => $callable->line ),
            $self->opcode( 'dor' => scalar(@code_fetch_symbol) + 1),

            @code_fetch_symbol,
            $self->opcode( 'funcall' )
        );
    };
    @code;
}

no Any::Moose;
__PACKAGE__->meta->make_immutable();

=head1 NAME

Text::Xslate::Compiler::HTMLTemplate - An Xslate compiler to generate HTML::Template compatible intermediate code.

=head1 AUTHOR

Shigeki Morimoto E<lt>Shigeki(at)Morimo.toE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011, Shigeki, Morimoto. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
