
package WAP::wmls::parser;

use strict;
use warnings;
use bigint;
use bignum;

use Carp;

my $OneMoreTime;
my $OneMoreExpr;

sub optWarning {
    my $parser = shift;
    my ($node, $msg) = @_;

    $msg ||= ".\n";

    if (exists $parser->YYData->{nb_warning}) {
        $parser->YYData->{nb_warning} ++;
    }
    else {
        $parser->YYData->{nb_warning} = 1;
    }

    print STDOUT '#',$parser->YYData->{filename},':',$node->{OpCode}->{Lineno},'#Warning: ',$msg
            if (        exists $parser->YYData->{verbose_warning}
                    and $parser->YYData->{verbose_warning});
    return;
}

sub optInfo {
    my $parser = shift;
    my ($node, $msg) = @_;

    $msg ||= ".\n";

    if (exists $parser->YYData->{nb_info}) {
        $parser->YYData->{nb_info} ++;
    } else {
        $parser->YYData->{nb_info} = 1;
    }

    print STDOUT '#',$parser->YYData->{filename},':',$node->{OpCode}->{Lineno},'#Info: ',$msg
            if (        exists $parser->YYData->{verbose_info}
                    and $parser->YYData->{verbose_info});
    return;
}

sub optDebug {
    my $parser = shift;
    my ($node, $msg) = @_;

    $msg ||= ".\n";

    print STDOUT '#',$parser->YYData->{filename},':',$node->{OpCode}->{Lineno},'#Debug: ',$msg
            if (        exists $parser->YYData->{verbose_debug}
                    and $parser->YYData->{verbose_debug});
    return;
}

sub checkRangeInteger {
    my $parser = shift;
    my ($opcode) = @_;
    my $value = $opcode->{Value};
    if ($value > 2147483647 or $value < -2147483648) {
        $parser->Error("Integer $value is out of range.\n");
        $opcode->{TypeDef} = 'TYPE_INVALID';
    }
    return;
}

sub checkRangeFloat {
    my $parser = shift;
    my ($opcode) = @_;
    my $value = $opcode->{Value};
    my $abs_v = abs $value;
    if    ($abs_v > 3.40282347e+38) {
        $parser->Error("Float $value is out of range.\n");
        $opcode->{TypeDef} = 'TYPE_INVALID';
    }
    elsif ($abs_v < 1.17549435e-38) {
        $parser->Warning("Float $value is underflow.\n");
        $opcode->{Value} = 0.0;
    }
    return;
}

sub evalUnopInteger {
    my $parser = shift;
    my ($op, $cst) = @_;
    my $opcode = $cst->{OpCode};
    my $oper = $op->{OpCode}->{Operator};
    if    ($oper eq 'typeof') {
        $opcode->{TypeDef} = 'TYPE_INTEGER';
        $opcode->{Value} = 0;
        $op->del();
        $OneMoreExpr = 1;
    }
    elsif ($oper eq 'isvalid') {
        $opcode->{TypeDef} = 'TYPE_BOOLEAN';
        $opcode->{Value} = 1;
        $op->del();
        $OneMoreExpr = 1;
    }
    elsif ($oper eq '-') {
        $opcode->{Value} = - $opcode->{Value};
        $parser->checkRangeInteger($opcode);
        $op->del();
        $OneMoreExpr = 1;
    }
    elsif ($oper eq '~') {
        $opcode->{Value} = ~ $opcode->{Value};
        $parser->checkRangeInteger($opcode);
        $op->del();
        $OneMoreExpr = 1;
    }
    elsif ($oper eq '!') {
        $opcode->{Value} = ($opcode->{Value}) ? 0 : 1;
        $opcode->{TypeDef} = 'TYPE_BOOLEAN';
        $op->del();
        $OneMoreExpr = 1;
    }
    elsif ($oper eq '++') {
        $opcode->{Value} ++;
        $parser->checkRangeInteger($opcode);
        $op->del();
        $OneMoreExpr = 1;
    }
    elsif ($oper eq '--') {
        $opcode->{Value} --;
        $parser->checkRangeInteger($opcode);
        $op->del();
        $OneMoreExpr = 1;
    }
    else {
        croak "INTERNAL ERROR evalUnopInteger (op:$oper)\n";
    }
    return;
}

sub evalUnopFloat {
    my $parser = shift;
    my ($op, $cst) = @_;
    my $opcode = $cst->{OpCode};
    my $oper = $op->{OpCode}->{Operator};
    if    ($oper eq 'typeof') {
        # if (interpreter supports float)
        #     integer(1)
        # else
        #     invalid
    }
    elsif ($oper eq 'isvalid') {
        # if (interpreter supports float)
        #     boolean(true)
        # else
        #     invalid
    }
    elsif ($oper eq '-') {
        $opcode->{Value} = - $opcode->{Value};
        $parser->checkRangeFloat($opcode);
        $op->del();
        $OneMoreExpr = 1;
    }
    elsif ($oper eq '~') {
    }
    elsif ($oper eq '!') {
        # if (interpreter supports float)
        #     boolean
        # else
        #     invalid
    }
    elsif ($oper eq '++') {
        $opcode->{Value} ++;
        $parser->checkRangeFloat($opcode);
        $op->del();
        $OneMoreExpr = 1;
    }
    elsif ($oper eq '--') {
        $opcode->{Value} --;
        $parser->checkRangeFloat($opcode);
        $op->del();
        $OneMoreExpr = 1;
    }
    else {
        croak "INTERNAL ERROR evalUnopFloat (op:$oper)\n";
    }
    return;
}

sub evalUnopString {
    my $parser = shift;
    my ($op, $cst) = @_;
    my $opcode = $cst->{OpCode};
    my $oper = $op->{OpCode}->{Operator};
    if    ($oper eq 'typeof') {
        $opcode->{TypeDef} = 'TYPE_INTEGER';
        $opcode->{Value} = 2;
        $op->del();
        $OneMoreExpr = 1;
    }
    elsif ($oper eq 'isvalid') {
        $opcode->{TypeDef} = 'TYPE_BOOLEAN';
        $opcode->{Value} = 1;
        $op->del();
        $OneMoreExpr = 1;
    }
    elsif ($oper eq '-') {
    }
    elsif ($oper eq '~') {
    }
    elsif ($oper eq '!') {
        $opcode->{Value} = (length $opcode->{Value}) ? 0 : 1;
        $opcode->{TypeDef} = 'TYPE_BOOLEAN';
        $op->del();
        $OneMoreExpr = 1;
    }
    elsif ($oper eq '++') {
    }
    elsif ($oper eq '--') {
    }
    else {
        croak "INTERNAL ERROR evalUnopString (op:$oper)\n";
    }
    return;
}

