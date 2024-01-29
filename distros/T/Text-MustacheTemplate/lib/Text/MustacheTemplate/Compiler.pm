package Text::MustacheTemplate::Compiler;
use 5.022000;
use strict;
use warnings;

use B ();
use List::Util qw/none/;
use Carp qw/croak/;

use Text::MustacheTemplate::Lexer;
use Text::MustacheTemplate::Parser qw/:syntaxes :variables :boxes :references/;
use Text::MustacheTemplate::Evaluator qw/retrieve_variable evaluate_section_variable evaluate_section/;
use Text::MustacheTemplate::HTML qw/escape_html/;

use constant {
    DEBUG          => !!$ENV{PERL_TEXT_MUSTACHE_TINY_COMPILER_DEBUG},
    DISCARD_RESULT => '##DISCARD##',
};

our @CONTEXT_HINT; # for optimize

our $_PADDING;
our $_PARENT;
our $_DEFAULT_OPEN_DELIMITER;
our $_DEFAULT_CLOSE_DELIMITER;
our $_CURRENT_OPEN_DELIMITER;
our $_CURRENT_CLOSE_DELIMITER;

sub compile {
    my ($class, $ast) = @_;
    die "Invalid AST: empty AST" unless @$ast; # uncoverable branch true

    my @ast = @$ast;
    my $first_delimiter_syntax = shift @ast;
    my ($type, $open_delimiter, $close_delimiter) = @$first_delimiter_syntax;
    if ($type != SYNTAX_DELIMITER) { # uncoverable branch true
        croak "Invalid AST: Delimiter should be first syntax"; # uncoverable statement
    }

    @ast = do {
        local $_DEFAULT_OPEN_DELIMITER = $open_delimiter;
        local $_DEFAULT_CLOSE_DELIMITER = $close_delimiter;
        _optimize(\@ast, 0);
    };

    # Optimize: empty
    return sub { '' } if @ast == 0;

    # Optimize: raw text only
    if (@ast == 1 && $ast[0][0] == SYNTAX_RAW_TEXT) {
        my (undef, $text) = @{ $ast[0] };
        if (!@CONTEXT_HINT && $text =~ /[\r\n](?!\z)/mano) {
            return sub {
                defined $_PADDING ? $text =~ s/(\r\n?|\n)(?!\z)/${1}${_PADDING}/mgar : $text
            };
        }
        return sub { $text };
    }

    my $code = eval {
        local $_PARENT;
        local $_DEFAULT_OPEN_DELIMITER = $open_delimiter;
        local $_DEFAULT_CLOSE_DELIMITER = $close_delimiter;
        local $_CURRENT_OPEN_DELIMITER = $open_delimiter;
        local $_CURRENT_CLOSE_DELIMITER = $close_delimiter;
        _compile(\@ast, 4);
    };
    die "Invalid AST: $@" if "$@"; # uncoverable branch true

    # wrap to define function global variables
    $code = <<__CODE__;
do {
    our (\%_BLOCKS, \@_CTX, \$_OPEN_DELIMITER, \$_CLOSE_DELIMITER);
    my (\$_name, \$_tmp, \@_section);
$code
};
__CODE__
    warn $code if DEBUG; # uncoverable branch true

    my $f = eval $code;
    die $@ if $@; # uncoverable branch true
    return $f;
}

sub _compile {
    my ($ast, $indent) = @_;

    my $initial_text = '';
    # Optimize: remove first raw text and fill initial text if no contains new lines
    if ($ast->[0]->[0] == SYNTAX_RAW_TEXT && $ast->[0]->[1] !~ /[\r\n]/mano) {
        my (undef, $text) = @{ shift @$ast };
        $initial_text = $text;
    }

    my $initial_text_perl = B::perlstring($initial_text);
    my $default_open_delimiter_perl = B::perlstring($_DEFAULT_OPEN_DELIMITER);
    my $default_close_delimiter_perl = B::perlstring($_DEFAULT_CLOSE_DELIMITER);
    my $current_open_delimiter_perl = B::perlstring($_CURRENT_OPEN_DELIMITER);
    my $current_close_delimiter_perl = B::perlstring($_CURRENT_CLOSE_DELIMITER);

    my $code = '';
    $code .= (' ' x $indent)."sub {\n";
    $code .= (' ' x $indent)."    local \@_CTX = \@_;\n";
    $code .= (' ' x $indent)."    local (\$_OPEN_DELIMITER, \$_CLOSE_DELIMITER) = ($default_open_delimiter_perl, $default_close_delimiter_perl);\n";
    $code .= (' ' x $indent)."    local \$Text::MustacheTemplate::Evaluator::LAMBDA_RENDERER = \\&_render_template_in_context;\n" if $indent == 4;
    $code .= "\n";
    $code .= (' ' x $indent)."    my \$_result = $initial_text_perl;\n";
    $code .=                      _compile_body($ast, $indent+4, '$_result');
    $code .= (' ' x $indent)."    return \$_result;\n";
    $code .= (' ' x $indent)."};\n";
    return $code;
}

sub _optimize {
    my ($ast, $depth) = @_;

    my $raw_text_syntax;
    my @optimized_ast;
    for my $syntax (@$ast) {
        if ($syntax->[0] == SYNTAX_RAW_TEXT) {
            if ($raw_text_syntax) {
                $raw_text_syntax->[1] .= $syntax->[1];
            } else {
                $raw_text_syntax = $syntax;
            }
        } elsif ($syntax->[0] == SYNTAX_COMMENT) {
            # ignore
        } elsif ($syntax->[0] == SYNTAX_DELIMITER) {
            # keep it and keep raw text syntax context both
            push @optimized_ast => $syntax;
        } else {
            if (@CONTEXT_HINT && $depth == 0) {
                if ($syntax->[0] == SYNTAX_VARIABLE) {
                    my (undef, $type, $name) = @$syntax;
                    local our $_OPEN_DELIMITER = $_DEFAULT_OPEN_DELIMITER;
                    local our $_CLOSE_DELIMITER = $_DEFAULT_CLOSE_DELIMITER;
                    local our @_CTX = @CONTEXT_HINT;
                    local $Text::MustacheTemplate::Evaluator::LAMBDA_RENDERER = \&_render_template_in_context if $Text::MustacheTemplate::LAMBDA_TEMPLATE_RENDERING;

                    my $value = $name eq '.' ? $_CTX[-1] : retrieve_variable(\@_CTX, split /\./ano, $name);
                    next unless $value;
                    if ($type == VARIABLE_HTML_ESCAPE) { # uncoverable branch false count:2
                        $value = escape_html($value);
                    } elsif ($type == VARIABLE_RAW) {
                        # nothing to do
                    } else {
                        die "Unknown variable type: $type"; # uncoverable statement
                    }

                    if ($raw_text_syntax) {
                        $raw_text_syntax->[1] .= $value;
                    } else {
                        $raw_text_syntax = [SYNTAX_RAW_TEXT, $value];
                    }
                    next;
                } elsif ($syntax->[0] == SYNTAX_BOX) {
                    my (undef, $type, $name) = @$syntax;
                    if ($type == BOX_SECTION) {
                        local our $_OPEN_DELIMITER = $_DEFAULT_OPEN_DELIMITER;
                        local our $_CLOSE_DELIMITER = $_DEFAULT_CLOSE_DELIMITER;
                        local our @_CTX = @CONTEXT_HINT;
                        local $Text::MustacheTemplate::Evaluator::LAMBDA_RENDERER = \&_render_template_in_context if $Text::MustacheTemplate::LAMBDA_TEMPLATE_RENDERING;
                        next unless $name eq '.' ? evaluate_section($_CTX[-1]) : evaluate_section_variable(\@_CTX, split /\./ano, $name);
                    } elsif ($type == BOX_INVERTED_SECTION) {
                        local our $_OPEN_DELIMITER = $_DEFAULT_OPEN_DELIMITER;
                        local our $_CLOSE_DELIMITER = $_DEFAULT_CLOSE_DELIMITER;
                        local our @_CTX = @CONTEXT_HINT;
                        local $Text::MustacheTemplate::Evaluator::LAMBDA_RENDERER = \&_render_template_in_context if $Text::MustacheTemplate::LAMBDA_TEMPLATE_RENDERING;
                        next if $name eq '.' ? evaluate_section($_CTX[-1]) : evaluate_section_variable(\@_CTX, split /\./ano, $name);
                    }
                }
            }

            if ($raw_text_syntax) {
                push @optimized_ast => $raw_text_syntax;
                $raw_text_syntax = undef;
            }
            if ($syntax->[0] == SYNTAX_BOX) {
                my @children = _optimize($syntax->[-1], $depth+1);
                $syntax = [@$syntax]; # shallow copy
                $syntax->[-1] = \@children;
            }
            push @optimized_ast => $syntax;
        }
    }
    if ($raw_text_syntax) {
        push @optimized_ast => $raw_text_syntax;
    }
    return @optimized_ast;
}

