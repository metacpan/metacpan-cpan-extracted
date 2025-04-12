package Text::MustacheTemplate::Parser;
use 5.022000;
use strict;
use warnings;

use Carp qw/croak/;
use Exporter 5.57 'import';

use Text::MustacheTemplate::Lexer qw/:types/;
use Text::MustacheTemplate::Generator;

our %EXPORT_TAGS = (
    syntaxes   => [qw/SYNTAX_RAW_TEXT SYNTAX_VARIABLE SYNTAX_BOX SYNTAX_COMMENT SYNTAX_PARTIAL SYNTAX_DELIMITER/],
    variables  => [qw/VARIABLE_HTML_ESCAPE VARIABLE_RAW/],
    boxes      => [qw/BOX_SECTION BOX_INVERTED_SECTION BOX_BLOCK BOX_PARENT/],
    references => [qw/REFERENCE_STATIC REFERENCE_DYNAMIC/],
);
our @EXPORT_OK = map @$_, values %EXPORT_TAGS;

use constant {
    # enum
    SYNTAX_RAW_TEXT  => 0,
    SYNTAX_VARIABLE  => 1,
    SYNTAX_BOX       => 2,
    SYNTAX_COMMENT   => 3,
    SYNTAX_PARTIAL   => 4,
    SYNTAX_DELIMITER => 5,
};

use constant {
    # enum
    VARIABLE_HTML_ESCAPE => 0,
    VARIABLE_RAW         => 1,
};

use constant {
    # enum
    BOX_SECTION          => 0,
    BOX_INVERTED_SECTION => 1,
    BOX_BLOCK            => 2,
    BOX_PARENT           => 3,
};

use constant {
    # enum
    REFERENCE_STATIC  => 0,
    REFERENCE_DYNAMIC => 1,
};

my %TRIM_INNER_WHITESPACE_TYPES = map { $_ => 1 } (qw({ & ^ $ < >), '#', '/'); # set
my %TRIM_AROUND_WHITESPACE_TYPES = map { $_ => 1 } (qw(! ^ $ < >), '#', '/');

our $SOURCE; # optional for error reporting and optimized lambda support

sub parse {
    my $class = shift;
    my $ast =  _parse(@_);
    return $ast;
}

sub _parse {
    my @tokens = @_;

    my $last_delimiter_token;
    my @root;
    my @stack;
    my $ast = \@root;
    for my $i (0..$#tokens) {
        my $token = $tokens[$i];

        my ($type, $pos) = @$token;
        if ($type == TOKEN_RAW_TEXT) { # uncoverable branch false count:4
            my (undef, undef, $text) = @$token;
            if ($i != 1) { # optimized $i >= 2: comes delimiter token when $i == 0 always, so the first raw text token should be $i == 1.
                my $prev = $i-1; # $prev >= 1
                if (_needs_trim_around_whitespaces($tokens[$prev])) {
                    while ($prev != 1 && _needs_trim_around_whitespaces($tokens[$prev-1])) {
                        $prev--;
                    }
                    my $before_prev_token = $prev != 1 ? $tokens[$prev-1] : undef;
                    my $is_empty_before_prev = !defined $before_prev_token || $before_prev_token->[0] == TOKEN_PADDING || (
                        $before_prev_token->[0] == TOKEN_RAW_TEXT && $before_prev_token->[2] =~ /[\r\n]\z/mano
                    );
                    if ($is_empty_before_prev) {
                        $text =~ s/\A(\r\n|[\r\n])//mano;
                    }
                }
            }
            push @$ast => [SYNTAX_RAW_TEXT, $text] if $text;
        } elsif ($type == TOKEN_PADDING) {
            my (undef, undef, $padding) = @$token;
            my $needs_padding = 1;
            if ($i == $#tokens) { # uncoverable branch true
                _error($token, 'Syntax Error: Padding token should not be last'); # uncoverable statement
            }

            my $next = $i+1;
            if (_needs_trim_around_whitespaces($tokens[$next])) {
                while ($next != $#tokens && _needs_trim_around_whitespaces($tokens[$next+1])) {
                    $next++;
                }
                my $after_next_token = $next != $#tokens ? $tokens[$next+1] : undef;
                my $is_empty_after_next = !defined $after_next_token || (
                    $after_next_token->[0] == TOKEN_RAW_TEXT && $after_next_token->[2] =~ /\A[\r\n]/mano
                );
                $needs_padding = !$is_empty_after_next;
            }
            if ($needs_padding) {
                push @$ast => [SYNTAX_RAW_TEXT, $padding];
            }
        } elsif ($type == TOKEN_TAG) {
            if (@$token == 3) { # uncoverable branch false count:2
                my (undef, undef, $tag_body) = @$token;
                _error($token, 'Syntax Error: Must not contain newlines') if $tag_body =~ /[\r\n]/mo;
                $tag_body =~ s/^\s+//ano;
                $tag_body =~ s/\s+$//ano;
                push @$ast => [SYNTAX_VARIABLE, VARIABLE_HTML_ESCAPE, $tag_body];
            } elsif (@$token == 4) {
                my (undef, undef, $tag_type, $tag_body) = @$token;
                if ($TRIM_INNER_WHITESPACE_TYPES{$tag_type}) {
                    _error($token, 'Syntax Error: Must not contain newlines') if $tag_body =~ /[\r\n]/mo;
                    $tag_body =~ s/^\s+//ano;
                    $tag_body =~ s/\s+$//ano;
                }

                if ($tag_type eq '{' || $tag_type eq '&') { # uncoverable branch false count:8
                    push @$ast => [SYNTAX_VARIABLE, VARIABLE_RAW, $tag_body];
                } elsif ($tag_type eq '!') {
                    push @$ast => [SYNTAX_COMMENT, $tag_body];
                } elsif ($tag_type eq '#') {
                    push @stack => [$i, $tag_body, [SYNTAX_BOX, BOX_SECTION, $tag_body], $ast];
                    $ast = [];
                } elsif ($tag_type eq '^') {
                    push @stack => [$i, $tag_body, [SYNTAX_BOX, BOX_INVERTED_SECTION, $tag_body], $ast];
                    $ast = [];
                } elsif ($tag_type eq '$') {
                    push @stack => [$i, $tag_body, [SYNTAX_BOX, BOX_BLOCK, $tag_body], $ast];
                    $ast = [];
                } elsif ($tag_type eq '<') {
                    my $name = $tag_body;
                    my $syntax = do {
                        my $is_dynamic = substr($name,0,1) eq '*';
                        if ($is_dynamic) {
                            $name = substr $name, 1;
                            [SYNTAX_BOX, BOX_PARENT, REFERENCE_DYNAMIC, $name];
                        } else {
                            [SYNTAX_BOX, BOX_PARENT, REFERENCE_STATIC, $name];
                        }
                    };
                    push @stack => [$i, $tag_body, $syntax, $ast];
                    $ast = [];
                } elsif ($tag_type eq '/') {
                    _error($token, 'Syntax Error: Unbalanced Section') unless @stack;
                    my $item = pop @stack;
                    my ($open_idx, $open_tag_body, $syntax, $parent) = @$item;
                    s/\s*//go for ($open_tag_body, $tag_body);
                    if ($open_tag_body ne $tag_body) {
                        _error($token, "Syntax Error: Unbalanced Section: open=$open_tag_body close=$tag_body");
                    }
                    if ($syntax->[1] == BOX_SECTION) {
                        # keep inner template to support lambda
                        my $inner_template = defined $SOURCE
                            ? substr $SOURCE, $tokens[$open_idx+1][1], $pos-$tokens[$open_idx+1][1]
                            : Text::MustacheTemplate::Generator->generate_from_tokens($last_delimiter_token, @tokens[$open_idx+1..$i-1]);
                        push @$syntax => $inner_template;
                    }
                    push @$syntax => $ast;
                    $ast = $parent;
                    push @$ast => $syntax;
                } elsif ($tag_type eq '>') {
                    my $name = $tag_body;
                    $name =~ s/\s*//go;

                    # comes delimiter token when $i == 0 always, so the first tag token should be $i == 1.
                    my $padding;
                    if ($i != 1) {
                        my $prev = $tokens[$i-1];
                        if ($prev->[0] == TOKEN_PADDING) {
                            $padding = $prev->[2] ;
                            push @$ast => [SYNTAX_RAW_TEXT, $padding];
                        }
                    }

                    my $is_dynamic = substr($name,0,1) eq '*';
                    if ($is_dynamic) {
                        $name = substr $name, 1;
                        push @$ast => [SYNTAX_PARTIAL, REFERENCE_DYNAMIC, $name, $padding];
                    } else {
                        push @$ast => [SYNTAX_PARTIAL, REFERENCE_STATIC, $name, $padding];
                    }
                } else {
                    _error($token, "Syntax Error: Unknown Tag Type: '$tag_type'"); # uncoverable statement
                }
            } else {
                _error($token, 'Syntax Error: Unknown Token'); # uncoverable statement
            }
        } elsif ($type == TOKEN_DELIMITER) {
            my @delimiters = @$token[3,4];
            $last_delimiter_token = $token;
            push @$ast => [SYNTAX_DELIMITER, @delimiters];
        } else {
            _error($token, 'Syntax Error: Unknown Token'); # uncoverable statement
        }
    }
    if (@stack) {
        my $item = pop @stack;
        my (undef, undef, $open_token) = @$item;
        _error($open_token, 'Syntax Error: Unbalanced Section');
    }
    return \@root;
}

sub _needs_trim_around_whitespaces {
    my $token = shift;
    my ($type) = @$token;

    if ($type == TOKEN_DELIMITER) {
        my (undef, undef, $tag_body) = @$token;
        return defined $tag_body; ## tag body is undef when first implicit TOKEN_DELIMITER
    } elsif ($type == TOKEN_TAG) {
        if (@$token == 4) {
            my (undef, undef, $tag_type, undef) = @$token;
            return !!$TRIM_AROUND_WHITESPACE_TYPES{$tag_type};
        } else {
            return !!0;
        }
    }
    return !!0;
}

sub _error {
    my ($token, $msg) = @_;
    croak $msg unless $SOURCE;

    my $src   = $SOURCE;
    my $curr  = $token->[1];
    my $line  = 1;
    my $start = 0;
    while ($src =~ /$/smgco and pos $src <= $curr) {# uncoverable condition left
        $start = pos $src;
        $line++;
    }
    my $end = pos $src;
    my $len = $curr - $start;
    $len-- if $len > 0;

    my $trace = join "\n",
        "${msg}: line:$line",
        substr($src, $start || 0, $end - $start),
        (' ' x $len) . '^';
    croak $trace, "\n";
}

1;
__END__

=encoding utf-8

=head1 NAME

Text::MustacheTemplate::Parser - Simple mustache template parser

=head1 SYNOPSIS

    use Text::MustacheTemplate::Lexer;
    use Text::MustacheTemplate::Parser;

    # change delimiters
    # local $Text::MustacheTemplate::Lexer::OPEN_DELIMITER = '<%';
    # local $Text::MustacheTemplate::Lexer::CLOSE_DELIMITER = '%>';

    my $source = '* {{variable}}';
    my @tokens = Text::MustacheTemplate::Lexer->tokenize($source);
    local $Text::MustacheTemplate::Parser::SOURCE = $source; # optional for syntax error reporting
    my $ast = Text::MustacheTemplate::Parser->parse(@tokens);

=head1 DESCRIPTION

Text::MustacheTemplate::Parser is a simple parser for Mustache template.

This is low-level interface for Text::MustacheTemplate.
The APIs may be change without notice.

=head1 METHODS

=over 2

=item parse(\@tokens)

Parses the token array from L<Text::MustacheTemplate::Lexer> and converts it into an abstract syntax tree (AST).
Returns a nested ArrayRef structure representing the template's parsed form.

The AST consists of nodes, where each node is an array reference with the following structure:

=over 4

=item * First element: Node type constant (see L</SYNTAXES>)

=item * Remaining elements: Node-specific data

=back

=back

=head1 SYNTAXES

The following constants define the various syntax node types that make up the abstract syntax tree (AST) after parsing.

=over 2

=item SYNTAX_RAW_TEXT

Represents literal text content in the template. 

Format: C<[SYNTAX_RAW_TEXT, $text]>

=item SYNTAX_VARIABLE

Represents a variable interpolation tag (e.g., {{name}} or {{{name}}}).

Format: C<[SYNTAX_VARIABLE, $escape_type, $variable_name]>

Where $escape_type is one of:

=over 4

=item VARIABLE_HTML_ESCAPE

The variable should be HTML-escaped before output (used with {{name}})

=item VARIABLE_RAW

The variable should not be escaped (used with {{{name}}} or {{&name}})

=back

=item SYNTAX_BOX

Represents block-like structures that may contain child content.

Format: C<[SYNTAX_BOX, $box_type, ...]> where the remaining parameters depend on the box type.

Box types include:

=over 4

=item BOX_SECTION

A regular Mustache section ({{#section}}...{{/section}}).

Format: C<[SYNTAX_BOX, BOX_SECTION, $name, $inner_template, \@children]>

$inner_template contains the raw template source of the section for lambda support.

=item BOX_INVERTED_SECTION

An inverted section ({{^section}}...{{/section}}) which renders when the value is falsy.

Format: C<[SYNTAX_BOX, BOX_INVERTED_SECTION, $name, \@children]>

=item BOX_BLOCK

A block definition ({{$block}}...{{/block}}) for template inheritance.

Format: C<[SYNTAX_BOX, BOX_BLOCK, $name, \@children]>

=item BOX_PARENT

A parent template reference ({{<parent}}...{{/parent}}) for template inheritance.

Format: C<[SYNTAX_BOX, BOX_PARENT, $reference_type, $name, \@children]>

Where $reference_type is one of:

=over 4

=item REFERENCE_STATIC

A static parent template name

=item REFERENCE_DYNAMIC

A dynamic parent template name (e.g., {{<*dynamic}})

=back

=back

=item SYNTAX_COMMENT

Represents a comment ({{! comment }}) which doesn't appear in the output.

Format: C<[SYNTAX_COMMENT, $comment_text]>

=item SYNTAX_PARTIAL

Represents including a partial template ({{> partial}}).

Format: C<[SYNTAX_PARTIAL, $reference_type, $name, $padding]>

Where $reference_type is one of:

=over 4

=item REFERENCE_STATIC

A static partial template name

=item REFERENCE_DYNAMIC

A dynamic partial template name (e.g., {{>*dynamic}})

=back

$padding contains any whitespace that preceded the tag, used for indenting partial content.

=item SYNTAX_DELIMITER

Represents a delimiter change ({{=<% %>=}}).

Format: C<[SYNTAX_DELIMITER, $open_delimiter, $close_delimiter]>

=back

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut

