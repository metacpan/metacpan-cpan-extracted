package Text::Handlebars::Compiler;
our $AUTHORITY = 'cpan:DOY';
$Text::Handlebars::Compiler::VERSION = '0.05';
use Mouse;

extends 'Text::Xslate::Compiler';

use Try::Tiny;

has '+syntax' => (
    default => 'Handlebars',
);

sub define_helper { shift->parser->define_helper(@_) }

sub _generate_block_body {
    my $self = shift;
    my ($node) = @_;

    my @compiled = map { $self->compile_ast($_) } @{ $node->second };

    unshift @compiled, $self->_localize_vars($node->first)
        if $node->first;

    return @compiled;
}

sub _generate_key {
    my $self = shift;
    my ($node) = @_;

    my $var = $node->clone(arity => 'variable');

    return $self->compile_ast($self->check_lambda($var));
}

sub _generate_key_field {
    my $self = shift;
    my ($node) = @_;

    my $field = $node->clone(arity => 'field');

    return $self->compile_ast($self->check_lambda($field));
}

sub _generate_call {
    my $self = shift;
    my ($node) = @_;

    if ($node->is_helper) {
        my @args;
        my @hash;
        for my $arg (@{ $node->second }) {
            if ($arg->arity eq 'pair') {
                push @hash, $arg->first, $arg->second;
            }
            else {
                push @args, $arg;
            }
        }

        my $hash = $self->make_hash(@hash);

        unshift @args, $self->vars;

        if ($node->is_block_helper) {
            push @{ $node->first->second }, $hash;
            $node->second(\@args);
        }
        else {
            $node->second([ @args, $hash ]);
        }
    }

    return $self->SUPER::_generate_call($node);
}

sub _generate_partial {
    my $self = shift;
    my ($node) = @_;

    my $file = $node->first;
    if (ref($file) eq 'ARRAY') {
        $file = $node->clone(
            arity  => 'binary',
            id     => '~',
            first  => $file->[0],
            second => $node->clone(arity => 'suffix'),
        );
    }

    my $args = $node->second;
    if ($args) {
        $args = [ $self->new_vars($args) ];
    }

    return (
        $self->compile_ast(
            $self->make_ternary(
                $self->find_file($file->clone),
                $node->clone(
                    arity  => 'include',
                    id     => 'include',
                    first  => $file->clone,
                    second => $args,
                ),
                $self->literal(''),
            ),
        ),
    );
}

sub _generate_suffix {
    my $self = shift;
    my ($node) = @_;

    return (
        $self->opcode('suffix'),
    );
}

sub find_file {
    my $self = shift;
    my ($filename) = @_;

    return $filename->clone(
        arity => 'unary',
        id    => 'find_file',
        first => $filename,
    );
}

sub _generate_for {
    my $self = shift;
    my ($node) = @_;

    my @opcodes = $self->SUPER::_generate_for(@_);
    return (
        @opcodes,
        $self->opcode('nil'),
    );
}

sub _generate_block {
    my $self = shift;
    my ($node) = @_;

    my $name = $node->first;
    my %block = %{ $node->second };

    if ($name->arity eq 'call') {
        return $self->compile_ast(
            $name->clone(
                first => $self->call(
                    $node,
                    '(make_block_helper)',
                    $self->vars,
                    $name->first,
                    $block{if}{raw_text}->clone,
                    ($block{else}
                        ? $block{else}{raw_text}->clone
                        : $self->literal('')),
                ),
                is_block_helper => 1,
            ),
        );
    }

    my $iterations = $self->make_ternary(
        $self->is_falsy($name->clone),
        $self->make_array($self->literal(1)),
        $self->make_ternary(
            $self->is_array_ref($name->clone),
            $name->clone,
            $self->make_array($self->literal(1)),
        ),
    );

    my $loop_var = $self->parser->symbol('(loop_var)')->clone(arity => 'variable');

    my $body_block = [
        $self->make_ternary(
            $self->is_falsy($name->clone),
            $name->clone(
                arity  => 'block_body',
                first  => undef,
                second => [ $block{else}{body} ],
            ),
            $name->clone(
                arity  => 'block_body',
                first  => [
                    $self->new_vars($name->clone, $self->iterator_index),
                ],
                second => [ $block{if}{body} ],
            ),
        ),
    ];

    my $var = $name->clone(arity => 'variable');
    return $self->compile_ast(
        $self->make_ternary(
            $self->is_code_ref($var->clone),
            $self->run_code(
                $var->clone,
                $block{if}{raw_text}->clone,
                $block{if}{open_tag}->clone,
                $block{if}{close_tag}->clone,
            ),
            $self->parser->symbol('(for)')->clone(
                arity  => 'for',
                first  => $iterations,
                second => [$loop_var],
                third  => $body_block,
            ),
        ),
    );
}