sub _compile_body {
    my ($ast, $indent, $result) = @_;

    my $code = '';
    for my $i (keys @$ast) {
        my $syntax = $ast->[$i];
        my ($type) = @$syntax;
        if ($type == SYNTAX_RAW_TEXT) { # uncoverable branch false count:5
            my (undef, $text) = @$syntax;
            next if $result eq DISCARD_RESULT;
            if ($i == $#{$ast} ? $text =~ /[\r\n](?!\z)/mano : $text =~ /[\r\n]/mano) {
                my $regex = '(\r\n?|\n)';
                $regex .= '(?!\z)' if $i == $#{$ast};
                $code .= (' ' x $indent).'$_tmp = '.B::perlstring($text).";\n";
                $code .= (' ' x $indent)."\$_tmp =~ s/$regex/\${1}\${_PADDING}/mag if defined \$_PADDING;\n";
                $code .= (' ' x $indent)."$result .= \$_tmp;\n";
            } else {
                $code .= (' ' x $indent).$result.' .= '.B::perlstring($text).";\n";
            }
        } elsif ($type == SYNTAX_DELIMITER) {
            my (undef, $open_delimiter, $close_delimiter) = @$syntax;
            ($_CURRENT_OPEN_DELIMITER, $_CURRENT_CLOSE_DELIMITER) = ($open_delimiter, $close_delimiter);
        } elsif ($type == SYNTAX_VARIABLE) {
            $code .= _compile_variable($syntax, $indent, $result);
        } elsif ($type == SYNTAX_BOX) {
            $code .= _compile_box($syntax, $indent, $result);
        } elsif ($type == SYNTAX_COMMENT) {
            # ignore
        } elsif ($type == SYNTAX_PARTIAL) {
            my (undef, $reference, $name, $padding) = @$syntax;
            $padding = B::perlstring($padding) if $padding;
            my $retriever = $reference == REFERENCE_DYNAMIC ? ($name eq '.' ? '$_CTX[-1]' : 'retrieve_variable(\@_CTX, '.(join ', ', map B::perlstring($_), split /\./ano, $name).')')
                          : $reference == REFERENCE_STATIC  ? B::perlstring($name)
                          : die "Unknown reference: $reference";
            $code .= (' ' x $indent)."\$_name = $retriever;\n";
            $code .= (' ' x $indent)."$result .= do {\n";
            $code .= (' ' x $indent)."    local \$_PADDING;\n" unless $padding;
            $code .= (' ' x $indent)."    local \$_PADDING = $padding;\n" if $padding;
            $code .= (' ' x $indent)."    \$Text::MustacheTemplate::REFERENCES{\$_name}->(\@_CTX);\n";
            $code .= (' ' x $indent)."} if exists \$Text::MustacheTemplate::REFERENCES{\$_name};\n";
        } else {
            die "Unknown syntax: $type"; # uncoverable statement
        }
    }
    return $code;
}

sub _compile_variable {
    my ($syntax, $indent, $result) = @_;

    my (undef, $type, $name) = @$syntax;
    if ($type == VARIABLE_HTML_ESCAPE) { # uncoverable branch false count:2
        my $retriever = $name eq '.' ? '$_CTX[-1]' : 'retrieve_variable(\@_CTX, '.(join ', ', map B::perlstring($_), split /\./ano, $name).')';
        return (' ' x $indent)."$result .= escape_html($retriever // '');\n";
    } elsif ($type == VARIABLE_RAW) {
        my $retriever = $name eq '.' ? '$_CTX[-1]' : 'retrieve_variable(\@_CTX, '.(join ', ', map B::perlstring($_), split /\./ano, $name).')';
        return (' ' x $indent)."$result .= $retriever // '';\n";
    } else {
        die "Unknown variable: $type"; # uncoverable statement
    }
}

