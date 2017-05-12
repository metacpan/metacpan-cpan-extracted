package Text::Clevery::Parser;
use Any::Moose;
extends 'Text::Xslate::Parser';

use Text::Xslate::Util qw(p any_in);

my $SIMPLE_IDENT = qr/(?: [a-zA-Z_][a-zA-Z0-9_]* )/xms;

sub _build_identity_pattern {
    return qr{ (?: [/\$]? $SIMPLE_IDENT ) }xmso;
}

sub _build_line_start { undef  }

# preprocess code sections
around trim_code => sub {
    my($super, $parser, $code) = @_;

    # comment {* ... *}
    if($code =~ /\A \* .* \* \z/xms) {
        return '';
    }

    # config variable
    $code =~ s{ \# \s* (\S+) \s* \# }
              { '$clevery.config.' . $1 }xmsgeo;

    return $parser->$super($code);
};

around split => sub {
    my($super, $parser, @args) = @_;


    my $tokens_ref = $parser->$super(@args);
    for(my $i = 0; $i < @{$tokens_ref}; $i++) {
        my $t = $tokens_ref->[$i];
        # process {literal} ... {/literal}
        if($t->[0] eq 'code' && $t->[1] =~ m{\A \s* literal \s* \z}xms) {
            my $text = '';

            for(my $j = $i + 1; $j < @{$tokens_ref}; $j++) {
                my $u = $tokens_ref->[$j];
                if($u->[0] eq 'code' && $u->[1] =~ m{\A \s* /literal \s* \z}xms) {
                    splice @{$tokens_ref}, $i+1, $j - $i;
                    last;
                }
                elsif( $u->[0] eq 'code' ) {
                    $text .= $parser->tag_start . $u->[1];

                    my $n = $tokens_ref->[$j+1];
                    if($n && $n->[0] eq 'postchomp') {
                        $text .= $n->[1];
                        $j++;
                    }
                    $text .= $parser->tag_end;
                }
                else {
                    $text .= $u->[1];
                }
            }
            $t->[0] = 'text';
            $t->[1] = $text;
        }
    }
    return $tokens_ref;
};

sub init_symbols {
    my($parser) = @_;

    $parser->init_basic_operators();

    # special symbols
    $parser->symbol('`')->set_nud(\&nud_backquote);
    $parser->symbol('(name)')->set_std(\&std_name);

    # operators
    $parser->symbol('|') ->set_led(\&led_pipe); # reset
    $parser->symbol('.') ->set_led(\&led_dot);  # reset
    $parser->make_alias('.' => '->');

    # special variables
    $parser->symbol('$clevery') ->set_nud(\&nud_clevery_context);
    $parser->symbol('$smarty')->set_nud(\&nud_clevery_context);

    $parser->define_literal(ldelim => $parser->tag_start);
    $parser->define_literal(rdelim => $parser->tag_end);

    # statement tokens
    $parser->symbol('if')    ->set_std(\&std_if);
    $parser->symbol('elseif')->is_block_end(1);
    $parser->symbol('else')  ->is_block_end(1);
    $parser->symbol('/if')   ->is_block_end(1);

    $parser->symbol('foreach')    ->set_std(\&std_foreach);
    $parser->symbol('foreachelse')->is_block_end(1);
    $parser->symbol('/foreach')   ->is_block_end(1);

    $parser->symbol('include')->set_std(\&std_include);

    return;
}

sub nud_backquote { # the same as parens
    my($parser, $symbol) = @_;
    my $expr = $parser->expression(0);
    $parser->advance('`');
    return $expr;
}

sub nud_clevery_context {
    my($parser, $symbol) = @_;
    return $parser->call('@clevery_context');
}

around nud_literal => sub {
    my($super, $parser, $symbol) = @_;

    my $value = $symbol->value;
    if(defined($value) and !Scalar::Util::looks_like_number($value)) {
        # XXX: string literals in Clevery are "raw" string
        return $parser->call('mark_raw', $parser->$super($symbol));
    }

    return $parser->$super($symbol);
};

around led_dot => sub {
    my($super, $parser, $symbol, $left) = @_;

    # special case: foo.$field
    if($parser->token->id =~ /\A \$/xms) {
        return $symbol->clone(
            arity  => "field",
            first  => $left,
            second => $parser->expression( $symbol->lbp ),
        );
    }

    return $parser->$super($symbol, $left);
};

# variable modifiers
# expr | modifier : param1 : param2 ...
around led_pipe => sub {
    my($super, $parser, $symbol, $left) = @_;

    my $bar = $parser->$super($symbol, $left);

    my @args;
    while($parser->token->id eq ':') {
        $parser->advance();
        my $modifier = $parser->expression(0);
        push @args, $modifier;
    }
    push @{$bar->second}, @args;
    return $bar;
};

sub attr_list {
    my($parser) = @_;
    my @args;
    while(1) {
        my $key = $parser->token;
        if(!($key->arity eq "name"
                and $parser->next_token_is('='))) {
            last;
        }
        $parser->advance();
        $parser->advance("=");

        my $value;
        my $t = $parser->token;
        if($t->arity eq "name" && !$t->is_defined) {
            $value = $t->clone(arity => 'literal');
            $parser->advance();
        }
        else {
            $value = $parser->expression(0);
        }

        push @args, $key->clone(arity => 'literal') => $value;
    }

    return @args;
}

sub std_name { # simple names are assumed as commands
    my($parser, $symbol) = @_;

    my @args = $parser->attr_list();
    return $parser->print( $parser->call($symbol, @args) );
}

sub define_function {
    my($parser, @names) = @_;

    foreach my $name(@names) {
        my $s = $parser->symbol($name);
        $s->set_std(\&std_name);
    }
    return;
}


sub std_if {
    my($parser, $symbol) = @_;

    my $if = $symbol->clone(arity => 'if');

    $if->first( $parser->expression(0) );
    $if->second( $parser->statements() );

    my $t = $parser->token;

    my $top_if = $if;

    while($t->id eq 'elseif') {
        $parser->reserve($t);
        $parser->advance();

        my $elsif = $t->clone(arity => "if");
        $elsif->first(  $parser->expression(0) );
        $elsif->second( $parser->statements() );
        $if->third([$elsif]);
        $if = $elsif;
        $t  = $parser->token;
    }

    if($t->id eq 'else') {
        $parser->reserve($t);
        $parser->advance();

        $if->third( $parser->statements() );
    }

    $parser->advance('/if');

    return $top_if;
}

sub std_foreach {
    my($parser, $symbol) = @_;

    my $for = $symbol->clone( arity => 'for' );

    my %args = $parser->attr_list();

    my $from = $args{from} or $parser->_error("You must specify 'from' attribute for {foreach}");
    my $item = $args{item} or $parser->_error("You must specify 'item' attribute for {foreach}");
    my $key  = $args{key};
    my $name = $args{name};

    $item->id( '$' . $item->id );
    $item->arity('variable');

    $for->first($from);
    $for->second([$item]);

    $parser->new_scope();
    my $iterator = $parser->define_iterator($item);
    my $body = $parser->statements();
    $parser->pop_scope();

    # set_foreach_property(name, $~iter.index, $~iter.body)
    if($name) {
        unshift @{$body}, $parser->call(
            '@clevery_set_foreach_property',
            $name,
            $iterator,
            $parser->iterator_body($iterator),
        );
    }
    $for->third($body);

    if($parser->token->id eq 'foreachelse') {
        $parser->advance();

        # if array_is_not_empty(my $array = expr) {
        #    foreach $array -> ...
        # }
        # else {
        #    foreachelse ...
        # }

        my $else = $parser->statements();

        my $tmpname = $parser->symbol('($foreach)')->clone(arity => 'name');
        my $tmpinit = $symbol->clone(
            arity        => 'constant',
            first        => $tmpname,
            second       => $from,
        );
        $for->first($tmpname);

        my $array_is_not_empty = $parser->call(
            '@clevery_array_is_not_empty', $tmpinit);

        my $if = $symbol->clone(
            arity  => 'if',
            first  => $array_is_not_empty,
            second => [$for],
            third  => $else,
       );

       $for = $if;
    }

    $parser->advance('/foreach');

    if(defined $key) {
        $for = $parser->_not_implemented($symbol,
            "'key' attribute for {$symbol}");
    }

    return $for;
}

sub std_include {
    my($parser, $symbol) = @_;

    my @args = $parser->attr_list();

    my $file;
    for(my $i = 0; $i < @args; $i += 2) {
        my $key = $args[$i]->id;

        if($key eq 'assign') {
            return $parser->_not_implemented($symbol, "'assign' attribute for {$symbol}");
        }
        elsif($key eq 'file') {
            $file = $args[$i+1];
            splice @args, $i, 2; # delete
        }
    }

    return $symbol->clone(
        arity  => 'include',
        first  => $file,
        second => \@args,
    );
}

sub _not_implemented {
    my($self, $proto, $name) = @_;
    return $self->call('@clevery_not_implemented',
        $proto->clone(arity => 'literal', value => $name));
}

no Any::Moose;
1;
__END__

=head1 NAME

Text::Clevery::Parser - A Smarty compatible syntax parser

=head1 SEE ALSO

L<Text::Clevery>

=cut