sub evalUnopBoolean {
    my $parser = shift;
    my ($op, $cst) = @_;
    my $opcode = $cst->{OpCode};
    my $oper = $op->{OpCode}->{Operator};
    if    ($oper eq 'typeof') {
        $opcode->{TypeDef} = 'TYPE_INTEGER';
        $opcode->{Value} = 3;
        $op->del();
        $OneMoreExpr = 1;
    }
    elsif ($oper eq 'isvalid') {
        $opcode->{Value} = 1;
        $op->del();
        $OneMoreExpr = 1;
    }
    elsif ($oper eq '-') {
    }
    elsif ($oper eq '~') {
    }
    elsif ($oper eq '!') {
        $opcode->{Value} = ($opcode->{Value}) ? 0 : 1;
        $op->del();
        $OneMoreExpr = 1;
    }
    elsif ($oper eq '++') {
    }
    elsif ($oper eq '--') {
    }
    else {
        croak "INTERNAL ERROR evalUnopBoolean (op:$oper)\n";
    }
    return;
}

sub evalUnopInvalid {
    my $parser = shift;
    my ($op, $cst) = @_;
    my $opcode = $cst->{OpCode};
    my $oper = $op->{OpCode}->{Operator};
    if    ($oper eq 'typeof') {
        $opcode->{TypeDef} = 'TYPE_INTEGER';
        $opcode->{Value} = 4;
        $op->del();
        $OneMoreExpr = 1;
    }
    elsif ($oper eq 'isvalid') {
        $opcode->{TypeDef} = 'TYPE_BOOLEAN';
        $opcode->{Value} = 0;
        $op->del();
        $OneMoreExpr = 1;
    }
    elsif ($oper eq '-') {
        $op->del();
        $OneMoreExpr = 1;
    }
    elsif ($oper eq '~') {
        $op->del();
        $OneMoreExpr = 1;
    }
    elsif ($oper eq '!') {
        $op->del();
        $OneMoreExpr = 1;
    }
    elsif ($oper eq '++') {
        $op->del();
        $OneMoreExpr = 1;
    }
    elsif ($oper eq '--') {
        $op->del();
        $OneMoreExpr = 1;
    }
    else {
        croak "INTERNAL ERROR evalUnopInvalid (op:$oper)\n";
    }
    return;
}

sub evalBinopInteger {
    my $parser = shift;
    my ($op, $left, $right) = @_;
    my $oper = $op->{OpCode}->{Operator};
    if    ($oper eq '+') {
        $left->{OpCode}->{Value} += $right->{OpCode}->{Value};
        $parser->checkRangeInteger($left->{OpCode});
        $right->del();
        $op->del();
        $OneMoreExpr = 1;
    }
    elsif ($oper eq '-') {
        $left->{OpCode}->{Value} -= $right->{OpCode}->{Value};
        $parser->checkRangeInteger($left->{OpCode});
        $right->del();
        $op->del();
        $OneMoreExpr = 1;
    }
    elsif ($oper eq '*') {
        $left->{OpCode}->{Value} *= $right->{OpCode}->{Value};
        $parser->checkRangeInteger($left->{OpCode});
        $right->del();
        $op->del();
        $OneMoreExpr = 1;
    }
    elsif ($oper eq '/') {
        if ($right->{OpCode}->{Value} == 0) {
            $left->{OpCode}->{TypeDef} = 'TYPE_INVALID';
            delete $left->{OpCode}->{Value};
            $parser->optWarning($op, "Division by zero.\n");
            $right->del();
            $op->del();
            $OneMoreExpr = 1;
        }
    }
    elsif ($oper eq 'div') {
        if ($right->{OpCode}->{Value} == 0) {
            $left->{OpCode}->{TypeDef} = 'TYPE_INVALID';
            delete $left->{OpCode}->{Value};
            $parser->optWarning($op, "Integer division by zero.\n");
        }
        else {
            use integer;
            $left->{OpCode}->{Value} /= $right->{OpCode}->{Value};
            $parser->checkRangeInteger($left->{OpCode});
        }
        $right->del();
        $op->del();
        $OneMoreExpr = 1;
    }
    elsif ($oper eq '%') {
        if ($right->{OpCode}->{Value} == 0) {
            $left->{OpCode}->{TypeDef} = 'TYPE_INVALID';
            delete $left->{OpCode}->{Value};
            $parser->optWarning($op, "Reminder by zero.\n");
        }
        else {
            $left->{OpCode}->{Value} %= $right->{OpCode}->{Value};
            $parser->checkRangeInteger($left->{OpCode});
        }
        $right->del();
        $op->del();
        $OneMoreExpr = 1;
    }
    elsif ($oper eq '<<') {
        $left->{OpCode}->{Value} <<= $right->{OpCode}->{Value};
        $parser->checkRangeInteger($left->{OpCode});
        $right->del();
        $op->del();
        $OneMoreExpr = 1;
    }
    elsif ($oper eq '>>') {
        $left->{OpCode}->{Value} >>= $right->{OpCode}->{Value};
        $parser->checkRangeInteger($left->{OpCode});
        $right->del();
        $op->del();
        $OneMoreExpr = 1;
    }
    elsif ($oper eq '>>>') {
        my $bit = $left->{OpCode}->{Value} & 0x80000000;
        $left->{OpCode}->{Value} >>= $right->{OpCode}->{Value};
        $left->{OpCode}->{Value} |= $bit;
        $parser->checkRangeInteger($left->{OpCode});
        $right->del();
        $op->del();
        $OneMoreExpr = 1;
    }
    elsif ($oper eq '<') {
        $left->{OpCode}->{Value} = ($left->{OpCode}->{Value} < $right->{OpCode}->{Value}) ? 1 : 0;
        $left->{OpCode}->{TypeDef} = 'TYPE_BOOLEAN';
        $right->del();
        $op->del();
        $OneMoreExpr = 1;
    }
    elsif ($oper eq '>') {
        $left->{OpCode}->{Value} = ($left->{OpCode}->{Value} > $right->{OpCode}->{Value}) ? 1 : 0;
        $left->{OpCode}->{TypeDef} = 'TYPE_BOOLEAN';
        $right->del();
        $op->del();
        $OneMoreExpr = 1;
    }
    elsif ($oper eq '<=') {
        $left->{OpCode}->{Value} = ($left->{OpCode}->{Value} <= $right->{OpCode}->{Value}) ? 1 : 0;
        $left->{OpCode}->{TypeDef} = 'TYPE_BOOLEAN';
        $right->del();
        $op->del();
        $OneMoreExpr = 1;
    }
    elsif ($oper eq '>=') {
        $left->{OpCode}->{Value} = ($left->{OpCode}->{Value} >= $right->{OpCode}->{Value}) ? 1 : 0;
        $left->{OpCode}->{TypeDef} = 'TYPE_BOOLEAN';
        $right->del();
        $op->del();
        $OneMoreExpr = 1;
    }
    elsif ($oper eq '==') {
        $left->{OpCode}->{Value} = ($left->{OpCode}->{Value} == $right->{OpCode}->{Value}) ? 1 : 0;
        $left->{OpCode}->{TypeDef} = 'TYPE_BOOLEAN';
        $right->del();
        $op->del();
        $OneMoreExpr = 1;
    }
    elsif ($oper eq '!=') {
        $left->{OpCode}->{Value} = ($left->{OpCode}->{Value} != $right->{OpCode}->{Value}) ? 1 : 0;
        $left->{OpCode}->{TypeDef} = 'TYPE_BOOLEAN';
        $right->del();
        $op->del();
        $OneMoreExpr = 1;
    }
    elsif ($oper eq '&') {
        $left->{OpCode}->{Value} &= $right->{OpCode}->{Value};
        $parser->checkRangeInteger($left->{OpCode});
        $right->del();
        $op->del();
        $OneMoreExpr = 1;
    }
    elsif ($oper eq '^') {
        $left->{OpCode}->{Value} ^= $right->{OpCode}->{Value};
        $parser->checkRangeInteger($left->{OpCode});
        $right->del();
        $op->del();
        $OneMoreExpr = 1;
    }
    elsif ($oper eq '|') {
        $left->{OpCode}->{Value} |= $right->{OpCode}->{Value};
        $parser->checkRangeInteger($left->{OpCode});
        $right->del();
        $op->del();
        $OneMoreExpr = 1;
    }
    else {
        croak "INTERNAL ERROR evalBinopInteger (oper:$oper)\n";
    }
    return;
}

sub evalBinopFloat {
    my $parser = shift;
    my ($op, $left, $right) = @_;
    my $oper = $op->{OpCode}->{Operator};
    if    ($oper eq '+') {
        $left->{OpCode}->{Value} += $right->{OpCode}->{Value};
        $parser->checkRangeFloat($left->{OpCode});
        $right->del();
        $op->del();
        $OneMoreExpr = 1;
    }
    elsif ($oper eq '-') {
        $left->{OpCode}->{Value} -= $right->{OpCode}->{Value};
        $parser->checkRangeFloat($left->{OpCode});
        $right->del();
        $op->del();
        $OneMoreExpr = 1;
    }
    elsif ($oper eq '*') {
        $left->{OpCode}->{Value} *= $right->{OpCode}->{Value};
        $parser->checkRangeFloat($left->{OpCode});
        $right->del();
        $op->del();
        $OneMoreExpr = 1;
    }
    elsif ($oper eq '/') {
        if ($right->{OpCode}->{Value} == 0) {
            $left->{OpCode}->{TypeDef} = 'TYPE_INVALID';
            delete $left->{OpCode}->{Value};
            $parser->optWarning($op, "Division by zero.\n");
        }
        else {
            $left->{OpCode}->{Value} /= $right->{OpCode}->{Value};
            $parser->checkRangeFloat($left->{OpCode});
        }
        $right->del();
        $op->del();
        $OneMoreExpr = 1;
    }
    elsif ($oper eq 'div') {
    }
    elsif ($oper eq '%') {
    }
    elsif ($oper eq '<<') {
    }
    elsif ($oper eq '>>') {
    }
    elsif ($oper eq '>>>') {
    }
    elsif ($oper eq '<') {
    }
    elsif ($oper eq '>') {
    }
    elsif ($oper eq '<=') {
    }
    elsif ($oper eq '>=') {
    }
    elsif ($oper eq '==') {
    }
    elsif ($oper eq '!=') {
    }
    elsif ($oper eq '&') {
    }
    elsif ($oper eq '^') {
    }
    elsif ($oper eq '|') {
    }
    else {
        croak "INTERNAL ERROR evalBinopFloat (oper:$oper)\n";
    }
    return;
}

sub optIdtLeftInteger {
    my $parser = shift;
    my ($op, $left, $right) = @_;
    my $val = $left->{OpCode}->{Value};
    my $oper = $op->{OpCode}->{Operator};
    if    ($val == 0) {
        if    ($oper eq '+') {
            $op->del();
            $left->del();
            $OneMoreExpr = 1;
        }
        elsif ($oper eq '-') {
            $left->del();
            bless($op->{OpCode}, 'UnaryOp');
            $OneMoreExpr = 1;
        }
        elsif ($oper eq '*') {
            $op->del();
            $right->insert(new Pop($parser));
            $OneMoreExpr = 1;
        }
        elsif ($oper eq '/') {
        }
        elsif ($oper eq 'div') {
            $op->del();
            $right->insert(new Pop($parser));
            $OneMoreExpr = 1;
        }
        elsif ($oper eq '%') {
            $op->del();
            $right->insert(new Pop($parser));
            $OneMoreExpr = 1;
        }
        elsif ($oper eq '<<') {
            $op->del();
            $op->insert(new Pop($parser));
            $OneMoreExpr = 1;
        }
        elsif ($oper eq '>>') {
            $op->del();
            $op->insert(new Pop($parser));
            $OneMoreExpr = 1;
        }
        elsif ($oper eq '>>>') {
            $op->del();
            $op->insert(new Pop($parser));
            $OneMoreExpr = 1;
        }
        elsif ($oper eq '<') {
        }
        elsif ($oper eq '>') {
        }
        elsif ($oper eq '<=') {
        }
        elsif ($oper eq '>=') {
        }
        elsif ($oper eq '==') {
        }
        elsif ($oper eq '!=') {
        }
        elsif ($oper eq '&') {
            $op->del();
            $right->insert(new Pop($parser));
            $OneMoreExpr = 1;
        }
        elsif ($oper eq '^') {
            $op->del();
            $left->del();
            $OneMoreExpr = 1;
        }
        elsif ($oper eq '|') {
            $op->del();
            $left->del();
            $OneMoreExpr = 1;
        }
        else {
            croak "INTERNAL ERROR optIdtLeftInteger (oper:$oper)\n";
        }
    }
    elsif ($val == 1) {
        if    ($oper eq '+') {
            $left->del();
            bless($op->{OpCode}, 'UnaryOp');
            $op->{OpCode}->{Operator} = '++';
            $OneMoreExpr = 1;
        }
        elsif ($oper eq '-') {
        }
        elsif ($oper eq '*') {
            $left->del();
            $op->del();
            $OneMoreExpr = 1;
        }
        elsif ($oper eq '/') {
        }
        elsif ($oper eq 'div') {
        }
        elsif ($oper eq '%') {
        }
        elsif ($oper eq '<<') {
        }
        elsif ($oper eq '>>') {
        }
        elsif ($oper eq '>>>') {
        }
        elsif ($oper eq '<') {
        }
        elsif ($oper eq '>') {
        }
        elsif ($oper eq '<=') {
        }
        elsif ($oper eq '>=') {
        }
        elsif ($oper eq '==') {
        }
        elsif ($oper eq '!=') {
        }
        elsif ($oper eq '&') {
        }
        elsif ($oper eq '^') {
        }
        elsif ($oper eq '|') {
        }
        else {
            croak "INTERNAL ERROR optIdtLeftInteger (oper:$oper)\n";
        }
    }
    elsif ($val == -1) {
        if    ($oper eq '+') {
            $left->del();
            bless($op->{OpCode}, 'UnaryOp');
            $op->{OpCode}->{Operator} = '--';
            $OneMoreExpr = 1;
        }
        elsif ($oper eq '-') {
        }
        elsif ($oper eq '*') {
            $left->del();
            bless($op->{OpCode}, 'UnaryOp');
            $op->{OpCode}->{Operator} = '-';
            $OneMoreExpr = 1;
        }
        elsif ($oper eq '/') {
        }
        elsif ($oper eq 'div') {
        }
        elsif ($oper eq '%') {
        }
        elsif ($oper eq '<<') {
        }
        elsif ($oper eq '>>') {
        }
        elsif ($oper eq '>>>') {
        }
        elsif ($oper eq '<') {
        }
        elsif ($oper eq '>') {
        }
        elsif ($oper eq '<=') {
        }
        elsif ($oper eq '>=') {
        }
        elsif ($oper eq '==') {
        }
        elsif ($oper eq '!=') {
        }
        elsif ($oper eq '&') {
        }
        elsif ($oper eq '^') {
        }
        elsif ($oper eq '|') {
        }
        else {
            croak "INTERNAL ERROR optIdtLeftInteger (oper:$oper)\n";
        }
    }
    return;
}

sub optIdtRightInteger {
    my $parser = shift;
    my ($op, $left, $right) = @_;
    my $val = $right->{OpCode}->{Value};
    my $oper = $op->{OpCode}->{Operator};
    if    ($val == 0) {
        if    ($oper eq '+') {
            $op->del();
            $right->del();
            $OneMoreExpr = 1;
        }
        elsif ($oper eq '-') {
            $op->del();
            $right->del();
            $OneMoreExpr = 1;
        }
        elsif ($oper eq '*') {
            $op->del();
            $left->insert(new Pop($parser));
            $OneMoreExpr = 1;
        }
        elsif ($oper eq '/') {
            $op->del();
            $left->insert(new Pop($parser));
            $right->{OpCode}->{TypeDef} = 'TYPE_INVALID';
            $OneMoreExpr = 1;
            $parser->optWarning($op, "Division by zero.\n");
        }
        elsif ($oper eq 'div') {
            $op->del();
            $left->insert(new Pop($parser));
            $right->{OpCode}->{TypeDef} = 'TYPE_INVALID';
            $OneMoreExpr = 1;
            $parser->optWarning($op, "Integer division by zero.\n");
        }
        elsif ($oper eq '%') {
            $op->del();
            $left->insert(new Pop($parser));
            $right->{OpCode}->{TypeDef} = 'TYPE_INVALID';
            $OneMoreExpr = 1;
            $parser->optWarning($op, "Reminder by zero.\n");
        }
        elsif ($oper eq '<<') {
            $op->del();
            $right->del();
            $OneMoreExpr = 1;
        }
        elsif ($oper eq '>>') {
            $op->del();
            $right->del();
            $OneMoreExpr = 1;
        }
        elsif ($oper eq '>>>') {
            $op->del();
            $right->del();
            $OneMoreExpr = 1;
        }
        elsif ($oper eq '<') {
        }
        elsif ($oper eq '>') {
        }
        elsif ($oper eq '<=') {
        }
        elsif ($oper eq '>=') {
        }
        elsif ($oper eq '==') {
        }
        elsif ($oper eq '!=') {
        }
        elsif ($oper eq '&') {
            $op->del();
            $left->insert(new Pop($parser));
            $OneMoreExpr = 1;
        }
        elsif ($oper eq '^') {
            $op->del();
            $right->del();
            $OneMoreExpr = 1;
        }
        elsif ($oper eq '|') {
            $op->del();
            $right->del();
            $OneMoreExpr = 1;
        }
        else {
            croak "INTERNAL ERROR optIdtRightInteger (oper:$oper)\n";
        }
    }
    elsif ($val == 1) {
        if    ($oper eq '+') {
            $right->del();
            bless($op->{OpCode}, 'UnaryOp');
            $op->{OpCode}->{Operator} = '++';
            $OneMoreExpr = 1;
        }
        elsif ($oper eq '-') {
            $right->del();
            bless($op->{OpCode}, 'UnaryOp');
            $op->{OpCode}->{Operator} = '--';
            $OneMoreExpr = 1;
        }
        elsif ($oper eq '*') {
            $right->del();
            $op->del();
            $OneMoreExpr = 1;
        }
        elsif ($oper eq '/') {
        }
        elsif ($oper eq 'div') {
            $right->del();
            $op->del();
            $OneMoreExpr = 1;
        }
        elsif ($oper eq '%') {
            $op->del();
            $left->insert(new Pop($parser));
            $right->{OpCode}->{Value} = 0;
            $OneMoreExpr = 1;
        }
        elsif ($oper eq '<<') {
        }
        elsif ($oper eq '>>') {
        }
        elsif ($oper eq '>>>') {
        }
        elsif ($oper eq '<') {
        }
        elsif ($oper eq '>') {
        }
        elsif ($oper eq '<=') {
        }
        elsif ($oper eq '>=') {
        }
        elsif ($oper eq '==') {
        }
        elsif ($oper eq '!=') {
        }
        elsif ($oper eq '&') {
        }
        elsif ($oper eq '^') {
        }
        elsif ($oper eq '|') {
        }
        else {
            croak "INTERNAL ERROR optIdtRightInteger (oper:$oper)\n";
        }
    }
    elsif ($val == -1) {
        if    ($oper eq '+') {
            $right->del();
            bless($op->{OpCode}, 'UnaryOp');
            $op->{OpCode}->{Operator} = '--';
            $OneMoreExpr = 1;
        }
        elsif ($oper eq '-') {
            $right->del();
            bless($op->{OpCode}, 'UnaryOp');
            $op->{OpCode}->{Operator} = '++';
            $OneMoreExpr = 1;
        }
        elsif ($oper eq '*') {
            $right->del();
            bless($op->{OpCode}, 'UnaryOp');
            $op->{OpCode}->{Operator} = '-';
            $OneMoreExpr = 1;
        }
        elsif ($oper eq '/') {
        }
        elsif ($oper eq 'div') {
            $right->del();
            bless($op->{OpCode}, 'UnaryOp');
            $op->{OpCode}->{Operator} = '-';
            $OneMoreExpr = 1;
        }
        elsif ($oper eq '%') {
            $op->del();
            $left->insert(new Pop($parser));
            $right->{OpCode}->{Value} = 0;
            $OneMoreExpr = 1;
        }
        elsif ($oper eq '<<') {
        }
        elsif ($oper eq '>>') {
        }
        elsif ($oper eq '>>>') {
        }
        elsif ($oper eq '<') {
        }
        elsif ($oper eq '>') {
        }
        elsif ($oper eq '<=') {
        }
        elsif ($oper eq '>=') {
        }
        elsif ($oper eq '==') {
        }
        elsif ($oper eq '!=') {
        }
        elsif ($oper eq '&') {
        }
        elsif ($oper eq '^') {
        }
        elsif ($oper eq '|') {
        }
        else {
            croak "INTERNAL ERROR optIdtRightInteger (oper:$oper)\n";
        }
    }
    return;
}

sub optIdtRightFloat {
    my $parser = shift;
    my ($op, $left, $right) = @_;
    my $val = $right->{OpCode}->{Value};
    my $oper = $op->{OpCode}->{Operator};
    if    ($val == 0) {
        if    ($oper eq '+') {
        }
        elsif ($oper eq '-') {
        }
        elsif ($oper eq '*') {
        }
        elsif ($oper eq '/') {
            $op->del();
            $left->insert(new Pop($parser));
            $right->{OpCode}->{TypeDef} = 'TYPE_INVALID';
            $OneMoreExpr = 1;
            $parser->optWarning($op, "Division by zero.\n");
        }
        elsif ($oper eq 'div') {
        }
        elsif ($oper eq '%') {
        }
        elsif ($oper eq '<<') {
        }
        elsif ($oper eq '>>') {
        }
        elsif ($oper eq '>>>') {
        }
        elsif ($oper eq '<') {
        }
        elsif ($oper eq '>') {
        }
        elsif ($oper eq '<=') {
        }
        elsif ($oper eq '>=') {
        }
        elsif ($oper eq '==') {
        }
        elsif ($oper eq '!=') {
        }
        elsif ($oper eq '&') {
        }
        elsif ($oper eq '^') {
        }
        elsif ($oper eq '|') {
        }
        else {
            croak "INTERNAL ERROR optIdtRightFloat (oper:$oper)\n";
        }
    }
    return;
}

sub _optAddAsg {
    my ($asg, $cst) = @_;
    my $val = $cst->{OpCode}->{Value};
    if    ($val == 1) {
        $cst->del();
        bless($asg->{OpCode}, 'IncrVar');
    }
    elsif ($val == 0) {
        $cst->del();
        $asg->del();
        $OneMoreExpr = 1;
    }
    elsif ($val == -1) {
        $cst->del();
        bless($asg->{OpCode}, 'DecrVar');
    }
    return;
}

sub _optSubAsg {
    my ($asg, $cst) = @_;
    my $val = $cst->{OpCode}->{Value};
    if    ($val == 1) {
        $cst->del();
        bless($asg->{OpCode}, 'DecrVar');
    }
    elsif ($val == 0) {
        $cst->del();
        $asg->del();
        $OneMoreExpr = 1;
    }
    elsif ($val == -1) {
        $cst->del();
        bless($asg->{OpCode}, 'IncrVar');
    }
    return;
}

sub optEvalExpr {
    my $parser = shift;
    my ($expr) = @_;

    my $cnt = 0;
    do {
        $cnt ++;
#       print "optim Expr $cnt\n";
        $OneMoreExpr = 0;
        for (my $node = $expr->getLastActive(); defined $node; $node = $node->getPrevActive()) {
            my $opcode = $node->{OpCode};
            if    ($opcode->isa('UnaryOp')) {
                my $prev = $node->getPrevActive();
                croak "INTERNAL ERROR optEvalExpr\n"
                        unless (defined $prev);
                if ($prev->{OpCode}->isa('LoadConst')) {
                    my $type = $expr->{OpCode}->{TypeDef};
                    if    ($type eq 'TYPE_INTEGER') {
                        $parser->evalUnopInteger($node, $prev);
                    }
                    elsif ($type eq 'TYPE_FLOAT') {
                        $parser->evalUnopFloat($node, $prev);
                    }
                    elsif ($type eq 'TYPE_STRING' or $type eq 'TYPE_UTF8_STRING') {
                        $parser->evalUnopString($node, $prev);
                    }
                    elsif ($type eq 'TYPE_BOOLEAN') {
                        $parser->evalUnopBoolean($node, $prev);
                    }
                    elsif ($type eq 'TYPE_INVALID') {
                        $parser->evalUnopInvalid($node, $prev);
                    }
                    else {
                        croak "INTERNAL ERROR optEvalExpr (type:$type)\n";
                    }
                }
            }
            elsif ($opcode->isa('BinaryOp')) {
                my $right = $node->getPrevActive();
                croak "INTERNAL ERROR optEvalExpr\n"
                        unless (defined $right);
                my $left = $node->{OpCode}->{Left};
                croak "INTERNAL ERROR optEvalExpr (left)\n"
                        unless (defined $left);
                if (      $left->{OpCode}->isa('LoadConst')
                      and $left->{OpCode}->{TypeDef} eq 'TYPE_INVALID' ) {
                    $right->del();
                    $node->del();
                    $OneMoreExpr = 1;
                }
                elsif (   $right->{OpCode}->isa('LoadConst')
                      and $right->{OpCode}->{TypeDef} eq 'TYPE_INVALID' ) {
                    $left->del();
                    $node->del();
                    $OneMoreExpr = 1;
                }
                elsif (   $left->{OpCode}->isa('LoadConst')
                      and $right->{OpCode}->isa('LoadConst') ) {
                    my $type_l = $left->{OpCode}->{TypeDef};
                    my $type_r = $right->{OpCode}->{TypeDef};
                    if ($type_l eq $type_r) {
                        if      ($type_r eq 'TYPE_INTEGER') {
                            $parser->evalBinopInteger($node, $left, $right);
                        }
                        elsif ($type_r eq 'TYPE_FLOAT') {
                            $parser->evalBinopFloat($node, $left, $right);
                        }
                    }
                }
                elsif (   $left->{OpCode}->isa('LoadConst') ) {
                    my $type = $left->{OpCode}->{TypeDef};
                    if    ($type eq 'TYPE_INTEGER') {
                        $parser->optIdtLeftInteger($node, $left, $right);
                    }
                }
                elsif (   $right->{OpCode}->isa('LoadConst') ) {
                    my $type = $right->{OpCode}->{TypeDef};
                    if    ($type eq 'TYPE_INTEGER') {
                        $parser->optIdtRightInteger($node, $left, $right);
                    }
                    elsif ($type eq 'TYPE_FLOAT') {
                        $parser->optIdtRightFloat($node, $left, $right);
                    }
                }
            }
            elsif ($opcode->isa('AddAsg')) {
                my $prev = $node->getPrevActive();
                croak "INTERNAL ERROR optEvalExpr\n"
                        unless (defined $prev);
                if ($prev->{OpCode}->isa('LoadConst')) {
                    if (       $prev->{OpCode}->{TypeDef} eq 'TYPE_INTEGER'
                            or $prev->{OpCode}->{TypeDef} eq 'TYPE_FLOAT' )  {
                        _optAddAsg($node,$prev);
                    }
                }
            }
            elsif ($opcode->isa('SubAsg')) {
                my $prev = $node->getPrevActive();
                croak "INTERNAL ERROR optEvalExpr\n"
                        unless (defined $prev);
                if ($prev->{OpCode}->isa('LoadConst')) {
                    if (       $prev->{OpCode}->{TypeDef} eq 'TYPE_INTEGER'
                            or $prev->{OpCode}->{TypeDef} eq 'TYPE_FLOAT' )  {
                        _optSubAsg($node, $prev);
                    }
                }
            }
        }
    }
    while ($OneMoreExpr);
    return $cnt > 1;
}

sub optLoadVarPop {
    my $parser = shift;
    my ($func) = @_;

    for (my $node = $func->getFirstActive(); defined $node; $node = $node->getNextActive()) {
        if ($node->{OpCode}->isa('LoadVar')) {
            my $next = $node->getNextActive();
            if (defined $next) {
                my $opcode = $next->{OpCode};
                if       ($opcode->isa('Pop')) {
                    $node->del();
                    $next->del();
                }
                elsif ( $opcode->isa('IncrVar') or $opcode->isa('DecrVar') ) {
                    $next = $next->getNextActive();
                    if (defined $next) {
                        if ($next->{OpCode}->isa('Pop')) {
                            $node->del();
                            $next->del();
                        }
                    }
                }
            }
        }
    }
    return;
}

sub optTobool {
    my $parser = shift;
    my ($func) = @_;

    for (my $node = $func->getFirstActive(); defined $node; $node = $node->getNextActive()) {
        if ($node->{OpCode}->isa('ToBool')) {
            my $next = $node->getNextActive();
            if (defined $next) {
                my $opcode = $next->{OpCode};
                if (       $opcode->isa('FalseJump')
                        or $opcode->isa('ScAnd')
                        or $opcode->isa('ScOr')
                        or $opcode->isa('ToBool')
                        or ($opcode->isa('UnaryOp') and $opcode->{Operator} eq '!') ) {
                    $node->del();
                }
            }
        }
    }
    return;
}

sub optUnopNot {
    my $parser = shift;
    my ($func) = @_;

    for (my $node = $func->getLastActive(); defined $node; $node = $node->getPrevActive()) {
        if ( $node->{OpCode}->isa('UnaryOp')
         and $node->{OpCode}->{Operator} eq '!' ) {
            my $prev = $node->getPrevActive();
            croak "INTERNAL ERROR optUnopNot\n"
                    unless (defined $prev);
            my $opcode = $prev->{OpCode};
            if    ($opcode->isa('BinaryOp')) {
                if    ($opcode->{Operator} eq '<') {
                    $opcode->{Operator} = '>=';
                    $node->del();
                    $OneMoreTime = 1;
                }
                elsif ($opcode->{Operator} eq '>') {
                    $opcode->{Operator} = '<=';
                    $node->del();
                    $OneMoreTime = 1;
                }
                elsif ($opcode->{Operator} eq '<=') {
                    $opcode->{Operator} = '>';
                    $node->del();
                    $OneMoreTime = 1;
                }
                elsif ($opcode->{Operator} eq '>=') {
                    $opcode->{Operator} = '<';
                    $node->del();
                    $OneMoreTime = 1;
                }
                elsif ($opcode->{Operator} eq '==') {
                    $opcode->{Operator} = '!=';
                    $node->del();
                    $OneMoreTime = 1;
                }
                elsif ($opcode->{Operator} eq '!=') {
                    $opcode->{Operator} = '==';
                    $node->del();
                    $OneMoreTime = 1;
                }
            }
            elsif ($opcode->isa('UnaryOp')) {
                if    ($opcode->{Operator} eq '!') {
                    bless($prev->{Opcode}, 'ToBool');
                    $node->del();
                    $OneMoreTime = 1;
                }
            }
        }
    }
    return;
}