sub _generate_unary {
    my $self = shift;
    my ($node) = @_;

    # XXX copied from Text::Xslate::Compiler because it uses a hardcoded list
    # of unary ops
    if ($self->is_unary($node->id)) {
        my @code = (
            $self->compile_ast($node->first),
            $self->opcode($node->id)
        );
        # render_string can't be constant folded, because it depends on the
        # current vars
        if ($Text::Xslate::Compiler::OPTIMIZE and $self->_code_is_literal(@code) && $node->id ne 'render_string' && $node->id ne 'find_file') {
            $self->_fold_constants(\@code);
        }
        return @code;
    }
    else {
        return $self->SUPER::_generate_unary(@_);
    }
}

sub is_unary {
    my $self = shift;
    my ($id) = @_;

    my %unary = (
        map { $_ => 1 } qw(builtin_is_array_ref builtin_is_hash_ref is_code_ref
                           find_file)
    );

    return $unary{$id};
}

sub _generate_array_length {
    my $self = shift;
    my ($node) = @_;

    my $max_index = $self->parser->symbol('(max_index)')->clone(
        id    => 'max_index',
        arity => 'unary',
        first => $node->first,
    );

    return (
        $self->compile_ast($max_index),
        $self->opcode('move_to_sb'),
        $self->opcode('literal', 1),
        $self->opcode('add'),
    );
}

sub _generate_run_code {
    my $self = shift;
    my ($node) = @_;

    my $to_render = $node->clone(arity => 'call');

    if ($node->third) {
        my ($open_tag, $close_tag) = @{ $node->third };
        $to_render = $self->make_ternary(
            $self->parser->symbol('==')->clone(
                arity  => 'binary',
                first  => $close_tag->clone,
                second => $self->literal('}}'),
            ),
            $to_render,
            $self->join('{{= ', $open_tag, ' ', $close_tag, ' =}}', $to_render)
        );
    }

    # XXX turn this into an opcode
    my $render_string = $self->call(
        $node,
        '(render_string)',
        $to_render,
        $self->vars,
    );

    return $self->compile_ast($render_string);
}

sub _generate_new_vars {
    my $self = shift;
    my ($node) = @_;

    my ($vars, $value, $i) = ($node->first, $node->second, $node->third);

    my $lvar_id = $self->lvar_id;
    local $self->{lvar_id} = $self->lvar_use(1);

    my @code;

    push @code, $self->compile_ast($value);
    push @code, $self->opcode('save_to_lvar', $lvar_id);
    my $lvar_value = $value->clone(arity => 'lvar', id => $lvar_id);

    if ($i) {
        my $value_at_index = $value->clone(
            arity  => 'field',
            first  => $value->clone,
            second => $i->clone,
        );

        push @code, $self->compile_ast(
            $self->make_ternary(
                $self->is_array_ref($lvar_value->clone),
                $self->save_lvar(
                    $lvar_id,
                    $self->make_ternary(
                        $self->is_hash_ref($value_at_index->clone),
                        $self->merge_hash(
                            $self->make_hash(
                                $self->literal('.'),
                                $value_at_index->clone,
                            ),
                            $value_at_index->clone,
                        ),
                        $self->make_hash(
                            $self->literal('.'),
                            $value_at_index->clone,
                        ),
                    ),
                ),
            ),
        );
    }
    else {
        push @code, $self->compile_ast(
            $self->make_ternary(
                $self->is_array_ref($lvar_value->clone),
                $self->save_lvar(
                    $lvar_id,
                    $self->make_hash(
                        $self->literal('.'),
                        $value->clone,
                    ),
                ),
            ),
        );
    }

    push @code, $self->compile_ast(
        $self->save_lvar(
            $lvar_id,
            $self->make_ternary(
                $self->is_hash_ref($lvar_value->clone),
                $self->merge_hash(
                    ($i
                        ? (
                            $self->make_hash(
                                $self->literal('@index'), $i->clone
                            )
                        )
                        : ()),
                    $vars->clone,
                    $lvar_value->clone,
                    $self->make_hash(
                        $self->literal('..'),
                        $vars->clone,
                    ),
                ),
                $vars->clone,
            ),
        ),
    );

    push @code, $self->opcode('load_lvar', $lvar_id);

    return @code;
}

sub _generate_lvar {
    my $self = shift;
    my ($node) = @_;

    return (
        $self->opcode('load_lvar', $node->id),
    );
}

sub _generate_save_lvar {
    my $self = shift;
    my ($node) = @_;

    return (
        $self->compile_ast($node->first),
        $self->opcode('save_to_lvar', $node->id),
    );
}

sub _generate_merge_hash {
    my $self = shift;
    my ($node) = @_;

    my $lvar_id = $self->lvar_id;
    local $self->{lvar_id} = $self->lvar_use(1);

    return (
        $self->compile_ast($node->first),
        $self->opcode('save_to_lvar', $lvar_id),
        $self->compile_ast($node->second),
        $self->opcode('move_to_sb'),
        $self->opcode('load_lvar', $lvar_id),
        $self->opcode('merge_hash'),
    );
}

