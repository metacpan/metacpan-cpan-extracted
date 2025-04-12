package Text::MustacheTemplate::Evaluator;
use 5.022000;
use strict;
use warnings;

use Exporter 5.57 'import';

our @EXPORT_OK = qw/retrieve_variable evaluate_section_variable evaluate_section/;

use Scalar::Util qw/looks_like_number/;

use Text::MustacheTemplate::Lexer ();

our $LAMBDA_RENDERER;

sub retrieve_variable {
    my ($ctx, @keys) = @_;

CTX_LOOP:
    for my $root (map $ctx->[$_], reverse 0..$#{$ctx}) {
        my $value = $root;
        for my $i (keys @keys) {
            my $key = $keys[$i];
            next CTX_LOOP if ref $value ne 'HASH';
            next CTX_LOOP if $i == 0 && !exists $value->{$key};

            my $is_last = $i == $#keys;
            $value = $value->{$key};
            $value = $value->() if !$is_last && ref $value eq 'CODE';
        }
        next if ref $value eq 'HASH';

        if (ref $value eq 'CODE') {
            $value = $value->();
            if (do { no warnings qw/once/; $Text::MustacheTemplate::LAMBDA_TEMPLATE_RENDERING }) {
                return $LAMBDA_RENDERER->($value);
            }
        }
        return $value;
    }
    return '';
}

sub evaluate_section_variable {
    my ($ctx, @keys) = @_;

CTX_LOOP:
    for my $root (map $ctx->[$_], reverse 0..$#{$ctx}) {
        my $value = $root;
        for my $i (keys @keys) {
            my $key = $keys[$i];
            next CTX_LOOP if ref $value ne 'HASH';
            next CTX_LOOP if $i == 0 && !exists $value->{$key};

            my $is_last = $i == $#keys;
            $value = $value->{$key};
            $value = $value->() if !$is_last && ref $value eq 'CODE';
        }

        return evaluate_section($value);
    }
    return;
}

sub evaluate_section {
    my $value = shift;
    return @$value if ref $value eq 'ARRAY';
    return $value ? $value : ();
}

1;

=head1 NAME

Text::MustacheTemplate::Evaluator - [INTERNAL] Context evaluation for Mustache templates

=head1 SYNOPSIS

    use Text::MustacheTemplate::Evaluator qw/
        retrieve_variable
        evaluate_section
        evaluate_section_variable
    /;
    
    my @context = ({ name => 'World', items => [1, 2, 3] });
    
    # Get a variable value
    my $value = retrieve_variable(\@context, 'name');
    
    # Evaluate if a section should be rendered
    my @section_ctx = evaluate_section_variable(\@context, 'items');
    
    # Evaluate a direct value
    my @items_ctx = evaluate_section($context[-1]->{items});

=head1 DESCRIPTION

Text::MustacheTemplate::Evaluator provides functions for evaluating Mustache template contexts
and retrieving values from nested context structures according to the Mustache specification.

This is internal interface for Text::MustacheTemplate.
The APIs may change without notice.

=head1 FUNCTIONS

=over 4

=item retrieve_variable(\@context, @path)

Retrieves a value from the context stack by following the given path.
Returns the value if found, otherwise undef.

Parameters:

=over 8

=item \@context - An array reference to the context stack

=item @path - The dot-separated path components to the variable

=back

=item evaluate_section($value)

Evaluates whether a section should be rendered and how it should be processed.
Returns an array of context objects for iteration.

Parameters:

=over 8

=item $value - The value to evaluate

=back

For different value types:

=over 8

=item * Undefined or falsy values: Returns an empty array (section not rendered)

=item * Array references: Returns the array elements for iteration

=item * Hash references: Returns the hash reference itself for context

=item * Code references: Returns the code reference for lambda processing

=item * True scalar values: Returns the value as a single-element array

=back

=item evaluate_section_variable(\@context, @path)

Retrieves a variable by path and evaluates it as a section.
Combines retrieve_variable and evaluate_section.

Parameters:

=over 8

=item \@context - An array reference to the context stack

=item @path - The dot-separated path components to the variable

=back

=back

=head1 LAMBDA SUPPORT

When a section value is a code reference (lambda), the Evaluator provides special handling:

=over 4

=item * The lambda receives the raw section content as its first argument

=item * If $LAMBDA_RENDERER is defined, the lambda's result will be processed by this renderer

=item * This enables dynamic template generation within templates

=back

=head1 LICENSE

=cut