sub optLabel {
    my $parser = shift;
    my ($func) = @_;

    for (my $node = $func->getFirstActive(); defined $node; $node = $node->getNextActive()) {
        if ($node->{OpCode}->isa('Label')) {
            if ($node->{OpCode}->{Definition}->{NbUse} == 0) {
                $node->del();
                $OneMoreTime = 1;
            }
        }
    }
    return;
}

sub optTestJump {
    my $parser = shift;
    my ($func) = @_;

    for (my $node = $func->getFirstActive(); defined $node; $node = $node->getNextActive()) {
        if ($node->{OpCode}->isa('FalseJump')) {
            my $prev = $node->getPrevActive();
            if (defined $prev and $prev->{OpCode}->isa('LoadConst')) {
                if ($prev->{OpCode}->{Value}) {
                    $parser->optInfo($node, "Condition always TRUE.\n");
                    $node->del();
                    $prev->del();
                    $node->{OpCode}->{Definition}->{NbUse} --;
                }
                else {
                    $parser->optInfo($node, "Condition always FALSE.\n");
                    bless($node->{OpCode}, 'Jump');
                    $prev->del();   # OK
                }
                $OneMoreTime = 1;
            }
        }
    }
    return;
}

sub optReJump {
    my $parser = shift;
    my ($func) = @_;

    for (my $node = $func->getFirstActive(); defined $node; $node = $node->getNextActive()) {
        my $opcode = $node->{OpCode};
        if ($opcode->isa('Jump') or $opcode->isa('FalseJump')) {
            my $label1 = $opcode->{Definition};
            my $dest = $label1->{Node}->getNextActive();
            if (defined $dest and $dest->{OpCode}->isa('Jump')) {
                my $label2 = $dest->{OpCode}->{Definition};
                $opcode->{Definition} = $label2;
                $label1->{NbUse} --;
                $label2->{NbUse} ++;
            }
        }
    }
    return;
}

sub optFalseJumpJump {
    my $parser = shift;
    my ($func) = @_;

    for (my $node = $func->getFirstActive(); defined $node; $node = $node->getNextActive()) {
        if ($node->{OpCode}->isa('FalseJump')) {
            my $next = $node->getNextActive();
            if (defined $next and $next->{OpCode}->isa('Jump')) {
                my $next2 = $next->getNextActive();
                if (        defined $next2
                        and $next2->{OpCode}->isa('Label')
                        and $node->{OpCode}->{Definition} == $next2->{OpCode}->{Definition} ) {
                    $node->{OpCode}->{Definition}->{NbUse} --;
                    bless($node->{OpCode}, 'UnaryOp');
                    $node->{OpCode}->{Operator} = '!';
                    bless($next->{OpCode}, 'FalseJump');
                    $parser->optDebug($node, "reverse FalseJump.\n");
                }
            }
        }
    }
    return;
}

sub optNullJump {
    my $parser = shift;
    my ($func) = @_;

    for (my $node = $func->getFirstActive(); defined $node; $node = $node->getNextActive()) {
        my $opcode = $node->{OpCode};
        if ($opcode->isa('Jump') or $opcode->isa('FalseJump')) {
            my $label = $opcode->{Definition};
            my $next = $node->getNextActive();
            if (        defined $next
                    and $next->{OpCode}->isa('Label')
                    and $label == $next->{OpCode}->{Definition} ) {
                if ($opcode->isa('Jump')) {
                    $node->del();
                    $parser->optDebug($node, "null Jump.\n");
                }
                else {  # FalseJump
                    bless($node->{OpCode}, 'Pop');
                    $OneMoreTime = 1;
                    $parser->optDebug($node, "null FalseJump.\n");
                }
            }
        }
    }
    return;
}

sub killVar {
    my $parser = shift;
    my ($func, $def) = @_;

    for (my $node = $func->getFirstActive(); defined $node; $node = $node->getNextActive()) {
        my $opcode = $node->{OpCode};
        if    ( $opcode->isa('StoreVar')
             or $opcode->isa('AddAsg')
             or $opcode->isa('SubAsg') ) {
                my $expr = $node->getPrevActive();
                croak "INTERNAL ERROR killVar\n"
                        unless (defined $expr);
                $expr->insert(new Pop($parser));
                $node->del();
        }
        elsif ( $opcode->isa('IncrVar')
             or $opcode->isa('DecrVar') ) {
            if ($def == $node->{OpCode}->{Definition}) {
                $node->del();
            }
        }
    }
    return;
}

sub killDeadExpr {
    my $parser = shift;
    my ($func) = @_;

    for (my $node = $func->getLastActive(); defined $node; $node = $node->getPrevActive()) {
        if ($node->{OpCode}->isa('Pop')) {
            my $prev = $node->getPrevActive();
            croak "INTERNAL ERROR killDeadExpr\n"
                    unless (defined $prev);
            my $opcode =$prev->{OpCode};
            if    ($opcode->isa('LoadConst')) {
                $prev->del();
                $node->del();
                $parser->optDebug($node, "del LOAD_CONST.\n");
            }
            elsif ($opcode->isa('LoadVar')) {
                $prev->del();
                $node->del();
                $OneMoreTime = 1;
                $parser->optDebug($node, "del LOAD_VAR.\n");
            }
            elsif ($opcode->isa('UnaryOp')) {
                my $expr = $prev->getPrevActive();
                croak "INTERNAL ERROR killDeadExpr (expr)\n"
                        unless (defined $expr);
                $expr->insert(new Pop($parser));
                $prev->del();
                $node->del();
                $parser->optDebug($node, "del UNOP.\n");
            }
            elsif ($opcode->isa('BinaryOp')) {
                my $left = $prev->{OpCode}->{Left};
                my $right = $prev->getPrevActive();
                croak "INTERNAL ERROR killDeadExpr (right)\n"
                        unless (defined $right);
                croak "INTERNAL ERROR killDeadExpr (left)\n"
                        unless (defined $left);
                $left->insert(new Pop($parser));
                $right->insert(new Pop($parser));
                $prev->del();
                $node->del();
                $parser->optDebug($node, "del BINOP.\n");
            }
        }
    }
    return;
}

