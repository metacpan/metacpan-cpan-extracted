package VIC::Receiver;
use strict;
use warnings;
use bigint;
use POSIX ();
use List::Util qw(max);
use List::MoreUtils qw(any firstidx indexes);

our $VERSION = '0.32';
$VERSION = eval $VERSION;

use Pegex::Base;
extends 'Pegex::Tree';

use VIC::PIC::Any;

has pic_override => undef;
has pic => undef;
has simulator => undef;
has ast => {
    block_stack => [],
    block_mapping => {},
    block_count => 0,
    funcs => {},
    variables => {},
    tmp_variables => {},
    conditionals => 0,
    tmp_stack_size => 0,
    strings => 0,
    tables => [],
    asserts => 0,
};
has intermediate_inline => undef;
has global_collections => {};

sub stack { reverse @{shift->parser->stack}; }

sub supported_chips { return VIC::PIC::Any::supported_chips(); }

sub supported_simulators { return VIC::PIC::Any::supported_simulators(); }

sub is_chip_supported { return VIC::PIC::Any::is_chip_supported(@_); }

sub is_simulator_supported { return VIC::PIC::Any::is_simulator_supported(@_); }

sub list_chip_features { return VIC::PIC::Any::list_chip_features(@_); }

sub print_pinout { return VIC::PIC::Any::print_pinout(@_); }

sub current_chip { return $_[0]->pic->type; }

sub current_simulator { return $_[0]->simulator->type; }

sub got_mcu_select {
    my ($self, $type) = @_;
    # override the PIC in code if defined
    $type = $self->pic_override if defined $self->pic_override;
    $type = lc $type;
    # assume supported type else return
    $self->pic(VIC::PIC::Any->new($type));
    unless (defined $self->pic and
        defined $self->pic->type) {
        $self->parser->throw_error("$type is not a supported chip");
    }
    $self->ast->{include} = $self->pic->include;
    # set the defaults in case the headers are not provided by the user
    $self->ast->{org} = $self->pic->org;
    $self->ast->{chip_config} = $self->pic->get_chip_config;
    $self->ast->{code_config} = $self->pic->code_config;
    # create the default simulator
    $self->simulator(VIC::PIC::Any->new_simulator(pic => $self->pic));
    return;
}

sub got_pragmas {
    my ($self, $list) = @_;
    $self->flatten($list);
    $self->pic->update_code_config(@$list);
    # get the updated config
    $self->ast->{chip_config} = $self->pic->get_chip_config;
    $self->ast->{code_config} = $self->pic->code_config;
    my ($sim, $stype) = @$list if scalar @$list;
    if ($sim eq 'simulator' and $stype !~ /disable/i) {
        $self->simulator(VIC::PIC::Any->new_simulator(
                    type => $stype, pic => $self->pic));
        if ($self->simulator) {
            unless ($self->simulator->type eq $stype) {
                warn "$stype is not a supported chip. Disabling simulator.";
                $self->simulator->disable(1);
            }
        } else {
            die "$stype is not a supported simulator.";
        }
    } elsif ($sim eq 'simulator' and $stype =~ /disable/i) {
        $self->simulator->disable(1) if $self->simulator;
    }
    return;
}

sub handle_named_block {
    my ($self, $name, $anon_block, $parent) = @_;
    my $id = $1 if $anon_block =~ /_anonblock(\d+)/;
    $id = $self->ast->{block_count} unless defined $id;
    my ($expected_label, $expected_param) = ('', '');
    if ($name eq 'Main') {
        $expected_label = "_start";
    } elsif ($name =~ /^Loop/) {
        $expected_label = "_loop_${id}";
    } elsif ($name =~ /^Action/) {
        $expected_label = "_action_${id}";
        $expected_param = "action${id}_param";
    } elsif ($name =~ /^True/) {
        $expected_label = "_true_${id}";
    } elsif ($name =~ /^False/) {
        $expected_label = "_false_${id}";
    } elsif ($name =~ /^ISR/) {
        $expected_label = "_isr_${id}";
        $expected_param = "isr${id}_param";
    } elsif ($name eq 'Simulator') {
        $expected_label = '_vic_simulator';
    } else {
        $expected_label = lc "_$name$id";
    }
    $name .= $id if $name =~ /^(?:Loop|Action|True|False|ISR)/;
    $self->ast->{block_mapping}->{$name} = {
        label => $expected_label,
        block => $anon_block,
        params => [],
        param_prefix => $expected_param,
    };
    $self->ast->{block_mapping}->{$anon_block} = {
        label => $expected_label,
        block => $name,
        params => [],
        param_prefix => $expected_param,
    };
    # make sure the anon-block and named-block refer to the same block
    $self->ast->{$name} = $self->ast->{$anon_block};

    my $stack = $self->ast->{$name} || $self->ast->{$anon_block};
    if (defined $stack and ref $stack eq 'ARRAY') {
        my $block_label = $stack->[0];
        ## this expression is dependent on got_start_block()
        my ($tag, $label, @others) = split /::/, $block_label;
        $label = $expected_label if $label ne $expected_label;
        $block_label = "BLOCK::${label}::${name}" if $label;
        # change the LABEL:: value in the stack for code-generation ease
        # we want to use the expected label and not the anon one unless it is an
        # anon-block
        $stack->[0] = join("::", $tag, $label, @others);
        my $elabel = "_end$label"; # end label
        my $slabel = $label; # start label
        if (defined $parent) {
            unless ($parent =~ /BLOCK::/) {
                $block_label .= "::$parent";
                if (exists $self->ast->{$parent} and
                    ref $self->ast->{$parent} eq 'ARRAY' and
                    $parent ne $anon_block) {
                    my ($ptag, $plabel) = split /::/, $self->ast->{$parent}->[0];
                    $block_label .= "::$plabel" if $plabel;
                }
            }
            my $ccount = $self->ast->{conditionals};
            if ($block_label =~ /True|False/i) {
                $elabel = "_end_conditional_$ccount";
                $slabel = "_start_conditional_$ccount";
            }
            $block_label .= "::$elabel";
            $block_label .= "::$expected_param" if length $expected_param;
            push @{$self->ast->{$parent}}, $block_label;
        }
        # save this for referencing when we need to know what the parent of
        # this block is in case we need to jump out of the block
        $self->ast->{block_mapping}->{$name}->{parent} = $parent;
        $self->ast->{block_mapping}->{$anon_block}->{parent} = $parent;
        $self->ast->{block_mapping}->{$name}->{end_label} = $elabel;
        $self->ast->{block_mapping}->{$anon_block}->{end_label} = $elabel;
        $self->ast->{block_mapping}->{$name}->{start_label} = $slabel;
        $self->ast->{block_mapping}->{$anon_block}->{start_label} = $slabel;
        $self->ast->{block_mapping}->{$anon_block}->{loop} = '1' if $block_label =~ /Loop/i;
        return $block_label;
    }
}

sub got_named_block {
    my ($self, $list) = @_;
    $self->flatten($list) if ref $list eq 'ARRAY';
    my ($name, $anon_block, $parent_block) = @$list;
    return $self->handle_named_block(@$list);
}

sub got_anonymous_block {
    my $self = shift;
    my $list = shift;
    my ($anon_block, $block_stack, $parent) = @$list;
    # returns anon_block and parent_block
    return [$anon_block, $parent];
}

sub got_start_block {
    my ($self, $list) = @_;
    my $id = $self->ast->{block_count};
    # we may not know the block name here
    my $block = lc "_anonblock$id";
    push @{$self->ast->{block_stack}}, $block;
    $self->ast->{$block} = [ "LABEL::$block" ];
    $self->ast->{block_count}++;
    return $block;
}

sub got_end_block {
    my ($self, $list) = @_;
    # we are not capturing anything here
    my $stack = $self->ast->{block_stack};
    my $block = pop @$stack;
    return $stack->[-1];
}

sub got_name {
    my ($self, $list) = @_;
    if (ref $list eq 'ARRAY') {
        $self->flatten($list);
        return shift(@$list);
    } else {
        return $list;
    }
}

sub update_intermediate {
    my $self = shift;
    my $block = $self->ast->{block_stack}->[-1];
    push @{$self->ast->{$block}}, @_ if $block;
    return;
}

sub got_instruction {
    my ($self, $list) = @_;
    my $method = shift @$list;
    $self->flatten($list) if $list;
    my $tag = 'INS';
    # check if it is a simulator method
    if ($self->simulator and $self->simulator->can($method)) {
        # this is a simulator instruction
        $tag = 'SIM';
    } else {
        unless ($self->pic->can($method)) {
            my $err = "Unsupported instruction '$method' for chip " . uc $self->pic->type;
            return $self->parser->throw_error($err);
        }
    }
    my @args = ();
    while (scalar @$list) {
        my $a = shift @$list;
        if ($a =~ /BLOCK::(\w+)::(Action|ISR)\w+::.*::(_end_\w+)::(\w+)$/) {
            push @args, uc($2) . "::$1::END::$3::PARAM::$4";
        } else {
            push @args, $a;
        }
    }
    $self->update_intermediate("${tag}::${method}::" . join ("::", @args));
    return;
}

sub got_unary_rhs {
    my ($self, $list) = @_;
    $self->flatten($list);
    return [ reverse @$list ];
}

sub got_unary_expr {
    my ($self, $list) = @_;
    $self->flatten($list);
    my $op = shift @$list;
    my $varname = shift @$list;
    $self->update_intermediate("UNARY::${op}::${varname}");
    return;
}

sub got_assign_expr {
    my ($self, $list) = @_;
    $self->flatten($list);
    my $varname = shift @$list;
    my $op = shift @$list;
    my $rhsx = $self->got_expr_value($list);
    my $rhs = ref $rhsx eq 'ARRAY' ? join ("::", @$rhsx) : $rhsx;
    if ($rhs =~ /PARAM::(\w+)/) {
        ## ok now we push this as our statement and handle the rest during
        ## code generation
        ## this is of the format PARAM::op::block_name::variable
        my $block = $1;
        $self->update_intermediate("PARAM::${op}::${block}::${varname}");
    } else {
        $self->update_intermediate("SET::${op}::${varname}::${rhs}");
    }
    return;
}

sub got_array_element {
    my ($self, $list) = @_;
    my $var1 = shift @$list;
    my $rhsx = $self->got_expr_value($list);
    if (ref $rhsx eq 'ARRAY') {
        XXX $rhsx; # why would this even happen
    }
    my $tvref = $self->ast->{tmp_variables};
    my $tvar = sprintf "_vic_tmp_%02d", scalar(keys %$tvref);
    my $vref = $self->ast->{variables}->{$var1};
    my @ops = ('OP');
    if (exists $vref->{type} and $vref->{type} eq 'HASH') {
        push @ops, $vref->{label}, 'TBLIDX', $rhsx, $vref->{size};
    } elsif (exists $vref->{type} and $vref->{type} eq 'ARRAY') {
        push @ops, $vref->{label}, 'ARRIDX', $rhsx, $vref->{size};
    } elsif (exists $vref->{type} and $vref->{type} eq 'string') {
        push @ops, $vref->{label}, 'STRIDX', $rhsx, $vref->{size};
    } else {
        # this must be a byte
        return $self->parser->throw_error(
                    "Variable '$var1' is not an array, table or string");
    }
    $tvref->{$tvar} = join("::", @ops);
    # create a new variable here
    my $varname = sprintf "vic_el_%02d", scalar(keys %$tvref);
    $varname = $self->got_variable([$varname]);
    if ($varname) {
        $self->update_intermediate("SET::ASSIGN::${varname}::${tvar}");
        return $varname;
    }
    return $self->parser->throw_error(
        "Unable to create intermediary variable '$varname'") unless $varname;
}

sub got_parameter {
    my $self = shift;
    ## ok the target variable needs a parameter here
    ## this works only in block scope so we want to check which block we are in
    my $block = $self->ast->{block_stack}->[-1];
    return "PARAM::$block";
}

sub got_declaration {
    my ($self, $list) = @_;
    my $lhs = shift @$list;
    my $rhs;
    if (scalar @$list == 1) {
        $rhs = shift @$list;
    } else {
        $rhs = $list;
    }
    # TODO: generate intermediate code here
    if (ref $rhs eq 'HASH' or ref $rhs eq 'ARRAY') {
        if (not exists $self->ast->{variables}->{$lhs}) {
            return $self->parser->throw_error("Variable '$lhs' doesn't exist");
        }
        if (exists $rhs->{TABLE} or ref $rhs eq 'ARRAY') {
            my $label = lc "_table_$lhs" if ref $rhs eq 'HASH' and exists $rhs->{TABLE};
            my $szpref = "VIC_TBLSZ_" if ref $rhs eq 'HASH' and exists $rhs->{TABLE};
            $szpref = "VIC_ARRSZ_" if ref $rhs eq 'ARRAY';
            $self->ast->{variables}->{$lhs}->{type} = ref $rhs;
            $self->ast->{variables}->{$lhs}->{data} = $rhs;
            $self->ast->{variables}->{$lhs}->{label} = $label || $lhs;
            if ($szpref) {
                $self->ast->{variables}->{$lhs}->{size} = $szpref .
                    $self->ast->{variables}->{$lhs}->{name};
            }
        } elsif (exists $rhs->{string}) {
            # handle variable that are strings here
            $self->ast->{variables}->{$lhs}->{data} = $rhs;
            $self->ast->{variables}->{$lhs}->{type} = 'string';
            $self->ast->{variables}->{$lhs}->{size} = "VIC_STRSZ_" .
                    $self->ast->{variables}->{$lhs}->{name};
            $self->update_intermediate("SET::ASSIGN::${lhs}::${rhs}");
        } else {
            return $self->parser->throw_error("We should not be here");
        }
    } else {
        # var = number | string etc.
        if ($rhs =~ /^-?\d+$/) {
            # we just use the got_assign_expr. this should never be called in
            # reality but is here in case the grammar rules change
            $self->update_intermediate("SET::ASSIGN::${lhs}::${rhs}");
        } else {
            #VIKAS: check this!
            # handle strings here
            $self->ast->{variables}->{$lhs}->{type} = 'string';
            $self->ast->{variables}->{$lhs}->{data} = $rhs;
            $self->ast->{variables}->{$lhs}->{label} = $lhs;
            $self->ast->{variables}->{$lhs}->{size} = "VIC_STRSZ_" .
                    $self->ast->{variables}->{$lhs}->{name};
        }
    }
    return;
}

sub got_conditional_statement {
    my ($self, $list) = @_;
    my ($type, $subject, $predicate) = @$list;
    return unless scalar @$predicate;
    my $is_loop = ($type eq 'while') ? 1 : 0;
    my ($current, $parent) = $self->stack;
    my $subcond = 0;
    $subcond = 1 if $parent =~ /^conditional/;
    if (ref $predicate ne 'ARRAY') {
        $predicate = [ $predicate ];
    }
    my @condblocks = ();
    if (scalar @$predicate < 3) {
        my $tb = $predicate->[0] || undef;
        my $fb = $predicate->[1] || undef;
        $self->flatten($tb) if $tb;
        $self->flatten($fb) if $fb;
        my $true_block = $self->handle_named_block('True', @$tb) if $tb and scalar @$tb;
        push @condblocks, $true_block if $true_block;
        my $false_block = $self->handle_named_block('False', @$fb)  if $fb and scalar @$fb;
        push @condblocks, $false_block if $false_block;
    } else {
        return $self->parser->throw_error("Multiple predicate conditionals not implemented");
    }
    my $inter;
    if (scalar @condblocks < 3) {
        my ($false_label, $true_label, $end_label);
        my ($false_name, $true_name);
        foreach my $p (@condblocks) {
            ($false_label, $false_name) = ($1, $2) if $p =~ /BLOCK::(\w+)::(False\d+)::/;
            ($true_label, $true_name) = ($1, $2) if $p =~ /BLOCK::(\w+)::(True\d+)::/;
            $end_label = $1 if $p =~ /BLOCK::.*::(_end_conditional\w+)$/;
        }
        $false_label = $end_label unless defined $false_label;
        $true_label = $end_label unless defined $true_label;
        my $subj = $subject;
        $subj = shift @$subject if ref $subject eq 'ARRAY';
        $inter = join("::",
                COND => $self->ast->{conditionals},
                SUBJ => $subj,
                FALSE => $false_label,
                TRUE => $true_label,
                END => $end_label,
                LOOP => $is_loop,
                SUBCOND => $subcond);
        my $mapping = $self->ast->{block_mapping};
        if ($true_name and exists $mapping->{$true_name}) {
            $mapping->{$true_name}->{loop} = "$is_loop";
            my $ab = $mapping->{$true_name}->{block};
            $mapping->{$ab}->{loop} = "$is_loop";
        }
        if ($false_name and exists $mapping->{$false_name}) {
            $mapping->{$false_name}->{loop} = "$is_loop";
            my $ab = $mapping->{$false_name}->{block};
            $mapping->{$ab}->{loop} = "$is_loop";
        }
    } else {
        return $self->parser->throw_error("Multiple predicate conditionals not implemented");
    }
    $self->update_intermediate($inter);
    $self->ast->{conditionals}++ unless $subcond;
    return;
}

##WARNING: do not change this function without looking at its effect on
#got_conditional_statement() above which calls this function explicitly
# this function is identical to got_expr_value() and hence redundant
# we may need to just use the same one although precedence will be different
# so maybe not
sub got_conditional_subject {
    my ($self, $list) = @_;
    if (ref $list eq 'ARRAY') {
        $self->flatten($list);
        if (scalar @$list == 1) {
            my $var1 = shift @$list;
            return $var1 if $var1 =~ /^\d+$/;
            my $vref = $self->ast->{tmp_variables};
            my $tvar = sprintf "_vic_tmp_%02d", scalar(keys %$vref);
            $vref->{$tvar} = "OP::${var1}::EQ::1";
            return $tvar;
        } elsif (scalar @$list == 2) {
            my ($op, $var) = @$list;
            my $vref = $self->ast->{tmp_variables};
            my $tvar = sprintf "_vic_tmp_%02d", scalar(keys %$vref);
            $vref->{$tvar} = "OP::${op}::${var}";
            return $tvar;
        } elsif (scalar @$list == 3) {
            my ($var1, $op, $var2) = @$list;
            my $vref = $self->ast->{tmp_variables};
            my $tvar = sprintf "_vic_tmp_%02d", scalar(keys %$vref);
            $vref->{$tvar} = "OP::${var1}::${op}::${var2}";
            return $tvar;
        } else {
            # handle precedence with left-to-right association
            my @arr = @$list;
            my $idx = firstidx { $_ =~ /^GE|GT|LE|LT|EQ|NE$/ } @arr;
            while ($idx >= 0) {
                my $res = $self->got_conditional_subject([$arr[$idx - 1], $arr[$idx], $arr[$idx + 1]]);
                $arr[$idx - 1] = $res;
                splice @arr, $idx, 2; # remove the extra elements
                $idx = firstidx { $_ =~ /^GE|GT|LE|LT|EQ|NE$/ } @arr;
            }
            $idx = firstidx { $_ =~ /^AND|OR$/ } @arr;
            while ($idx >= 0) {
                my $res = $self->got_conditional_subject([$arr[$idx - 1], $arr[$idx], $arr[$idx + 1]]);
                $arr[$idx - 1] = $res;
                splice @arr, $idx, 2; # remove the extra elements
                $idx = firstidx { $_ =~ /^AND|OR$/ } @arr;
            }
#            YYY $self->ast->{tmp_variables};
            return $self->got_conditional_subject([@arr]);
        }
    } else {
        return $list;
    }
}

##WARNING: do not change this function without looking at its effect on
#got_assign_expr() above which calls this function explicitly
sub got_expr_value {
    my ($self, $list) = @_;
    if (ref $list eq 'ARRAY') {
        $self->flatten($list);
        if (scalar @$list == 1) {
            my $val = shift @$list;
            if ($val =~ /MOP::/) {
                my $vref = $self->ast->{tmp_variables};
                my $tvar = sprintf "_vic_tmp_%02d", scalar(keys %$vref);
                $vref->{$tvar} = $val;
                return $tvar;
            } else {
                return $val;
            }
        } elsif (scalar @$list == 2) {
            my ($op, $var) = @$list;
            my $vref = $self->ast->{tmp_variables};
            my $tvar = sprintf "_vic_tmp_%02d", scalar(keys %$vref);
            $vref->{$tvar} = "OP::${op}::${var}";
            return $tvar;
        } elsif (scalar @$list == 3) {
            my ($var1, $op, $var2) = @$list;
            my $vref = $self->ast->{tmp_variables};
            my $tvar = sprintf "_vic_tmp_%02d", scalar(keys %$vref);
            $vref->{$tvar} = "OP::${var1}::${op}::${var2}";
            return $tvar;
        } elsif (scalar @$list > 3) {
            # handle precedence with left-to-right association
            my @arr = @$list;
            my $idx = firstidx { $_ =~ /^MUL|DIV|MOD$/ } @arr;
            while ($idx >= 0) {
                my $res = $self->got_expr_value([$arr[$idx - 1], $arr[$idx], $arr[$idx + 1]]);
                $arr[$idx - 1] = $res;
                splice @arr, $idx, 2; # remove the extra elements
                $idx = firstidx { $_ =~ /^MUL|DIV|MOD$/ } @arr;
            }
            $idx = firstidx { $_ =~ /^ADD|SUB$/ } @arr;
            while ($idx >= 0) {
                my $res = $self->got_expr_value([$arr[$idx - 1], $arr[$idx], $arr[$idx + 1]]);
                $arr[$idx - 1] = $res;
                splice @arr, $idx, 2; # remove the extra elements
                $idx = firstidx { $_ =~ /^ADD|SUB$/ } @arr;
            }
            $idx = firstidx { $_ =~ /^SHL|SHR$/ } @arr;
            while ($idx >= 0) {
                my $res = $self->got_expr_value([$arr[$idx - 1], $arr[$idx], $arr[$idx + 1]]);
                $arr[$idx - 1] = $res;
                splice @arr, $idx, 2; # remove the extra elements
                $idx = firstidx { $_ =~ /^SHL|SHR$/ } @arr;
            }
            $idx = firstidx { $_ =~ /^BAND|BXOR|BOR$/ } @arr;
            while ($idx >= 0) {
                my $res = $self->got_expr_value([$arr[$idx - 1], $arr[$idx], $arr[$idx + 1]]);
                $arr[$idx - 1] = $res;
                splice @arr, $idx, 2; # remove the extra elements
                $idx = firstidx { $_ =~ /^BAND|BXOR|BOR$/ } @arr;
            }
#            YYY $self->ast->{tmp_variables};
            return $self->got_expr_value([@arr]);
        } else {
            return $list;
        }
    } else {
        return $list;
    }
}

sub got_math_operator {
    my ($self, $op) = @_;
    return 'ADD' if $op eq '+';
    return 'SUB' if $op eq '-';
    return 'MUL' if $op eq '*';
    return 'DIV' if $op eq '/';
    return 'MOD' if $op eq '%';
    return $self->parser->throw_error("Math operator '$op' is not supported");
}

sub got_shift_operator {
    my ($self, $op) = @_;
    return 'SHL' if $op eq '<<';
    return 'SHR' if $op eq '>>';
    return $self->parser->throw_error("Shift operator '$op' is not supported");
}

sub got_bit_operator {
    my ($self, $op) = @_;
    return 'BXOR' if $op eq '^';
    return 'BOR'  if $op eq '|';
    return 'BAND' if $op eq '&';
    return $self->parser->throw_error("Bitwise operator '$op' is not supported");
}

sub got_logic_operator {
    my ($self, $op) = @_;
    return 'AND' if $op eq '&&';
    return 'OR' if $op eq '||';
    return $self->parser->throw_error("Logic operator '$op' is not supported");
}

sub got_compare_operator {
    my ($self, $op) = @_;
    return 'LE' if $op eq '<=';
    return 'LT' if $op eq '<';
    return 'GE' if $op eq '>=';
    return 'GT' if $op eq '>';
    return 'EQ' if $op eq '==';
    return 'NE' if $op eq '!=';
    return $self->parser->throw_error("Compare operator '$op' is not supported");
}

sub got_complement_operator {
    my ($self, $op) = @_;
    return 'NOT'  if $op eq '!';
    return 'COMP' if $op eq '~';
    return $self->parser->throw_error("Complement operator '$op' is not supported");
}

sub got_assign_operator {
    my ($self, $op) = @_;
    if (ref $op eq 'ARRAY') {
        $self->flatten($op);
        $op = shift @$op;
    }
    return 'ASSIGN' if $op eq '=';
    return 'ADD_ASSIGN'  if $op eq '+=';
    return 'SUB_ASSIGN'  if $op eq '-=';
    return 'MUL_ASSIGN'  if $op eq '*=';
    return 'DIV_ASSIGN'  if $op eq '/=';
    return 'MOD_ASSIGN'  if $op eq '%=';
    return 'BXOR_ASSIGN' if $op eq '^=';
    return 'BOR_ASSIGN'  if $op eq '|=';
    return 'BAND_ASSIGN' if $op eq '&=';
    return 'SHL_ASSIGN' if $op eq '<<=';
    return 'SHR_ASSIGN' if $op eq '>>=';
    return 'CAT_ASSIGN' if $op eq '.=';
    return $self->parser->throw_error("Assignment operator '$op' is not supported");
}

sub got_unary_operator {
    my ($self, $op) = @_;
    return 'INC' if $op eq '++';
    return 'DEC' if $op eq '--';
    return $self->parser->throw_error("Increment/Decrement operator '$op' is not supported");
}

sub got_array {
    my ($self, $arr) = @_;
    $self->flatten($arr) if ref $arr eq 'ARRAY';
    $self->global_collections->{"$arr"} = $arr;
    return $arr;
}

sub got_modifier_constant {
    my ($self, $list) = @_;
    # we don't flatten since $value can be an array as well
    my ($modifier, $value) = @$list;
    $modifier = uc $modifier;
    ## first check if the modifier is an operator
    my $method = $self->pic->validate_modifier_operator($modifier);
    $self->flatten($value) if ($method and ref $value eq 'ARRAY');
    return $self->got_expr_value(["MOP::${modifier}::${value}"]) if $method;
    ## if not then check if it is a type modifier for use by the simulator
    if ($self->simulator and $self->simulator->supports_modifier($modifier)) {
        my $hh = { $modifier => $value };
        $self->global_collections->{"$hh"} = $hh;
        return $hh;
    }
    ## ok check if the modifier is a type modifier for code generation
    ## this is reallly a bad hack
    if ($modifier eq 'TABLE') {
        return { TABLE => $value } if ref $value eq 'ARRAY';
        return { TABLE => [$value] };
    } elsif ($modifier eq 'ARRAY') {
        return $value if ref $value eq 'ARRAY';
        return [$value];
    } elsif ($modifier eq 'STRING') {
        return { STRING => $value } if ref $value eq 'ARRAY';
        return { STRING => [$value] };
    }
    $self->parser->throw_error("Modifying operator '$modifier' not supported") unless $method;
}

sub got_modifier_variable {
    my ($self, $list) = @_;
    my ($modifier, $varname);
    $self->flatten($list) if ref $list eq 'ARRAY';
    $modifier = shift @$list;
    $varname = shift @$list;
    $modifier = uc $modifier;
    my $method = $self->pic->validate_modifier_operator($modifier);
    $self->parser->throw_error("Modifying operator '$modifier' not supported") unless $method;
    return $self->got_expr_value(["MOP::${modifier}::${varname}"]);
}

sub got_validated_variable {
    my ($self, $list) = @_;
    my $varname;
    if (ref $list eq 'ARRAY') {
        $self->flatten($list);
        $varname = shift @$list;
        my $suffix = shift @$list;
        $varname .= $suffix if defined $suffix;
    } else {
        $varname = $list;
    }
    return $varname if $self->pic->validate($varname);
    return $self->parser->throw_error("'$varname' is not a valid part of the " . uc $self->pic->type);
}

sub got_variable {
    my ($self, $list) = @_;
    $self->flatten($list) if ref $list eq 'ARRAY';
    my $varname = shift @$list;
    my ($current, $parent) = $self->stack;
    # if the variable is used from the pragma grammar rule
    # we do not want to store it yet and definitely not store the size yet
    # we could remove this if we set the size after the code generation or so
    # but that may lead to more complexity. this is much easier
    return $varname if $parent eq 'pragmas';
    $self->ast->{variables}->{$varname} = {
        name => uc $varname,
        scope => $self->ast->{block_stack}->[-1],
        size => POSIX::ceil($self->pic->address_bits($varname) / 8),
        type => 'byte',
        data => undef,
    } unless exists $self->ast->{variables}->{$varname};
    $self->ast->{variables}->{$varname}->{scope} = 'global' if $parent =~ /assert_/;
    return $varname;
}

sub got_boolean {
    my ($self, $list) = @_;
    my $b;
    if (ref $list eq 'ARRAY') {
        $self->flatten($list);
        $b = shift @$list;
    } else {
        $b = $list;
    }
    return 0 unless defined $b;
    return 1 if $b =~ /TRUE|true/i;
    return 1 if $b == 1;
    return 0 if $b =~ /FALSE|false/i;
    return 0; # default boolean is false
}

sub got_double_quoted_string {
    my $self = shift;
    my $str = pop;
    ## Ripped from Ingy's pegex-json-pm Pegex::JSON::Data
    ## Unicode support not implemented yet but available in Pegex::JSON::Data
    my %escapes = (
        '"' => '"',
        '/' => '/',
        "\\" => "\\",
        b => "\b",
        f => "\x12",
        n => "\n",
        r => "\r",
        t => "\t",
        0 => "\0",
    );
    $str =~ s/\\(["\/\\bfnrt0])/$escapes{$1}/ge;
    return $str;
}

sub got_string {
    my $self = shift;
    my $str = shift;
    ##TODO: handle empty strings as initializers
    # store only unique strings otherwise re-use them
    foreach (%{$self->global_collections}) {
        my $h = $self->global_collections->{$_};
        return $h if ($h->{string} eq $str);
    }
    my $is_empty = 1 if $str eq '';
    my $stref = {
        string => $str,
        block => $self->ast->{block_stack}->[-1],
        name => sprintf("_vic_str_%02d", $self->ast->{strings}),
        size => length($str) + 1, # trailing null byte
        empty => $is_empty, # required for variable allocation later
    };
    $self->global_collections->{"$stref"} = $stref;
    $self->ast->{strings}++;
    return $stref;
    #return '@' . $str;
}

sub got_number {
    my ($self, $list) = @_;
    # if it is a hexadecimal number we can just convert it to number using int()
    # since hex is returned here as a string
    return hex($list) if $list =~ /0x|0X/;
    my $val = int($list);
    return $val if $val >= 0;
    ##TODO: check the negative value
    my $bits = (2 ** $self->pic->address_bits) - 1;
    $val = sprintf "0x%02X", $val;
    return hex($val) & $bits;
}

# convert the number to appropriate units
sub got_number_units {
    my ($self, $list) = @_;
    $self->flatten($list);
    my $num = shift @$list;
    my $units = shift @$list;
    return $num unless defined $units;
    $num *= 1 if $units eq 'us';
    $num *= 1000 if $units eq 'ms';
    $num *= 1e6 if $units eq 's';
    $num *= 1 if $units eq 'Hz';
    $num *= 1000 if $units eq 'kHz';
    $num *= 1e6 if $units eq 'MHz';
    # ignore the '%' sign for now
    return $num;
}

sub got_real_number {
    my ($self, $list) = @_;
    $list .= '0' if $list =~ /\d+\.$/;
    $list = "0.$1" if $list =~ /^\.(\d+)$/;
    $list = "-0.$1" if $list =~ /^-\.(\d+)$/;
    return $list;
}

# remove the dumb stuff from the tree
sub got_comment { return; }

sub _update_funcs {
    my ($self, $funcs, $macros) = @_;
    if (ref $funcs eq 'HASH') {
        foreach (keys %$funcs) {
            $self->ast->{funcs}->{$_} = $funcs->{$_};
        }
    }
    if (ref $macros eq 'HASH') {
        return unless ref $macros eq 'HASH';
        foreach (keys %$macros) {
            $self->ast->{macros}->{$_} = $macros->{$_};
        }
    }
    1;
}

sub _update_tables {
    my ($self, $tables) = @_;
    if (ref $tables eq 'HASH') {
        $tables = [ $tables ];
    }
    unless (ref $tables eq 'ARRAY') {
        return $self->parser->throw_error(
        "Code generation error. PIC methods should return strings as a HASH or ARRAY");
    }
    foreach my $s (@$tables) {
        next unless defined $s->{bytes};
        next unless defined $s->{name};
        push @{$self->ast->{tables}}, $s;
    }
    1;
}

## assert handling is special for now
sub got_assert_comparison {
    my ($self, $list) = @_;
    return unless $self->simulator;
    $self->flatten($list) if ref $list eq 'ARRAY';
    if (scalar @$list < 3) {
        return $self->parser->throw_error("Error in assert statement");
    }
    return join("@@", @$list);
}

sub got_assert_statement {
    my ($self, $list) = @_;
    $self->flatten($list) if ref $list eq 'ARRAY';
    my ($method, $cond, $msg) = @$list;
    $msg = '' unless defined $msg;
    $self->ast->{asserts}++;
    $self->update_intermediate("SIM::${method}::${cond}::${msg}");
    return;
}

sub generate_simulator_instruction {
    my ($self, $line) = @_;
    my @ins = split /::/, $line;
    my $tag = shift @ins;
    my $method = shift @ins;
    my @code = ();
    push @code, "\t;; $line" if $self->intermediate_inline;
    foreach (@ins) {
        next unless /HASH|ARRAY/;
        next unless exists $self->global_collections->{$_};
        $_ = $self->global_collections->{$_};
    }
    return @code if $self->simulator->disable;
    my $code = $self->simulator->$method(@ins);
    return $self->parser->throw_error("Error in simulator intermediate code '$line'") unless $code;
    push @code, $code if $code;
    return @code;
}

sub generate_code_instruction {
    my ($self, $line) = @_;
    my @ins = split /::/, $line;
    my $tag = shift @ins;
    my $method = shift @ins;
    my @code = ();
    foreach (@ins) {
        if (exists $self->global_collections->{$_}) {
            $_ = $self->global_collections->{$_};
            next;
        }
        if (exists $self->ast->{variables}->{$_}) {
            my $vhref = $self->ast->{variables}->{$_};
            if ($vhref->{type} eq 'string') {
                # send the string variable information to the method
                # and hope that the method knows how to handle it
                # this is useful for I/O methods and operator methods
                # other methods should outright fail to use this and it should
                # make sense there.#TODO: make better error messages for that.
                $_ = $vhref;
            }
        }
    }
    my ($code, $funcs, $macros, $tables) = $self->pic->$method(@ins);
    return $self->parser->throw_error("Error in intermediate code '$line'") unless $code;
    push @code, "\t;; $line" if $self->intermediate_inline;
    push @code, $code if $code;
    $self->_update_funcs($funcs, $macros) if ($funcs or $macros);
    $self->_update_tables($tables) if $tables;
    return @code;
}

sub generate_code_unary_expr {
    my ($self, $line) = @_;
    my @code = ();
    my $ast = $self->ast;
    my ($tag, $op, $varname) = split /::/, $line;
    my $method = $self->pic->validate_operator($op);
    $self->parser->throw_error("Invalid operator '$op' in intermediate code") unless $self->pic->can($method);
    # check if temporary variable or not
    if (exists $ast->{variables}->{$varname}) {
        my $nvar = $ast->{variables}->{$varname}->{name} || $varname;
        my ($code, $funcs, $macros, $tables) = $self->pic->$method($nvar);
        return $self->parser->throw_error("Error in intermediate code '$line'") unless $code;
        push @code, "\t;; $line" if $self->intermediate_inline;
        push @code, $code if $code;
        $self->_update_funcs($funcs, $macros) if ($funcs or $macros);
        $self->_update_tables($tables) if $tables;
    } else {
        return $self->parser->throw_error("Error in intermediate code '$line'");
    }
    return @code;
}

sub generate_code_operations {
    my ($self, $line, %extra) = @_;
    my @code = ();
    my ($tag, @args) = split /::/, $line;
    my ($op, $var1, $var2);
    if (scalar @args == 2) {
        $op = shift @args;
        $var1 = shift @args;
    } elsif (scalar @args == 3) {
        $var1 = shift @args;
        $op = shift @args;
        $var2 = shift @args;
    } elsif (scalar @args == 4) {
        $var1 = shift @args;
        $op = shift @args;
        $var2 = shift @args;
        my $var3 = shift @args;
        $extra{SIZE} = $var3;
    } else {
        return $self->parser->throw_error("Error in intermediate code '$line'");
    }
    if (exists $extra{STACK}) {
        if (defined $var1) {
            $var1 = $extra{STACK}->{$var1} || $var1;
        }
        if (defined $var2) {
            $var2 = $extra{STACK}->{$var2} || $var2;
        }
    }
    my $method = $self->pic->validate_operator($op) if $tag eq 'OP';
    $method = $self->pic->validate_modifier_operator($op) if $tag eq 'MOP';
    $self->parser->throw_error("Invalid operator '$op' in intermediate code") unless
        ($method and $self->pic->can($method));
    push @code, "\t;; $line" if $self->intermediate_inline;
    my ($code, $funcs, $macros, $tables) = $self->pic->$method($var1, $var2, %extra);
    return $self->parser->throw_error("Error in intermediate code '$line'") unless $code;
    push @code, $code if $code;
    $self->_update_funcs($funcs, $macros) if ($funcs or $macros);
    $self->_update_tables($tables) if $tables;
    return @code;
}

sub find_tmpvar_dependencies {
    my ($self, $tvar) = @_;
    my $tcode = $self->ast->{tmp_variables}->{$tvar};
    my ($tag, @args) = split /::/, $tcode;
    return unless $tag eq 'OP';
    my @deps = ();
    my $sz = scalar @args;
    if ($sz == 2) {
        my ($op, $var) = @args;
        if (exists $self->ast->{tmp_variables}->{$var}) {
            push @deps, $var;
            my @rdeps = $self->find_tmpvar_dependencies($var);
            push @deps, @rdeps if @rdeps;
        }
    } elsif ($sz == 3 or $sz == 4) {
        my ($var1, $op, $var2) = @args;
        if (exists $self->ast->{tmp_variables}->{$var1}) {
            push @deps, $var1;
            my @rdeps = $self->find_tmpvar_dependencies($var1);
            push @deps, @rdeps if @rdeps;
        }
        if (exists $self->ast->{tmp_variables}->{$var2}) {
            push @deps, $var2;
            my @rdeps = $self->find_tmpvar_dependencies($var2);
            push @deps, @rdeps if @rdeps;
        }
    } else {
        return $self->parser->throw_error("Error in intermediate code '$tcode'");
    }
    return wantarray ? @deps : \@deps;
}

sub find_var_dependencies {
    my ($self, $tvar) = @_;
    my $tcode = $self->ast->{tmp_variables}->{$tvar};
    my ($tag, @args) = split /::/, $tcode;
    return unless $tag eq 'OP';
    my @deps = ();
    my $sz = scalar @args;
    if ($sz == 2) {
        my ($op, $var) = @args;
        if (exists $self->ast->{variables}->{$var}) {
            push @deps, $var;
        }
    } elsif ($sz == 3 or $sz == 4) {
        my ($var1, $op, $var2) = @args;
        if (exists $self->ast->{variables}->{$var1}) {
            push @deps, $var1;
        }
        if (exists $self->ast->{variables}->{$var2}) {
            push @deps, $var2;
        }
    } else {
        return $self->parser->throw_error("Error in intermediate code '$tcode'");
    }
    return wantarray ? @deps : \@deps;
}

sub do_i_use_stack {
    my ($self, @deps) = @_;
    return 0 unless @deps;
    my @bits = map { $self->pic->address_bits($_) } @deps;
    return 0 if max(@bits) == $self->pic->wreg_size;
    return 1;
}

sub generate_code_assign_expr {
    my ($self, $line) = @_;
    my @code = ();
    my $ast = $self->ast;
    my ($tag, $op, $varname, $rhs) = split /::/, $line;
    push @code, ";;; $line\n" if $self->intermediate_inline;
    if (exists $ast->{variables}->{$varname}) {
        if (exists $ast->{tmp_variables}->{$rhs}) {
            my $tmp_code = $ast->{tmp_variables}->{$rhs};
            my @deps = $self->find_tmpvar_dependencies($rhs);
            my @vdeps = $self->find_var_dependencies($rhs);
            push @deps, $rhs if @deps;
            if ($self->intermediate_inline) {
                push @code, "\t;; TMP_VAR DEPS - $rhs, ". join (',', @deps) if @deps;
                push @code, "\t;; VAR DEPS - ". join (',', @vdeps) if @vdeps;
                foreach (sort @deps) {
                    my $tcode = $ast->{tmp_variables}->{$_};
                    push @code, "\t;; $_ = $tcode";
                }
                push @code, "\t;; $line";
            }
            if (scalar @deps) {
                $ast->{tmp_stack_size} = max(scalar(@deps), $ast->{tmp_stack_size});
                ## it is assumed that the dependencies and intermediate code are
                #arranged in expected order
                # TODO: bits check
                my $counter = 0;
                my %tmpstack = map { $_ => 'VIC_STACK + ' . $counter++ } sort(@deps);
                foreach (sort @deps) {
                    my $tcode = $ast->{tmp_variables}->{$_};
                    my $result = $tmpstack{$_};
                    $result = uc $varname if $_ eq $rhs;
                    my @newcode = $self->generate_code_operations($tcode,
                                        STACK => \%tmpstack, RESULT => $result) if $tcode;
                    push @code, "\t;; $_ = $tcode" if $self->intermediate_inline;
                    push @code, @newcode if @newcode;
                }
            } else {
                # no tmp-var dependencies
                my $use_stack = $self->do_i_use_stack(@vdeps) unless scalar @deps;
                unless ($use_stack) {
                    my @newcode = $self->generate_code_operations($tmp_code,
                                                            RESULT => uc $varname);
                    push @code, @newcode if @newcode;
                } else {
                    # TODO: stack
                    XXX @vdeps;
                }
            }
        } else {
            my $nvar = $ast->{variables}->{$varname}->{name} || $varname;
            if ($rhs =~ /HASH|ARRAY/) {
                if (exists $self->global_collections->{$rhs}) {
                    $rhs = $self->global_collections->{$rhs};
                }
            }
            if (exists $self->ast->{variables}->{$varname}) {
                my $vhref = $self->ast->{variables}->{$varname};
                if ($vhref->{type} eq 'string') {
                    # send the string variable information to the method
                    # and hope that the method knows how to handle it
                    # this is useful for I/O methods and operator methods
                    # other methods should outright fail to use this and it should
                    # make sense there.#TODO: make better error messages for that.
                    $nvar = $vhref;
                }
            }
            my $method = $self->pic->validate_operator($op);
            $self->parser->throw_error("Invalid operator '$op' in intermediate code") unless $self->pic->can($method);
            my ($code, $funcs, $macros, $tables) = $self->pic->$method($nvar, $rhs);
            return $self->parser->throw_error("Error in intermediate code '$line'") unless $code;
            push @code, "\t;; $line" if $self->intermediate_inline;
            push @code, $code if $code;
            $self->_update_funcs($funcs, $macros) if ($funcs or $macros);
            $self->_update_tables($tables) if $tables;
        }
    } else {
        return $self->parser->throw_error(
            "Error in intermediate code '$line': $varname doesn't exist");
    }
    return @code;
}

sub find_nearest_loop {
    my ($self, $mapping, $child) = @_;
    return unless exists $mapping->{$child};
    if (exists $mapping->{$child}->{loop}) {
        return $child if $mapping->{$child}->{loop} eq '1';
    }
    return unless $mapping->{$child}->{parent};
    return $self->find_nearest_loop($mapping, $mapping->{$child}->{parent});
}

sub generate_code_blocks {
    my ($self, $line, $block) = @_;
    my @code = ();
    my $ast = $self->ast;
    my $mapping = $ast->{block_mapping};
    my $mapped_block = $mapping->{$block}->{block} || $block;
    my ($tag, $label, $child, $parent, $parent_label, $end_label) = split/::/, $line;
    return if ($child eq $block or $child eq $mapped_block or $child eq $parent);
    return if exists $ast->{generated_blocks}->{$child};
    push @code, "\t;; $line" if $self->intermediate_inline;
    my @newcode = $self->generate_code($ast, $child);
    my @bindexes = indexes { $_ eq 'BREAK' } @newcode;
    my @cindexes = indexes { $_ eq 'CONTINUE' } @newcode;
    if ($child =~ /^(?:True|False)/ and @newcode) {
        my $cond_end = "\tgoto $end_label;; go back to end of conditional\n";
        # handle break
        if (@bindexes) {
            #find top most parent loop
            my $el = $self->find_nearest_loop($mapping, $child);
            $el = $mapping->{$el}->{end_label} if $el;
            my $break_end;
            unless ($el) {
                $break_end = "\t;; break from existing block since $child not part of any loop\n";
                $break_end .= "\tgoto $end_label;; break from the conditional\n";
            } else {
                $break_end = "\tgoto $el;; break from the conditional\n";
            }
            $newcode[$_] = $break_end foreach @bindexes;
        }
        # handle continue
        if (@cindexes) {
            #find top most parent loop
            my $sl = $self->find_nearest_loop($mapping, $child);
            $sl = $mapping->{$sl}->{start_label} if $sl;
            my $cont_start = "\tgoto $sl;; go back to start of conditional\n" if $sl;
            $cont_start = "\tnop ;; $child or $parent have no start_label" unless $sl;
            $newcode[$_] = $cont_start foreach @cindexes;
        }
        # add the end _label
        # if the current block is a loop, the end label is the start label
        if (exists $mapping->{$child}->{loop} and $mapping->{$child}->{loop} eq '1') {
            my $slabel = $mapping->{$child}->{start_label} || $end_label;
            my $start_code = "\tgoto $slabel ;; go back to start of conditional\n" if $slabel;
            $start_code = $cond_end unless $start_code;
            push @newcode, $start_code;
        } else {
            push @newcode, $cond_end;
        }
        push @newcode, ";;;; end of $label";
        # hack into the function list
        $ast->{funcs}->{$label} = [@newcode];
    } elsif ($child =~ /^(?:Action|ISR)/ and @newcode) {
        my $cond_end = "\tgoto $end_label ;; go back to end of block\n";
        if (@bindexes) {
            # we just break from the current block since we are not in any
            # sub-block
            my $break_end = "\tgoto $end_label ;; break from the block\n";
            $newcode[$_] = $break_end foreach @bindexes;
        }
        if (@cindexes) {
            # continue gets ignored
            my $cont_start = ";; continue is a NOP for $child block";
            $newcode[$_] = $cont_start foreach @cindexes;
        }
        push @newcode, $cond_end, ";;;; end of $label";
        # hack into the function list
        $ast->{funcs}->{$label} = [@newcode];
    } elsif ($child =~ /^Loop/ and @newcode) {
        my $cond_end = "\tgoto $end_label;; go back to end of block\n";
        if (@bindexes) {
            # we just break from the current block since we are not in any
            # sub-block and are in a Loop already
            my $break_end = "\tgoto $end_label ;; break from the block\n";
            $newcode[$_] = $break_end foreach @bindexes;
        }
        if (@cindexes) {
            # continue goes to start of the loop
            my $cont_start = "\tgoto $label ;; go back to start of loop\n";
            $newcode[$_] = $cont_start foreach @cindexes;
        }
        push @code, @newcode;
        push @code, "\tgoto $label ;;;; end of $label\n";
        push @code, "$end_label:\n";
    } else {
        push @code, @newcode if @newcode;
    }
    $ast->{generated_blocks}->{$child} = 1 if @newcode;
    # parent equals block if it is the topmost of the stack
    # if the child is not a loop construct it will need a goto back to
    # the parent construct. if a child is a loop construct it will
    # already have a goto back to itself
    if (defined $parent and exists $ast->{$parent} and
        ref $ast->{$parent} eq 'ARRAY' and $parent ne $mapped_block) {
        my ($ptag, $plabel) = split /::/, $ast->{$parent}->[0];
        push @code, "\tgoto $plabel;; $plabel" if $plabel;
    }
    return @code;
}

sub generate_code_conditionals {
    my ($self, @condblocks) = @_;
    my @code = ();
    my $ast = $self->ast;
    my ($start_label, $end_label, $is_loop);
    my $blockcount = scalar @condblocks;
    my $index = 0;
    foreach my $line (@condblocks) {
        push @code, "\t;; $line" if $self->intermediate_inline;
        my %hh = split /::/, $line;
        my $subj = $hh{SUBJ};
        $index++ if $hh{SUBCOND};
        # for multiple if-else-if-else we adjust the labels
        # for single ones we do not
        $start_label = "_start_conditional_$hh{COND}" unless defined $start_label;
        $is_loop = $hh{LOOP} unless defined $is_loop;
        $end_label = $hh{END} unless defined $end_label;
        # we now modify the TRUE/FALSE/END labels
        if ($blockcount > 1) {
            my $el = "$hh{END}_$index"; # new label
            $hh{FALSE} = $el if $hh{FALSE} eq $hh{END};
            $hh{TRUE} = $el if $hh{TRUE} eq $hh{END};
            $hh{END} = $el;
        }
        if ($subj =~ /^\d+?$/) { # if subject is a literal
            push @code, "\t;; $line" if $self->intermediate_inline;
            if ($subj eq 0) {
                # is false
                push @code, "\tgoto $hh{FALSE}" if $hh{FALSE};
            } else {
                # is true
                push @code, "\tgoto $hh{TRUE}" if $hh{TRUE};
            }
            push @code, "\tgoto $hh{END}" if $hh{END};
            push @code, "$hh{END}:\n" if $hh{END};
        } elsif (exists $ast->{variables}->{$subj}) {
            ## we will never get here actually since we have eliminated this
            #possibility
            XXX \%hh;
        } elsif (exists $ast->{tmp_variables}->{$subj}) {
            my $tmp_code = $ast->{tmp_variables}->{$subj};
            my @deps = $self->find_tmpvar_dependencies($subj);
            my @vdeps = $self->find_var_dependencies($subj);
            push @deps, $subj if @deps;
            if ($self->intermediate_inline) {
                push @code, "\t;; TMP_VAR DEPS - $subj, ". join (',', @deps) if @deps;
                push @code, "\t;; VAR DEPS - ". join (',', @vdeps) if @vdeps;
                push @code, "\t;; $subj = $tmp_code";
            }
            if (scalar @deps) {
                $ast->{tmp_stack_size} = max(scalar(@deps), $ast->{tmp_stack_size});
                ## it is assumed that the dependencies and intermediate code are
                #arranged in expected order
                # TODO: bits check
                my $counter = 0;
                my %tmpstack = map { $_ => 'VIC_STACK + ' . $counter++ } sort(@deps);
                $counter = 0; # reset
                foreach (sort @deps) {
                    my $tcode = $ast->{tmp_variables}->{$_};
                    my %extra = (%hh, COUNTER => $counter++);
                    $extra{RESULT} = $tmpstack{$_} if $_ ne $subj;
                    my @newcode = $self->generate_code_operations($tcode,
                                                STACK => \%tmpstack, %extra) if $tcode;
                    push @code, @newcode if @newcode;
                }
            } else {
                # no tmp-var dependencies
                my $use_stack = $self->do_i_use_stack(@vdeps);
                unless ($use_stack) {
                    my @newcode = $self->generate_code_operations($tmp_code, %hh);
                    push @code, @newcode if @newcode;
                    return $self->parser->throw_error("Error in intermediate code '$tmp_code'")
                        unless @newcode;
                } else {
                    # TODO: stack
                    XXX \%hh;
                }
            }
        } else {
            return $self->parser->throw_error("Error in intermediate code '$line'");
        }
    }
    unshift @code, "$start_label:" if defined $start_label;
    push @code, "$end_label:" if defined $end_label and $blockcount > 1;
    return @code;
}

sub generate_code {
    my ($self, $ast, $block_name) = @_;
    my @code = ();
    return wantarray ? @code : [] unless defined $ast;
    return wantarray ? @code : [] unless exists $ast->{$block_name};
    $ast->{generated_blocks} = {} unless defined $ast->{generated_blocks};
    push @code, ";;;; generated code for $block_name";
    my $blocks = $ast->{$block_name};
    while (@$blocks) {
        my $line = shift @$blocks;
        next unless defined $line;
        if ($line =~ /^BLOCK::\w+/) {
            my $blockparams = $ast->{block_mapping}->{$block_name}->{params} || [];
            push @code, $self->generate_code_blocks($line, $block_name, $blockparams);
        } elsif ($line =~ /^INS::\w+/) {
            push @code, $self->generate_code_instruction($line);
        } elsif ($line =~ /^UNARY::\w+/) {
            push @code, $self->generate_code_unary_expr($line);
        } elsif ($line =~ /^SET::\w+/) {
            push @code, $self->generate_code_assign_expr($line);
        } elsif ($line =~ /^PARAM::(\w+)::(\w+)::(\w+)/) {
            if (exists $ast->{block_mapping}->{$block_name}) {
                my $op = $1;
                my $pblock = $2;
                my $pvar = $3;
                my $mapping = $ast->{block_mapping}->{$pblock};
                my $param_idx = scalar @{$mapping->{params}};
                my $paramvar = $mapping->{param_prefix} || lc($block_name . '_param');
                $paramvar .= $param_idx;
                push @{$mapping->{params}}, $paramvar;
                # map the param index back to the other mapping too
                if ($pblock ne $block_name and $mapping->{block} eq $block_name) {
                    my $mapping2 = $ast->{block_mapping}->{$block_name};
                    $mapping2->{params} = $mapping->{params};
                }
                my $pline = "SET::${op}::${pvar}::${paramvar}";
                #YYY [$pblock, $pvar, $block_name, $param_idx, $pline, $paramvar];
                push @code, $self->generate_code_assign_expr($pline);
            } else {
                $self->parser->throw_error("Intermediate code '$line' in block "
                    . "$block_name cannot be handled");
            }
        } elsif ($line =~ /^LABEL::(\w+)/) {
            my $lbl = $1;
            push @code, ";; $line" if $self->intermediate_inline;
            push @code, "$lbl:\n" if $lbl ne '_vic_simulator';
        } elsif ($line =~ /^COND::(\d+)::/) {
            my $cblock = $1;
            my @condblocks = ( $line );
            for my $i (1 .. scalar @$blocks) {
                next unless $blocks->[$i - 1] =~ /^COND::${cblock}::/;
                push @condblocks, $blocks->[$i - 1];
                delete $blocks->[$i - 1];
            }
            push @code, $self->generate_code_conditionals(reverse @condblocks);
        } elsif ($line =~ /^SIM::\w+/) {
            push @code, $self->generate_simulator_instruction($line);
        } else {
            $self->parser->throw_error("Intermediate code '$line' cannot be handled");
        }
    }
    return wantarray ? @code : [@code];
}

sub final {
    my ($self, $got) = @_;
    my $ast = $self->ast;
    return $self->parser->throw_error("Missing '}'") if scalar @{$ast->{block_stack}};
    return $self->parser->throw_error("Main not defined") unless defined $ast->{Main};
    # generate main code first so that any addition to functions, macros,
    # variables during generation can be handled after
    my @main_code = $self->generate_code($ast, 'Main');
    push @main_code, "_end_start:\n", "\tgoto \$\t;;;; end of Main";
    my $main_code = join("\n", @main_code);
    # variables are part of macros and need to go first
    my $variables = '';
    my $vhref = $ast->{variables};
    $variables .= "GLOBAL_VAR_UDATA udata\n" if keys %$vhref;
    my @global_vars = ();
    my @tables = ();
    my @init_vars = ();
    foreach my $var (sort(keys %$vhref)) {
        my $name = $vhref->{$var}->{name};
        my $typ = $vhref->{$var}->{type} || 'byte';
        my $data = $vhref->{$var}->{data};
        my $label = $vhref->{$var}->{label} || $name;
        my $szvar = $vhref->{$var}->{size};
        if ($typ eq 'string') {
            ##this may need to be stored in a different location
            $data = '' unless defined $data;
            ## different PICs may have different string handling
            my ($scode, $szdecl)= $self->pic->store_string($data, $label, $szvar);
            push @tables, $scode;
            $variables .= $szdecl if $szdecl;
        } elsif ($typ eq 'ARRAY') {
            $data = [] unless defined $data;
            push @init_vars, $self->pic->store_array($data, $label,
                                scalar(@$data), $szvar);
        } elsif ($typ eq 'HASH') {
            $data = {} unless defined $data;
            next unless defined $data->{TABLE};
            my $table = $data->{TABLE};
            my ($code, $szdecl) = $self->pic->store_table($table, $label,
                        scalar(@$table), $szvar);
            push @tables, $code;
            push @init_vars, $szdecl if $szdecl;
        } else {# $typ == 'byte' or any other
            # should we care about scope ?
            $variables .= "$name res $vhref->{$var}->{size}\n";
            if (($vhref->{$var}->{scope} eq 'global') or
                ($ast->{code_config}->{variable}->{export})) {
                push @global_vars, $name;
            }
        }
    }
    if ($ast->{tmp_stack_size}) {
        $variables .= "VIC_STACK res $ast->{tmp_stack_size}\t;; temporary stack\n";
    }
    if (scalar @global_vars) {
        # export the variables
        $variables .= "\tglobal ". join (", ", @global_vars) . "\n";
    }
    if (scalar @init_vars) {
        $variables .= "\nGLOBAL_VAR_IDATA idata\n"; # initialized variables
        $variables .= join("\n", @init_vars);
    }
    my $macros = '';
    foreach my $mac (sort(keys %{$ast->{macros}})) {
        $variables .= "\n" . $ast->{macros}->{$mac} . "\n", next if $mac =~ /_var$/;
        $macros .= $ast->{macros}->{$mac};
        $macros .= "\n";
    }
    my $isr_checks = '';
    my $isr_code = '';
    my $funcs = '';
    foreach my $fn (sort(keys %{$ast->{funcs}})) {
        my $fn_val = $ast->{funcs}->{$fn};
        # the default ISR checks to be done first
        if ($fn =~ /^isr_\w+$/) {
            if (ref $fn_val eq 'ARRAY') {
                $isr_checks .= join("\n", @$fn_val);
            } else {
                $isr_checks .= $fn_val . "\n";
            }
        # the user ISR code to be handled next
        } elsif ($fn =~ /^_isr_\w+$/) {
            if (ref $fn_val eq 'ARRAY') {
                $isr_code .= join("\n", @$fn_val);
            } else {
                $isr_code .= $fn_val . "\n";
            }
        } else {
            if (ref $fn_val eq 'ARRAY') {
                $funcs .= join("\n", @$fn_val);
            } else {
                $funcs .= "$fn:\n";
                $funcs .= $fn_val unless ref $fn_val eq 'ARRAY';
            }
            $funcs .= "\n";
        }
    }
    foreach my $tbl (@{$ast->{tables}}) {
        my $dt = $tbl->{bytes};
        my $dn = $tbl->{name};
    }
    $funcs .= join ("\n", @tables) if scalar @tables;
    $funcs .= $self->pic->store_bytes($ast->{tables});
    if (length $isr_code) {
        my $isr_entry = $self->pic->isr_entry;
        my $isr_exit = $self->pic->isr_exit;
        my $isr_var = $self->pic->isr_var;
        $isr_checks .= "\tgoto _isr_exit\n";
        $isr_code = "\tgoto _start\n$isr_entry\n$isr_checks\n$isr_code\n$isr_exit\n";
        $variables .= "\n$isr_var\n";
    }
    my ($sim_include, $sim_setup_code) = ('', '');
    # we need to generate simulator code if either the Simulator block is
    # present or if any asserts are present
    if ($self->simulator and not $self->simulator->disable and
        ($ast->{Simulator} or $ast->{asserts})) {
        my $stype = $self->simulator->type;
        $sim_include .= ";;;; generated code for $stype header file\n";
        $sim_include .= '#include <' . $self->simulator->include .">\n";
        my @setup_code = $self->generate_code($ast, 'Simulator');
        my $init_code = $self->simulator->init_code;
        $sim_setup_code .= $init_code . "\n" if defined $init_code;
        $sim_setup_code .= join("\n", @setup_code) if scalar @setup_code;
        if ($self->simulator->should_autorun) {
            $sim_setup_code .= $self->simulator->get_autorun_code;
        }
    }
    # final get of the chip config in case it has been modified
    $self->ast->{chip_config} = $self->pic->get_chip_config;
    my $pic = <<"...";
;;;; generated code for PIC header file
#include <$ast->{include}>
$sim_include
;;;; generated code for variables
$variables
;;;; generated code for macros
$macros

$ast->{chip_config}

\torg $ast->{org}

$sim_setup_code

$isr_code

$main_code

;;;; generated code for functions
$funcs
;;;; generated code for end-of-file
\tend
...
    return $pic;
}

1;

=encoding utf8

=head1 NAME

VIC::Receiver

=head1 SYNOPSIS

The Pegex::Receiver class for handling the grammar.

=head1 DESCRIPTION

INTERNAL CLASS.

=head1 AUTHOR

Vikas N Kumar <vikas@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2014. Vikas N Kumar

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