sub join {
    my $self = shift;
    my (@args) = @_;

    @args = map { $self->literalize($_) } @args;

    my $joined = shift @args;
    for my $arg (@args) {
        $joined = $self->parser->symbol('~')->clone(
            arity  => 'binary',
            first  => $joined,
            second => $arg,
        );
    }

    return $joined;
}

sub literalize {
    my $self = shift;
    my ($val) = @_;

    return $val->clone if blessed($val);
    return $self->literal($val);
}

sub call {
    my $self = shift;
    my ($node, $name, @args) = @_;

    my $code = $self->parser->symbol('(name)')->clone(
        arity => 'name',
        id    => $name,
        line  => $node->line,
    );

    return $self->parser->call($code, @args);
}

sub make_ternary {
    my $self = shift;
    my ($if, $then, $else) = @_;
    return $self->parser->symbol('?:')->clone(
        arity  => 'if',
        first  => $if,
        second => $then,
        third  => $else,
    );
}

sub vars {
    my $self = shift;
    return $self->parser->symbol('(vars)')->clone(arity => 'vars');
}

sub iterator_index {
    my $self = shift;

    return $self->parser->symbol('(iterator)')->clone(
        arity => 'iterator',
        id    => '$~(loop_var)',
        first => $self->parser->symbol('(loop_var)')->clone,
    ),
}

sub check_lambda {
    my $self = shift;
    my ($var) = @_;

    return $self->make_ternary(
        $self->is_code_ref($var->clone),
        $self->run_code($var->clone),
        $var,
    );
}

sub is_array_ref {
    my $self = shift;
    my ($var) = @_;

    return $self->parser->symbol('(is_array_ref)')->clone(
        id    => 'builtin_is_array_ref',
        arity => 'unary',
        first => $var,
    );
}

sub is_hash_ref {
    my $self = shift;
    my ($var) = @_;

    return $self->parser->symbol('(is_hash_ref)')->clone(
        id    => 'builtin_is_hash_ref',
        arity => 'unary',
        first => $var,
    );
}

sub is_code_ref {
    my $self = shift;
    my ($var) = @_;

    return $self->parser->symbol('(is_code_ref)')->clone(
        id    => 'is_code_ref',
        arity => 'unary',
        first => $var,
    );
}

sub make_array {
    my $self = shift;
    my (@contents) = @_;

    return $self->parser->symbol('[')->clone(
        arity => 'composer',
        first => \@contents,
    );
}

sub make_hash {
    my $self = shift;
    my (@contents) = @_;

    return $self->parser->symbol('{')->clone(
        arity => 'composer',
        first => \@contents,
    );
}

sub is_falsy {
    my $self = shift;
    my ($node) = @_;

    return $self->not(
        $self->make_ternary(
            $self->is_array_ref($node->clone),
            $self->array_length($node->clone),
            $node
        )
    );
}

sub not {
    my $self = shift;
    my ($node) = @_;

    return $self->parser->symbol('!')->clone(
        arity => 'unary',
        first => $node,
    );
}

sub array_length {
    my $self = shift;
    my ($node) = @_;

    return $self->parser->symbol('(array_length)')->clone(
        arity => 'array_length',
        first => $node,
    );
}

sub run_code {
    my $self = shift;
    my ($code, $raw_text, $open_tag, $close_tag) = @_;

    return $self->parser->symbol('(run_code)')->clone(
        arity  => 'run_code',
        first  => $code,
        (@_ > 1
            ? (second => [ $raw_text ], third => [ $open_tag, $close_tag ])
            : (second => [])),
    );
}

sub new_vars {
    my $self = shift;
    my ($value, $i) = @_;

    return $value->clone(
        arity  => 'new_vars',
        first  => $self->vars,
        second => $value,
        third  => $i,
    );
}

sub save_lvar {
    my $self = shift;
    my ($id, $value) = @_;

    return $value->clone(
        arity => 'save_lvar',
        id    => $id,
        first => $value,
    );
}

sub merge_hash {
    my $self = shift;
    my (@hashes) = @_;

    my $merged = shift @hashes;
    for my $hash (@hashes) {
        $merged = $self->merge_single_hash($merged, $hash);
    }

    return $merged;
}

sub merge_single_hash {
    my $self = shift;
    my ($left, $right) = @_;

    return $left->clone(
        arity  => 'merge_hash',
        first  => $left,
        second => $right,
    );
}

sub literal { shift->parser->literal(@_) }

__PACKAGE__->meta->make_immutable;
no Mouse;

=for Pod::Coverage
  define_helper
  find_file
  is_unary
  join
  literalize
  call
  make_ternary
  vars
  iterator_index
  check_lambda
  is_array_ref
  is_hash_ref
  is_code_ref
  make_array
  make_hash
  is_falsy
  not
  array_length
  run_code
  new_vars
  save_lvar
  merge_hash
  merge_single_hash
  literal

=cut

1;