sub killDeadCode {
    my $parser = shift;
    my ($func) = @_;

    for (my $node = $func->getFirstActive(); defined $node; $node = $node->getNextActive()) {
        if ( $node->{OpCode}->isa('Jump')
          or $node->{OpCode}->isa('Return')
          or $node->{OpCode}->isa('ReturnES') ) {
            my $first = 1;
            for (my $next = $node->getNextActive(); defined $next; $next = $next->getNextActive()) {
                my $opcode = $next->{OpCode};
                last if ($opcode->isa('Label') and $opcode->{Definition}->{Index} > 0);
                $next->del();
                if ($first) {
                    $first = 0;
                    $parser->optWarning($next, "Code unreachable.\n");
                }
            }
        }
    }
    return;
}

sub convVar2Const {
    my $parser = shift;
    my ($func, $def, $name, $cst) = @_;

    for (my $node = $func->getFirstActive(); defined $node; $node = $node->getNextActive()) {
        my $opcode = $node->{OpCode};
        if ($opcode->isa('LoadVar') and $def == $opcode->{Definition}) {
            $parser->optInfo($node, "Implemented by a constant - $name.\n");
            bless($node->{OpCode}, 'LoadConst');
            $opcode->{Value} = $cst->{Value};
            $opcode->{TypeDef} = $cst->{TypeDef};
        }
    }
    return;
}

sub optVar {
    my $parser = shift;
    my ($func) = @_;

    for (my $node = $func->getFirstActive(); defined $node; $node = $node->getNextActive()) {
        my $opcode = $node->{OpCode};
        if ( $opcode->isa('Argument')
          or $opcode->isa('LoadVar')
          or $opcode->isa('StoreVar')
          or $opcode->isa('IncrVar')
          or $opcode->isa('DecrVar')
          or $opcode->isa('AddAsg')
          or $opcode->isa('SubAsg') ) {
            $opcode->{Definition}->{Index} = 0;     # clear flag
        }
    }
    for (my $node = $func->getFirstActive(); defined $node; $node = $node->getNextActive()) {
        my $opcode = $node->{OpCode};
        if ( $opcode->isa('Argument')
          or $opcode->isa('LoadVar')
          or $opcode->isa('StoreVar')
          or $opcode->isa('IncrVar')
          or $opcode->isa('DecrVar')
          or $opcode->isa('AddAsg')
          or $opcode->isa('SubAsg') ) {
            my $def = $opcode->{Definition};
            if ($def->{Index} == 0 and $def->{NbUse} != 0) {
                my $load = undef;
                my $store = undef;
                my $nb_load = 0;
                my $nb_store = 0;
                my $nb_modif = 0;
                my $name = $def->{Symbol};
                $def->{Index} = 1;      # set flag
                for (my $next = $node; defined $next; $next = $next->getNextActive()) {
                    if      ($next->{OpCode}->isa('LoadVar')) {
                        if ($def == $next->{OpCode}->{Definition}) {
                            $nb_load ++;
                            $load = $next;
                        }
                    }
                    elsif   ($next->{OpCode}->isa('StoreVar')) {
                        if ($def == $next->{OpCode}->{Definition}) {
                            $nb_store ++;
                            $store = $next;
                        }
                    }
                    elsif (  $next->{OpCode}->isa('IncrVar')
                          or $next->{OpCode}->isa('DecrVar')
                          or $next->{OpCode}->isa('AddAsg')
                          or $next->{OpCode}->isa('SubAsg') ) {
                        if ($def == $next->{OpCode}->{Definition}) {
                            $nb_modif ++;
                        }
                    }
                }
#               print "var:",$name," nb_load:",$nb_load," nb_store:",$nb_store," nb_modif:",$nb_modif,"\n";
                if ($nb_load == 0) {
                    $parser->optWarning($node, "Unaccessed variable - $name.\n");
                    $parser->killVar($node, $def);
                }
                elsif ( ! $opcode->isa('Argument') and $nb_modif == 0 and $nb_store == 1) {
                    my $prev = $store->getPrevActive();
                    if ($prev->{OpCode}->isa('LoadConst')) {
                        $parser->convVar2Const($node, $def, $name, $prev->{OpCode});
                        $store->del();
                        $prev->del();
                    }
                    elsif ($nb_load == 1 and $store->getNextActive() == $load) {
                        $store->del();
                        $load->del();
                        $parser->optDebug($load, "store/load deleted - $name.\n");
                    }
                }
            }
        }
    }
    return;
}

sub Optimize {
    my $parser = shift;
    my ($OptExpr) = @_;
#   my $visitor = new WAP::wmls::printVisitor();

    for (my $node = $parser->YYData->{FunctionList}; defined $node; $node = $node->{Next}) {
        croak "INTERNAL ERROR in Optimize\n"
                unless ($node->{OpCode}->isa('Function'));
        my $func = $node->{OpCode}->{Value};
        next unless (defined $func);

        my $cnt = 0;
#       $func->visit($visitor);
        $parser->optLoadVarPop($func);
        do {
            $cnt ++;
#           print "optim $cnt\n";
            $OneMoreTime = 0;
            $parser->optTobool($func);
            $parser->optVar($func);
            $parser->killDeadExpr($func);
#           $func->visit($visitor);
            if ($OptExpr) {
                if ($parser->optEvalExpr($func)) {
                    $OneMoreTime = 1;
                }
            }
#           $func->visit($visitor);
            $parser->optTestJump($func);
            $parser->optReJump($func);
            $parser->killDeadCode($func);
            $parser->optFalseJumpJump($func);
            $parser->optNullJump($func);
            $parser->optLabel($func);
            $parser->optUnopNot($func);
#           $func->visit($visitor);
        }
        while ($OneMoreTime);
    }
    return;
}

1;

