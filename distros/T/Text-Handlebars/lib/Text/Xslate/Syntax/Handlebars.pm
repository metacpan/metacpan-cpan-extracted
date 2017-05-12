package Text::Xslate::Syntax::Handlebars;
our $AUTHORITY = 'cpan:DOY';
$Text::Xslate::Syntax::Handlebars::VERSION = '0.05';
use Mouse;

use Carp 'confess';
use Text::Xslate::Util qw($DEBUG $NUMBER neat p);

use Text::Handlebars::Symbol;

extends 'Text::Xslate::Parser';

use constant _DUMP_PROTO => scalar($DEBUG =~ /\b dump=proto \b/xmsi);

my $nl = qr/\x0d?\x0a/;

my $bracket_string = qr/\[ [^\]]* \]/xms;
my $STRING = qr/(?: $Text::Xslate::Util::STRING | $bracket_string )/xms;

my $single_char = '[.#^/>&;=]';
my $OPERATOR_TOKEN = sprintf(
    "(?:%s|$single_char)",
    join('|', map{ quotemeta } qw(..))
);

sub _build_identity_pattern { qr/\@?[A-Za-z_][A-Za-z0-9_?-]*/ }
sub _build_comment_pattern  { qr/\![^;]*/                }

sub _build_line_start { undef }
sub _build_tag_start  { '{{'  }
sub _build_tag_end    { '}}'  }

sub _build_shortcut_table { +{} }

sub symbol_class { 'Text::Handlebars::Symbol' }

sub split_tags {
    my $self = shift;
    my ($input) = @_;

    my $tag_start = $self->tag_start;
    my $tag_end   = $self->tag_end;

    my $lex_comment = $self->comment_pattern;
    my $lex_code    = qr/(?: $lex_comment | (?: $STRING | [^\['"] ) )/xms;

    my @chunks;

    my @raw_text;
    my @delimiters;

    my $close_tag;
    my $standalone = 1;
    while ($input) {
        if ($close_tag) {
            my $start = 0;
            my $pos;
            while(($pos = index $input, $close_tag, $start) >= 0) {
                my $code = substr $input, 0, $pos;
                $code =~ s/$lex_code//g;
                if(length($code) == 0) {
                    last;
                }
                $start = $pos + 1;
            }

            if ($pos >= 0) {
                my $code = substr $input, 0, $pos, '';
                $input =~ s/\A\Q$close_tag//
                    or die "Oops!";

                # XXX this is ugly, but i don't know how to get the parsing
                # right otherwise if we also need to support ^foo
                $code = 'else' if $code eq '^';

                my @extra;

                my $autochomp = $code =~ m{^[!#^/=>]} || $code eq 'else';

                if ($code =~ s/^=\s*([^\s]+)\s+([^\s]+)\s*=$//) {
                    ($tag_start, $tag_end) = ($1, $2);
                }
                elsif ($code =~ /^=/) {
                    die "Invalid delimiter tag: $code";
                }

                if ($autochomp && $standalone) {
                    if ($input =~ /\A\s*(?:\n|\z)/) {
                        $input =~ s/\A$nl//;
                        if (@chunks > 0 && $chunks[-1][0] eq 'text' && $code !~ m{^>}) {
                            $chunks[-1][1] =~ s/^(?:(?!\n)\s)*\z//m;
                            if (@raw_text) {
                                $raw_text[-1] =~ s/^(?:(?!\n)\s)*\z//m;
                            }
                        }
                    }
                }
                else {
                    $standalone = 0;
                }

                if ($code =~ m{^/} || $code eq 'else') {
                    push @extra, pop @raw_text;
                    push @extra, pop @delimiters;
                    if (@raw_text) {
                        $raw_text[-1] .= $extra[0];
                    }
                }
                if (@raw_text) {
                    if ($close_tag eq '}}}') {
                        $raw_text[-1] .= '{{{' . $code . '}}}';
                    }
                    else {
                        $raw_text[-1] .= $tag_start . $code . $tag_end;
                    }
                }
                if ($code =~ m{^[#^]} || $code eq 'else') {
                    push @raw_text, '';
                    push @delimiters, [$tag_start, $tag_end];
                }

                if (length($code)) {
                    push @chunks, [
                        ($close_tag eq '}}}' ? 'raw_code' : 'code'),
                        $code,
                        @extra,
                    ];
                }

                undef $close_tag;
            }
            else {
                last; # the end tag is not found
            }
        }
        elsif ($input =~ s/\A\Q$tag_start//) {
            if ($tag_start eq '{{' && $input =~ s/\A\{//) {
                $close_tag = '}}}';
            }
            else {
                $close_tag = $tag_end;
            }
        }
        elsif ($input =~ s/\A([^\n]*?(?:\n|(?=\Q$tag_start\E)|\z))//) {
            my $text = $1;
            if (length($text)) {
                push @chunks, [ text => $text ];

                if ($standalone) {
                    $standalone = $text =~ /(?:^|\n)\s*$/;
                }
                else {
                    $standalone = $text =~ /\n\s*$/;
                }

                if (@raw_text) {
                    $raw_text[-1] .= $text;
                }
            }
        }
        else {
            confess "Oops: unreached code, near " . p($input);
        }
    }

    if ($close_tag) {
        # calculate line number
        my $orig_src = $_[0];
        substr $orig_src, -length($input), length($input), '';
        my $line = ($orig_src =~ tr/\n/\n/);
        $self->_error("Malformed templates detected",
            neat((split /\n/, $input)[0]), ++$line,
        );
    }

    return @chunks;
}

sub preprocess {
    my $self = shift;
    my ($input) = @_;

    my @chunks = $self->split_tags($input);

    my $code = '';
    for my $chunk (@chunks) {
        my ($type, $content, $raw_text, $delimiters) = @$chunk;
        if ($type eq 'text') {
            $content =~ s/(["\\])/\\$1/g;
            $code .= qq{print_raw "$content";\n}
                if length($content);
        }
        elsif ($type eq 'code') {
            my $extra = '';
            if ($content =~ s{^/}{}) {
                $chunk->[2] =~ s/(["\\])/\\$1/g;
                $chunk->[3][0] =~ s/(["\\])/\\$1/g;
                $chunk->[3][1] =~ s/(["\\])/\\$1/g;

                $extra = '"'
                       . join('" "', $chunk->[2], @{ $chunk->[3] })
                       . '"';
                $code .= qq{/$extra $content;\n};
            }
            elsif ($content eq 'else') {
                # XXX fix duplication
                $chunk->[2] =~ s/(["\\])/\\$1/g;
                $chunk->[3][0] =~ s/(["\\])/\\$1/g;
                $chunk->[3][1] =~ s/(["\\])/\\$1/g;

                $extra = '"'
                       . join('" "', $chunk->[2], @{ $chunk->[3] })
                       . '"';
                $code .= qq{$content $extra;\n};
            }
            else {
                $code .= qq{$content;\n};
            }
        }
        elsif ($type eq 'raw_code') {
            $code .= qq{&$content;\n};
        }
        else {
            $self->_error("Oops: Unknown token: $content ($type)");
        }
    }

    print STDOUT $code, "\n" if _DUMP_PROTO;
    return $code;
}

# XXX advance has some syntax special cases in it, probably need to override
# it too eventually

sub init_symbols {
    my $self = shift;

    for my $type (qw(name key literal)) {
        my $symbol = $self->symbol("($type)");
        $symbol->arity($type);
        $symbol->set_nud($self->can("nud_$type"));
        $symbol->lbp(10);
    }

    for my $this (qw(. this)) {
        my $symbol = $self->symbol($this);
        $symbol->arity('key');
        $symbol->id('.');
        $symbol->lbp(10);
        $symbol->set_nud($self->can('nud_key'));
    }

    for my $field_access (qw(. /)) {
        $self->infix($field_access, 256, $self->can('led_dot'));
    }

    for my $block ('#', '^') {
        $self->symbol($block)->set_std($self->can('std_block'));
    }

    for my $else (qw(/ else)) {
        $self->symbol($else)->is_block_end(1);
    }

    $self->symbol('>')->set_std($self->can('std_partial'));

    $self->symbol('&')->set_nud($self->can('nud_mark_raw'));
    $self->symbol('..')->set_nud($self->can('nud_uplevel'));
    $self->symbol('..')->lbp(10);

    $self->infix('=', 20, $self->can('led_equals'));
}

# copied from Text::Xslate::Parser, but using different definitions of
# $STRING and $OPERATOR_TOKEN
sub tokenize {
    my($parser) = @_;

    local *_ = \$parser->{input};

    my $comment_rx = $parser->comment_pattern;
    my $id_rx      = $parser->identity_pattern;
    my $count      = 0;
    TRY: {
        /\G (\s*) /xmsgc;
        $count += ( $1 =~ tr/\n/\n/);
        $parser->following_newline( $count );

        if(/\G $comment_rx /xmsgc) {
            redo TRY; # retry
        }
        elsif(/\G ($id_rx)/xmsgc){
            return [ name => $1 ];
        }
        elsif(/\G ($NUMBER | $STRING)/xmsogc){
            return [ literal => $1 ];
        }
        elsif(/\G ($OPERATOR_TOKEN)/xmsogc){
            return [ operator => $1 ];
        }
        elsif(/\G (\S+)/xmsgc) {
            Carp::confess("Oops: Unexpected token '$1'");
        }
        else { # empty
            return [ special => '(end)' ];
        }
    }
}

sub nud_name {
    my $self = shift;
    my ($symbol) = @_;

    my $name = $self->SUPER::nud_name($symbol);

    my $call = $self->call($name);

    if ($self->token->is_defined) {
        push @{ $call->second }, $self->expression(0);
    }

    return $call;
}

sub nud_key {
    my $self = shift;
    my ($symbol) = @_;

    return $symbol->clone(arity => 'key');
}

sub led_dot {
    my $self = shift;
    my ($symbol, $left) = @_;

    # XXX hack to make {{{.}}} work, but in general this syntax is ambiguous
    # and i'm not going to deal with it
    if ($left->arity eq 'call' && $left->first->id eq 'mark_raw') {
        push @{ $left->second }, $symbol->nud($self);
        return $left;
    }

    my $dot = $self->make_field_lookup($left, $self->token, $symbol);

    $self->advance;

    return $dot;
}

sub std_block {
    my $self = shift;
    my ($symbol) = @_;

    my $inverted = $symbol->id eq '^';

    my $name = $self->expression(0);

    if ($name->arity ne 'key' && $name->arity ne 'key_field' && $name->arity ne 'call') {
        $self->_unexpected("opening block name", $self->token);
    }
    my $name_string = $self->_field_to_string($name);

    $self->advance(';');

    my %block;
    my $context = 'if';
    $block{$context}{body} = $self->statements;

    if ($self->token->id eq 'else') {
        $self->advance;

        $block{$context}{raw_text} = $self->token;
        $self->advance;
        $block{$context}{open_tag} = $self->token;
        $self->advance;
        $block{$context}{close_tag} = $self->token;
        $self->advance;

        $context = 'else';
        $block{$context}{body} = $self->statements;
    }

    $self->advance('/');

    $block{$context}{raw_text} = $self->token;
    $self->advance;
    $block{$context}{open_tag} = $self->token;
    $self->advance;
    $block{$context}{close_tag} = $self->token;
    $self->advance;

    if ($inverted) {
        ($block{if}, $block{else}) = ($block{else}, $block{if});
        if (!$block{if}) {
            $block{if}{body}      = $self->literal('');
            $block{if}{raw_text}  = $self->literal('');
            $block{if}{open_tag}  = $block{else}{open_tag};
            $block{if}{close_tag} = $block{else}{close_tag};
        }
    }

    my $closing_name = $self->expression(0);

    if ($closing_name->arity ne 'key' && $closing_name->arity ne 'key_field' && $closing_name->arity ne 'call') {
        $self->_unexpected("closing block name", $self->token);
    }
    my $closing_name_string = $self->_field_to_string($closing_name);

    if ($name_string ne $closing_name_string) {
        $self->_unexpected('/' . $name_string, $self->token);
    }

    $self->advance(';');

    return $self->print_raw(
        $name->clone(
            arity  => 'block',
            first  => $name,
            second => \%block,
        ),
    );
}

sub nud_mark_raw {
    my $self = shift;
    my ($symbol) = @_;

    return $self->symbol('mark_raw')->clone(
        line => $symbol->line,
    )->nud($self);
}

sub nud_uplevel {
    my $self = shift;
    my ($symbol) = @_;

    return $symbol->clone(arity => 'variable');
}

sub std_partial {
    my $self = shift;
    my ($symbol) = @_;

    my $partial = $self->token->clone(arity => 'literal');
    $self->advance;
    my $args;
    if ($self->token->id ne ';') {
        $args = $self->expression(0);
    }
    $self->advance(';');

    return $symbol->clone(
        arity  => 'partial',
        first  => ($partial->id =~ /\./ ? $partial : [ $partial ]),
        second => $args,
    );
}

sub led_equals {
    my $self = shift;
    my ($symbol, $left) = @_;

    my $right = $self->expression($symbol->lbp);

    return $symbol->clone(
        arity  => 'pair',
        first  => $left->clone(arity => 'literal'),
        second => $right,
    );
}

sub undefined_name {
    my $self = shift;
    my ($name) = @_;

    return $self->symbol('(key)')->clone(id => $name);
}

sub define_function {
    my $self = shift;
    my (@names) = @_;

    $self->SUPER::define_function(@_);
    for my $name (@names) {
        my $symbol = $self->symbol($name);
        $symbol->set_nud($self->can('nud_name'));
        $symbol->lbp(10);
    }

    return;
}

sub define_helper {
    my $self = shift;
    my (@names) = @_;

    $self->define_function(@names);
    for my $name (@names) {
        my $symbol = $self->symbol($name);
        $symbol->is_helper(1);
    }

    return;
}

sub parse_literal {
    my $self = shift;
    my ($literal) = @_;

    if ($literal =~ /\A\[(.*)\]\z/ms) {
        $literal = $1;
        $literal =~ s/(["\\])/\\$1/g;
        $literal = '"' . $literal . '"';
    }

    return $self->SUPER::parse_literal($literal);
}

sub is_valid_field {
    my $self = shift;
    my ($field) = @_;

    # allow foo.[10]
    return 1 if $field->arity eq 'literal';
    # undefined symbols are all treated as keys - see undefined_name
    return 1 if $field->arity eq 'key';
    # allow ../../foo
    return 1 if $field->id eq '..';

    return;
}

sub expression {
    my $self = shift;
    my ($rbp) = @_;

    my $token = $self->token;
    $self->advance;
    my $left = $token->nud($self);

    while ($rbp < $self->token->lbp) {
        $token = $self->token;
        if ($token->has_led) {
            $self->advance;
            $left = $token->led($self, $left);
        }
        else {
            if ($left->arity ne 'call') {
                $self->_error("Unexpected " . $token->arity, $left);
            }
            push @{ $left->second }, $self->expression($token->lbp);
        }
    }

    return $left;
}

sub call {
    my $self = shift;

    my $call = $self->SUPER::call(@_);
    $call->is_helper($call->first->is_helper);
    return $call;
}

sub make_field_lookup {
    my $self = shift;
    my ($var, $field, $dot) = @_;

    if (!$self->is_valid_field($field)) {
        $self->_unexpected("a field name", $field);
    }

    $dot ||= $self->symbol('.');

    return $dot->clone(
        arity  => 'key_field',
        first  => $var,
        second => $field->clone(arity => 'literal'),
    );
}

sub print_raw {
    my $self = shift;
    return $self->print(@_)->clone(id => 'print_raw');
}

sub literal {
    my $self = shift;
    my ($value) = @_;
    return $self->symbol('(literal)')->clone(id => $value);
}

sub _field_to_string {
    my $self = shift;
    my ($symbol) = @_;

    # name and key can just be returned
    return $symbol->id
        unless $symbol->arity eq 'field';

    # field accesses should recurse on the first and append the second
    return $self->_field_to_string($symbol->first) . '.' . $symbol->second->id;
}

__PACKAGE__->meta->make_immutable;
no Mouse;

=for Pod::Coverage
  call
  define_function
  define_helper
  expression
  init_symbols
  is_valid_field
  led_dot
  led_equals
  literal
  make_field_lookup
  nud_key
  nud_mark_raw
  nud_name
  nud_uplevel
  parse_literal
  preprocess
  print_raw
  split_tags
  std_block
  std_partial
  symbol_class
  tokenize
  undefined_name

=cut

1;