sub _compile_box {
    my ($syntax, $indent, $result) = @_;

    my (undef, $type) = @$syntax;
    if ($type == BOX_SECTION) { # uncoverable branch false count:4
        my (undef, undef, $name, $inner_template, $children) = @$syntax;
        my $no_lambda = @CONTEXT_HINT && !$Text::MustacheTemplate::LAMBDA_TEMPLATE_RENDERING;

        my $inner_code = _compile_body($children, $no_lambda ? $indent+4 : $indent+8, $result);
        my $evaluator = $name eq '.'
            ? 'evaluate_section($_CTX[-1])'
            : 'evaluate_section_variable(\@_CTX, '.(join ', ', map B::perlstring($_), split /\./ano, $name).')';
        if ($no_lambda) {
            $evaluator = 'evaluate_section($_CTX[-2]) 'if $name eq '.';
            my $code = (' ' x $indent)."push \@_CTX => {};\n";
            $code .= (' ' x $indent)."for my \$ctx ($evaluator) {\n";
            $code .= (' ' x $indent)."    \$_CTX[-1] = \$ctx;\n";
            $code .=                      $inner_code;
            $code .= (' ' x $indent)."}\n";
            $code .= (' ' x $indent)."pop \@_CTX;\n";
            return $code;
        }

        my ($open_delimiter, $close_delimiter) = map B::perlstring($_), ($_CURRENT_OPEN_DELIMITER, $_CURRENT_CLOSE_DELIMITER);
        $inner_template = B::perlstring($inner_template);
        my $code = (' ' x $indent)."\@_section = $evaluator;\n";
        $code .= (' ' x $indent)."if (\$Text::MustacheTemplate::LAMBDA_TEMPLATE_RENDERING && \@_section == 1 && ref \$_section[0] eq 'CODE') {\n";
        $code .= (' ' x $indent)."    my \$code = \$_section[0];\n";
        $code .= (' ' x $indent)."    \$_tmp = \$code->($inner_template);\n";
        $code .= (' ' x $indent)."    local (\$_OPEN_DELIMITER, \$_CLOSE_DELIMITER) = ($open_delimiter, $close_delimiter);\n";
        $code .= (' ' x $indent)."    $result .= _render_template_in_context(\$_tmp);\n";
        $code .= (' ' x $indent)."} else {\n";
        $code .= (' ' x $indent)."    my \@section = \@_section;\n"; # copy to avoid rewrite same varialbe in recurse
        $code .= (' ' x $indent)."    push \@_CTX => {};\n";
        $code .= (' ' x $indent)."    for my \$ctx (\@section) {\n";
        $code .= (' ' x $indent)."        \$_CTX[-1] = \$ctx;\n";
        $code .=                          $inner_code;
        $code .= (' ' x $indent)."    }\n";
        $code .= (' ' x $indent)."    pop \@_CTX;\n";
        $code .= (' ' x $indent)."}\n";
        return $code;
    } elsif ($type == BOX_INVERTED_SECTION) {
        my (undef, undef, $name, $children) = @$syntax;
        my $evaluator = $name eq '.'
            ? 'evaluate_section($_CTX[-1])'
            : 'evaluate_section_variable(\@_CTX, '.(join ', ', map B::perlstring($_), split /\./ano, $name).')';
        my $code = (' ' x $indent)."if (!$evaluator) {\n";
        $code .= _compile_body($children, $indent+4, $result);
        $code .= (' ' x $indent)."}\n";
        return $code;
    } elsif ($type == BOX_BLOCK) {
        my (undef, undef, $name, $children) = @$syntax;
        $name = B::perlstring($name);
        unless ($_PARENT) {
            my $code = (' ' x $indent)."if (exists \$_BLOCKS{$name}) {\n";
            $code .= (' ' x $indent)."    $result .= \$_BLOCKS{$name}->(\@_CTX);\n";
            $code .= (' ' x $indent)."} else {\n";
            $code .= _compile_body($children, $indent+4, $result);
            $code .= (' ' x $indent)."}\n";
            return $code;
        }

        my ($open_delimiter, $close_delimiter) = ($_CURRENT_OPEN_DELIMITER, $_CURRENT_CLOSE_DELIMITER);
        my $sub_code = _compile($children, $indent+4);
        $sub_code = substr $sub_code, $indent+4; # remove first indent
        my $code = (' ' x $indent)."unless (exists \$_BLOCKS{$name}) {\n";
        $code .= (' ' x $indent)."    \$_BLOCKS{$name} = $sub_code";
        $code .= (' ' x $indent)."}\n";
        return $code;
    } elsif ($type == BOX_PARENT) {
        local $_PARENT = $syntax;
        my (undef, undef, $reference, $name, $children) = @$syntax;
        my $retriever = $reference == REFERENCE_DYNAMIC ? ($name eq '.' ? '$_CTX[-1]' : 'retrieve_variable(\@_CTX, '.(join ', ', map B::perlstring($_), split /\./ano, $name).')')
                      : $reference == REFERENCE_STATIC  ? B::perlstring($name)
                      : die "Unknown reference: $type";
        my $code = (' ' x $indent)."{\n";
        $code .= (' ' x $indent)."    \$_name = $retriever;\n";
        $code .= (' ' x $indent)."    my \$_parent = \$Text::MustacheTemplate::REFERENCES{\$_name} or croak \"Unknown parent template: \$_name\";\n";
        $code .= (' ' x $indent)."    local \%_BLOCKS = \%_BLOCKS;\n";
        $code .= _compile_body($children, $indent+4, DISCARD_RESULT);
        $code .= (' ' x $indent)."    $result .= do {\n";
        $code .= (' ' x $indent)."        local \$_PADDING;\n";
        $code .= (' ' x $indent)."        \$_parent->(\@_CTX);\n";
        $code .= (' ' x $indent)."    };\n";
        $code .= (' ' x $indent)."}\n";
        return $code;
    } else {
        die "Unknown box: $type"; # uncoverable statement
    }
}

sub _render_template_in_context {
    my $source = shift;
    our ($_OPEN_DELIMITER, $_CLOSE_DELIMITER);
    if ($source !~ /(?:\Q$_OPEN_DELIMITER\E|\Q$_CLOSE_DELIMITER\E)/man) {
        return $source;
    }

    local $_PADDING;
    local $Text::MustacheTemplate::Lexer::OPEN_DELIMITER  = $_OPEN_DELIMITER;
    local $Text::MustacheTemplate::Lexer::CLOSE_DELIMITER = $_CLOSE_DELIMITER;
    my @tokens = Text::MustacheTemplate::Lexer->tokenize($source);

    local $Text::MustacheTemplate::Parser::SOURCE = $source;
    my $ast = Text::MustacheTemplate::Parser->parse(@tokens);

    local @CONTEXT_HINT = our @_CTX;
    my $template = __PACKAGE__->compile($ast);
    return $template->(@_CTX);
}

1;
__END__

=encoding utf-8

=head1 NAME

Text::MustacheTemplate::Compiler - Simple mustache template compiler

=head1 SYNOPSIS

    use Text::MustacheTemplate::Lexer;
    use Text::MustacheTemplate::Parser;
    use Text::MustacheTemplate::Compiler;

    # change delimiters
    # local $Text::MustacheTemplate::Lexer::OPEN_DELIMITER = '<%';
    # local $Text::MustacheTemplate::Lexer::CLOSE_DELIMITER = '%>';

    my $source = '* {{variable}}';
    my @tokens = Text::MustacheTemplate::Lexer->tokenize();

    local $Text::MustacheTemplate::Parser::SOURCE = $source; # optional for syntax error reporting
    my $ast = Text::MustacheTemplate::Parser->parse(@tokens);

    my $template = Text::MustacheTemplate::Compiler->compile($ast);
    my $result = $template->({ variable => 'foo' });
    print "result: $result\n"; # print "* foo";

=head1 DESCRIPTION

Text::MustacheTemplate::Compiler is a compiler for Mustache tempalte.

This is low-level interface for Text::MustacheTemplate.
The APIs may be change without notice.

=head1 METHODS

=over 2

=item compile

=back

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut

