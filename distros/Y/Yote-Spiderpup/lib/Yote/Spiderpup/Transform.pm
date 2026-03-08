package Yote::Spiderpup::Transform;

use strict;
use warnings;
use Exporter 'import';

our $VERSION = '0.06';

our @EXPORT_OK = qw(
    transform_dollar_vars
    transform_expression
    extract_arrow_params
    add_implicit_this
    parse_html
);

# Transform $var syntax to this.get_var() / this.set_var()
sub transform_dollar_vars {
    my ($expr) = @_;
    return $expr unless defined $expr;

    # Track positions to avoid transforming inside strings
    my @protected_ranges;

    # Find string literals (both single and double quoted)
    # Handle escaped quotes properly: match \\ (escaped backslash) or \' \" (escaped quote) or any non-quote char
    while ($expr =~ /("(?:[^"\\]|\\.)*")/g) {
        push @protected_ranges, [$-[0], $+[0]];
    }
    while ($expr =~ /('(?:[^'\\]|\\.)*')/g) {
        push @protected_ranges, [$-[0], $+[0]];
    }
    # Find template literals (handle escaped backticks)
    while ($expr =~ /(`(?:[^`\\]|\\.)*`)/g) {
        push @protected_ranges, [$-[0], $+[0]];
    }

    my $is_protected = sub {
        my ($pos) = @_;
        for my $range (@protected_ranges) {
            return 1 if $pos >= $range->[0] && $pos < $range->[1];
        }
        return 0;
    };

    # Process assignments: $var = value (but not == or ===)
    # Need to handle complex RHS with nested $vars
    my $result = '';
    my $pos = 0;

    while ($expr =~ /\$(\w+)\s*=(?!=)/g) {
        my $var_name = $1;
        my $match_start = $-[0];
        my $match_end = $+[0];

        if (!$is_protected->($match_start)) {
            # Find the end of the assignment (semicolon, comma, or closing paren/bracket at depth 0)
            my $rhs_start = $match_end;
            my $depth = 0;
            my $rhs_end = length($expr);
            my $in_string = '';

            for my $i ($rhs_start .. length($expr) - 1) {
                my $char = substr($expr, $i, 1);
                my $prev = $i > 0 ? substr($expr, $i - 1, 1) : '';

                # Track string state (skip if escaped)
                if (!$in_string && $prev ne '\\') {
                    if ($char eq '"' || $char eq "'" || $char eq '`') {
                        $in_string = $char;
                        next;
                    }
                } elsif ($in_string && $char eq $in_string && $prev ne '\\') {
                    $in_string = '';
                    next;
                }

                next if $in_string;

                if ($char eq '(' || $char eq '[' || $char eq '{') {
                    $depth++;
                } elsif ($char eq ')' || $char eq ']' || $char eq '}') {
                    if ($depth == 0) {
                        $rhs_end = $i;
                        last;
                    }
                    $depth--;
                } elsif (($char eq ';' || $char eq ',') && $depth == 0) {
                    $rhs_end = $i;
                    last;
                }
            }

            my $rhs = substr($expr, $rhs_start, $rhs_end - $rhs_start);
            # Trim leading whitespace from RHS
            $rhs =~ s/^\s+//;
            # Recursively transform $vars in RHS
            $rhs = transform_dollar_vars($rhs);

            $result .= substr($expr, $pos, $match_start - $pos);
            $result .= "this.set_$var_name($rhs)";
            $pos = $rhs_end;

            # Reset regex position
            pos($expr) = $pos;
        }
    }
    $result .= substr($expr, $pos);
    $expr = $result;

    # Process reads: $var (not followed by =)
    # Need to be careful not to transform inside strings
    $result = '';
    $pos = 0;
    @protected_ranges = (); # Recalculate for the modified expression

    while ($expr =~ /("(?:[^"\\]|\\.)*")/g) {
        push @protected_ranges, [$-[0], $+[0]];
    }
    while ($expr =~ /('(?:[^'\\]|\\.)*')/g) {
        push @protected_ranges, [$-[0], $+[0]];
    }
    while ($expr =~ /(`(?:[^`\\]|\\.)*`)/g) {
        push @protected_ranges, [$-[0], $+[0]];
    }

    while ($expr =~ /\$(\w+)(?!\s*=(?!=))/g) {
        my $var_name = $1;
        my $match_start = $-[0];
        my $match_end = $+[0];

        if (!$is_protected->($match_start)) {
            $result .= substr($expr, $pos, $match_start - $pos);
            $result .= "this.get_$var_name()";
            $pos = $match_end;
        }
    }
    $result .= substr($expr, $pos);

    return $result;
}

# Extract parameter names from arrow function expressions
sub extract_arrow_params {
    my ($expr) = @_;
    my %params;

    # Match arrow functions: (param1, param2) => or param =>
    while ($expr =~ /\(([^)]*)\)\s*=>/g) {
        my $param_str = $1;
        for my $param (split /,/, $param_str) {
            $param =~ s/^\s+|\s+$//g;
            $param =~ s/\s*=.*//;  # Remove default values
            $params{$param} = 1 if $param =~ /^\w+$/;
        }
    }

    # Single param without parens: x =>
    while ($expr =~ /\b(\w+)\s*=>/g) {
        $params{$1} = 1;
    }

    # Match regular function params: function(param1, param2)
    while ($expr =~ /\bfunction\s*\(([^)]*)\)/g) {
        my $param_str = $1;
        for my $param (split /,/, $param_str) {
            $param =~ s/^\s+|\s+$//g;
            $param =~ s/\s*=.*//;  # Remove default values
            $params{$param} = 1 if $param =~ /^\w+$/;
        }
    }

    return \%params;
}

# Add implicit this. prefix to known method calls (whitelist approach)
sub add_implicit_this {
    my ($expr, $local_vars, $known_methods) = @_;
    return $expr unless defined $expr;
    $local_vars //= {};

    # Track string positions to avoid transforming inside strings
    my @protected_ranges;
    while ($expr =~ /("(?:[^"\\]|\\.)*")/g) {
        push @protected_ranges, [$-[0], $+[0]];
    }
    while ($expr =~ /('(?:[^'\\]|\\.)*')/g) {
        push @protected_ranges, [$-[0], $+[0]];
    }
    while ($expr =~ /(`(?:[^`\\]|\\.)*`)/g) {
        push @protected_ranges, [$-[0], $+[0]];
    }

    my $is_protected = sub {
        my ($pos) = @_;
        for my $range (@protected_ranges) {
            return 1 if $pos >= $range->[0] && $pos < $range->[1];
        }
        return 0;
    };

    # Replace bare method calls: only add this. for known methods
    my $result = '';
    my $last_end = 0;

    while ($expr =~ /\b(\w+)\s*\(/g) {
        my $name = $1;
        my $match_start = $-[1];
        my $match_end = $+[0];

        next if $is_protected->($match_start);

        # Check what precedes this identifier
        my $before = substr($expr, 0, $match_start);

        # Skip if preceded by . (already a method call on something)
        next if $before =~ /\.\s*$/;

        # Skip if preceded by 'new '
        next if $before =~ /\bnew\s+$/;

        # Skip if preceded by 'function '
        next if $before =~ /\bfunction\s+$/;

        # Skip if already has this.
        next if $before =~ /\bthis\.\s*$/;

        # Skip local variables (arrow params, for loop vars)
        next if $local_vars->{$name};

        # Only add this. if it's a known method (whitelist approach)
        next unless $known_methods && $known_methods->{$name};

        # Add this. prefix
        $result .= substr($expr, $last_end, $match_start - $last_end);
        $result .= "this.$name(";
        $last_end = $match_end;
    }

    $result .= substr($expr, $last_end);
    return $result;
}

