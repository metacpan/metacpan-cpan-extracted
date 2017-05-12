# NAME

Text::Xslate::AST::Walker - Filter Nodes in the AST made by Text::Xslate

# SYNOPSIS

    use Text::Xslate::Parser;
    use Text::Xslate::AST::Walker;

    my $template = EOF;
    : my $first_name = 'Hanae';
    Hello, <: $last_name :>, <: $first_name :>.
    EOF
    my $parser = Text::Xslate::Parser->new;
    my $nodes = $parser->parse($template);
    my $tw = Text::Xslate::AST::Walker->new(nodes => $nodes);
    my $undeclared_vars = $tw->search_descendants(sub {
      my ($node) = @_;
      ($node->arity eq 'variable') && !$node->is_defined && !$node->is_reserved;
    });

# DESCRIPTION

Filter nodes in the AST which made by Text::Xslate.

# LICENSE

Copyright (C) aereal.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

aereal <aereal@aereal.org>
