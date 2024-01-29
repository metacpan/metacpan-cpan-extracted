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