# Main transformation function that applies all shorthand transformations
sub transform_expression {
    my ($expr, $known_methods) = @_;
    return $expr unless defined $expr && $expr =~ /\S/;

    # Wrap as regular function so .call(scope) can rebind 'this' for slot scoping
    # Don't wrap expressions that are already complete (async, function)
    if ($expr =~ /^async\s/ || $expr =~ /^function[\s(]/) {
        # Already a complete expression, just apply transforms below
    }
    elsif ($expr !~ /^\(/) {
        $expr = "function(){return $expr}";
    }
    elsif($expr =~ /^\s*\(\s*([^)]+)\s*\)\s*=>\s*([{].*)/s) {
        # Arrow with block body — convert to regular function
        $expr = "function($1)$2";
    }
    elsif($expr =~ /^\s*\(\s*([^)]+)\s*\)\s*=>\s*(.*)/s) {
        # Arrow with expression body — convert to regular function
        $expr = "function($1){return $2}";
    }

    my $local_vars = extract_arrow_params($expr);
    $expr = transform_dollar_vars($expr);
    $expr = add_implicit_this($expr, $local_vars, $known_methods);
    return $expr;
}

# Parse HTML into hierarchical structure
sub parse_html {
    my ($html, $known_methods) = @_;

    my %result = (
        children => [],
    );

    # Self-closing tags
    my %void_tags = map { $_ => 1 } qw(area base br col embed hr img input meta param source track wbr);

    my @stack = (\%result);
    my $pos = 0;

    while ($html =~ /(<(?:[^>"']|"[^"]*"|'[^']*')+>|[^<]+)/g) {
        my $token = $1;

        if ($token =~ /^<\/([\w.!]+)>$/) {
            my $tag = lc($1);
            pop @stack if @stack > 1;
        }
        elsif ($token =~ /^<([\w.!]+)((?:[^>"']|"[^"]*"|'[^']*')*?)(\/?)>$/) {
            my $full_tag = lc($1);
            my $attr_str = $2 // '';
            my $self_close = $3;

            next if $full_tag =~ /^!/;

            my ($tag, $variant) = split(/!/, $full_tag, 2);

            my $element = {
                tag => $tag,
                children => [],
            };
            $element->{variant} = $variant if defined $variant;

            my %attrs;
            # First pass: match attributes with values (attr="value")
            while ($attr_str =~ /([\w:@!*]+)="([^"]*)"/g) {
                my ($attr, $value) = ($1, $2);

                # Parentheses required: 'and' has lower precedence than '||'
                if (($tag eq 'if' || $tag eq 'elseif') and $attr eq 'condition') {
                    $attrs{"*condition"} = transform_expression($value, $known_methods);
                }
                elsif ($attr eq 'for') {
                    if ($value =~ /^\[/) {
                        $value = "function(){return $value}";
                    }
                    $attrs{"*for"} = transform_expression($value, $known_methods);
                }
                elsif ($attr =~ /^@(\w+)$/) {
                    $attr = "*on" . lc($1);
                    $attrs{$attr} = transform_expression($value, $known_methods);
                }
                elsif ($value =~ /^\(/) {
                    $value = transform_expression($value, $known_methods);
                    $attrs{"*".lc($attr)} = $value;
                }
                elsif ($value =~ /\$/) {
                    $value = _transform_dollar_interpolation($value);
                    $attrs{"*".lc($attr)} = "function(){return `$value`}";
                }
                else {
                    $attrs{lc($attr)} = $value;
                }
            }

            # Second pass: match bare attributes without values (e.g., <option selected>)
            # Remove already-matched attributes with values first
            my $bare_attr_str = $attr_str;
            $bare_attr_str =~ s/[\w:@*]+="[^"]*"//g;
            while ($bare_attr_str =~ /\b([\w-]+)\b/g) {
                my $attr = lc($1);
                # Only add if not already set
                unless (exists $attrs{$attr} || exists $attrs{"*$attr"}) {
                    $attrs{$attr} = 'true';
                }
            }

            $element->{attributes} = \%attrs;

            my $parent = $stack[-1];
            push @{$parent->{children}}, $element;

            unless ($self_close || $void_tags{$tag}) {
                push @stack, $element;
            }
        }
        elsif ($token !~ /^\s*$/) {
            my $text = $token;
            $text =~ s/^\s+|\s+$//g;
            my $text_node = {};
            if ($text ne '') {
                if ($text =~ /^\s*(\([^)]*\)\s*=>)(.*)/) {
                    $text_node->{'*content'} = transform_expression($text, $known_methods);
                } elsif ($text =~ /\$/) {
                    $text = _transform_dollar_interpolation($text);
                    $text_node->{'*content'} = "function(){return `$text`}";
                } else {
                    $text_node->{content} = $text;
                }

                my $parent = $stack[-1];
                push @{$parent->{children}}, $text_node;
            }
        }
    }

    return \%result;
}

# Transform $var references in template text/attributes.
# Handles ${$var.prop}, ${$var}, and bare $var patterns.
# Inside ${...} blocks, $var is replaced without adding another ${} wrapper.
sub _transform_dollar_interpolation {
    my ($text) = @_;

    # First: transform ${...} blocks that contain $var references
    $text =~ s/\$\{([^}]*)\}/"\${" . _transform_inner_dollars($1) . "}"/ge;

    # Then: transform bare $var (not inside ${})
    $text =~ s/\$([\w]+)/\${this.get_$1()}/g;

    return $text;
}

# Transform $var references inside a ${...} expression.
# $var becomes this.get_var(), no extra ${} wrapping.
sub _transform_inner_dollars {
    my ($expr) = @_;
    $expr =~ s/\$(\w+)/this.get_$1()/g;
    return $expr;
}

1;
