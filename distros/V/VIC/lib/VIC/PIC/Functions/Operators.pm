package VIC::PIC::Functions::Operators;
use strict;
use warnings;
use bigint;
our $VERSION = '0.31';
$VERSION = eval $VERSION;
use Carp;
use POSIX ();
use Moo::Role;

sub _assign_literal {
    my ($self, $var, $val) = @_;
    return unless $self->doesrole('Chip'); # needed for address_bits
    if (ref $var eq 'HASH' and $var->{type} eq 'string') {
        #YYY { lhs => $var, rhs => $var };
        carp $var->{name}, " has been defined as a string and '$val' is not a string !";
        return;
    }
    my $bits = $self->address_bits($var);
    my $bytes = POSIX::ceil($bits / 8);
    my $nibbles = 2 * $bytes;
    $var = uc $var;
    my $code = sprintf "\t;; moves $val (0x%0${nibbles}X) to $var\n", $val;
    if ($val >= 2 ** $bits) {
        carp "Warning: Value $val doesn't fit in $bits-bits";
        $code .= "\t;; $val doesn't fit in $bits-bits. Using ";
        $val &= (2 ** $bits) - 1;
        $code .= sprintf "%d (0x%0${nibbles}X)\n", $val, $val;
    }
    if ($val == 0) {
        $code .= "\tclrf $var\n";
        for (2 .. $bytes) {
            $code .= sprintf "\tclrf $var + %d\n", ($_ - 1);
        }
    } else {
        my $valbyte = $val & ((2 ** 8) - 1);
        $code .= "\tbanksel $var\n";
        $code .= sprintf "\tmovlw 0x%02X\n\tmovwf $var\n", $valbyte if $valbyte > 0;
        $code .= "\tclrf $var\n" if $valbyte == 0;
        for (2 .. $bytes) {
            my $k = $_ * 8;
            my $i = $_ - 1;
            my $j = $i * 8;
            # get the right byte. 64-bit math requires bigint
            $valbyte = (($val & ((2 ** $k) - 1)) & (2 ** $k - 2 ** $j)) >> $j;
            $code .= sprintf "\tmovlw 0x%02X\n\tmovwf $var + $i\n", $valbyte if $valbyte > 0;
            $code .= "\tclrf $var + $i\n" if $valbyte == 0;
        }
    }
    return $code;
}

sub _op_assign_str_var {
    return <<"....";
;;;; for m_op_assign_str/m_op_nullify_str/m_op_concat_byte
VIC_VAR_ASSIGN_STRIDX res 1
VIC_VAR_ASSIGN_STRLEN res 1
....
}

sub _op_nullify_str {
    return << "...";
m_op_nullify_str macro dvar, dlen, didx
\tlocal _op_nullify_str_loop_0
\tlocal _op_nullify_str_loop_1
\tbanksel VIC_VAR_ASSIGN_STRLEN
\tmovlw dlen
\tmovwf VIC_VAR_ASSIGN_STRLEN
\tbanksel dvar
\tmovlw (dvar - 1)
\tmovwf FSR
\tbanksel VIC_VAR_ASSIGN_STRIDX
\tclrf VIC_VAR_ASSIGN_STRIDX
_op_nullify_str_loop_0:
\tclrw
\tincf FSR, F
\tmovwf INDF
\tbanksel VIC_VAR_ASSIGN_STRIDX
\tincf VIC_VAR_ASSIGN_STRIDX, F
\tbcf STATUS, Z
\tbcf STATUS, C
\tmovf VIC_VAR_ASSIGN_STRIDX, W
\tsubwf VIC_VAR_ASSIGN_STRLEN, W
\t;; W == 0
\tbtfsc STATUS, Z
\tgoto _op_nullify_str_loop_1
\tgoto _op_nullify_str_loop_0
_op_nullify_str_loop_1:
\tbanksel didx
\tclrf didx
\tendm
...
}

sub _op_assign_str {
    return <<"...";
m_op_assign_str macro dvar, dlen, cvar, clen
\tlocal _op_assign_str_loop_0
\tlocal _op_assign_str_loop_1
\tbanksel VIC_VAR_ASSIGN_STRLEN
if dlen > clen
\tmovlw clen
else
\tmovlw dlen
endif
\tmovwf VIC_VAR_ASSIGN_STRLEN
\tbanksel dvar
\tmovlw (dvar - 1)
\tmovwf FSR
\tbanksel VIC_VAR_ASSIGN_STRIDX
\tclrf VIC_VAR_ASSIGN_STRIDX
_op_assign_str_loop_0:
\tmovf VIC_VAR_ASSIGN_STRIDX, W
\tcall cvar
\tincf FSR, F
\tmovwf INDF
\tbanksel VIC_VAR_ASSIGN_STRIDX
\tincf VIC_VAR_ASSIGN_STRIDX, F
\tbcf STATUS, Z
\tbcf STATUS, C
\tmovf VIC_VAR_ASSIGN_STRIDX, W
\tsubwf VIC_VAR_ASSIGN_STRLEN, W
\t;; W == 0
\tbtfsc STATUS, Z
\tgoto _op_assign_str_loop_1
\tgoto _op_assign_str_loop_0
_op_assign_str_loop_1:
\tnop
\tendm
...
}

sub _get_idx_var {
    my ($self, $var) = @_;
    return uc ($var . '_IDX');
}

sub op_assign {
    my ($self, $var1, $var2, %extra) = @_;
    return unless $self->doesrole('Operators');
    my $literal = qr/^\d+$/;
    return $self->_assign_literal($var1, $var2) if $var2 =~ $literal;
    my $code = '';
    if (ref $var1 eq 'HASH') {
        if ($var1->{type} eq 'string') {
            if (ref $var2 eq 'HASH' && exists $var2->{string}) {
                # allocate the constant string into the variable location
                my $cvar = $var2->{name};# constant var location
                my $clen = sprintf "0x%02X", $var2->{size};# constant length definition
                my $dlen = $var1->{size};# destination length definition
                my $dvar = $var1->{name};
                my $macros = {};
                $macros->{m_op_assign_str} = $self->_op_assign_str;
                $macros->{m_op_assign_var} = $self->_op_assign_str_var;
                $macros->{m_op_nullify_str} = $self->_op_nullify_str;
                unless ($var2->{empty}) {
                    $code .= "\t;;;; moving contents of $cvar into $dvar with bounds checking\n";
                    $code .= "\tm_op_assign_str $dvar, $dlen, $cvar, $clen\n";
                } else {
                    $code .= "\t;;;; storing an empty string in $dvar\n";
                    my $idxvar = $self->_get_idx_var($dvar);
                    $code .= "\tm_op_nullify_str $dvar, $dlen, $idxvar\n";
                }
                return wantarray ? ($code, {}, $macros, []) : $code;
            } else {
                #YYY { lhs => $var1, rhs => $var2 };
                carp $var1->{name}, " has been defined as a string and '$var2' is not a string !";
                return;
            }
        }
    }
    my $b1 = POSIX::ceil($self->address_bits($var1) / 8);
    my $b2 = POSIX::ceil($self->address_bits($var2) / 8);
    $var2 = uc $var2;
    $var1 = uc $var1;
    $code = "\t;; moving $var2 to $var1\n";
    if ($b1 == $b2) {
        $code .= "\tmovf $var2, W\n\tmovwf $var1\n";
        for (2 .. $b1) {
            my $i = $_ - 1;
            $code .= "\tmovf $var2 + $i, W\n\tmovwf $var1 + $i\n";
        }
    } elsif ($b1 > $b2) {
        # we are moving a smaller var into a larger var
        $code .= "\t;; $var2 has a smaller size than $var1\n";
        $code .= "\tmovf $var2, W\n\tmovwf $var1\n";
        for (2 .. $b2) {
            my $i = $_ - 1;
            $code .= "\tmovf $var2 + $i, W\n\tmovwf $var1 + $i\n";
        }
        $code .= "\t;; we practice safe assignment here. zero out the rest\n";
        # we practice safe mathematics here. zero-out the rest of the place
        $b2++;
        for ($b2 .. $b1) {
            $code .= sprintf "\tclrf $var1 + %d\n", ($_ - 1);
        }
    } elsif ($b1 < $b2) {
        # we are moving a larger var into a smaller var
        $code .= "\t;; $var2 has a larger size than $var1. truncating..,\n";
        $code .= "\tmovf $var2, W\n\tmovwf $var1\n";
        for (2 .. $b1) {
            my $i = $_ - 1;
            $code .= "\tmovf $var2 + $i, W\n\tmovwf $var1 + $i\n";
        }
    } else {
        carp "Warning: should never reach here: $var1 is $b1 bytes and $var2 is $b2 bytes";
    }
    $code .= $self->op_assign_wreg($extra{RESULT}) if $extra{RESULT};
    return $code;
}

sub op_assign_wreg {
    my ($self, $var) = @_;
    return unless $self->doesrole('Operators');
    return unless $var;
    $var = uc $var;
    return "\tmovwf $var\n";
}

sub rol {
    my ($self, $var, $bits) = @_;
    return unless $self->doesroles(qw(Operators Chip));
    unless (exists $self->registers->{STATUS}) {
        carp "The STATUS register does not exist for the chip ", $self->type;
        return;
    }
    $var = uc $var;
    my $code = <<"...";
\tbcf STATUS, C
...
    for (1 .. $bits) {
        $code .= << "...";
\trlf $var, 1
\tbtfsc STATUS, C
\tbsf $var, 0
...
    }
    return $code;
}

sub ror {
    my ($self, $var, $bits) = @_;
    return unless $self->doesroles(qw(Operators Chip));
    unless (exists $self->registers->{STATUS}) {
        carp "The STATUS register does not exist for the chip ", $self->type;
        return;
    }
    $var = uc $var;
    my $code = <<"...";
\tbcf STATUS, C
...
    for (1 .. $bits) {
        $code .= << "...";
\trrf $var, 1
\tbtfsc STATUS, C
\tbsf $var, 7
...
    }
    return $code;
}

sub op_shl {
    my ($self, $var, $bits, %extra) = @_;
    return unless $self->doesroles(qw(Operators Chip));
    unless (exists $self->registers->{STATUS}) {
        carp "The STATUS register does not exist for the chip ", $self->type;
        return;
    }
    my $literal = qr/^\d+$/;
    my $code = '';
    if ($var !~ $literal and $bits =~ $literal) {
        $var = uc $var;
        $code .= "\t;;;; perform $var << $bits\n";
        if ($bits == 1) {
            $code .= << "...";
\tbcf STATUS, C
\trlf $var, W
\tbtfsc STATUS, C
\tbcf $var, 0
...
        } elsif ($bits == 0) {
            $code .= "\tmovf $var, W\n";
        } else {
            carp "Not implemented. use the 'shl' instruction\n";
            return;
        }
    } elsif ($var =~ $literal and $bits =~ $literal) {
        my $res = $var << $bits;
        $code .= "\t;;;; perform $var << $bits = $res\n";
        $code .= sprintf "\tmovlw 0x%02X\n", $res;
    } else {
        carp "Unable to handle $var << $bits";
        return;
    }
    $code .= $self->op_assign_wreg($extra{RESULT}) if $extra{RESULT};
    return $code;
}

sub op_shr {
    my ($self, $var, $bits, %extra) = @_;
    return unless $self->doesroles(qw(Operators Chip));
    unless (exists $self->registers->{STATUS}) {
        carp "The STATUS register does not exist for the chip ", $self->type;
        return;
    }
    my $literal = qr/^\d+$/;
    my $code = '';
    if ($var !~ $literal and $bits =~ $literal) {
        $var = uc $var;
        $code .= "\t;;;; perform $var >> $bits\n";
        if ($bits == 1) {
            $code .= << "...";
\tbcf STATUS, C
\trrf $var, W
\tbtfsc STATUS, C
\tbcf $var, 7
...
        } elsif ($bits == 0) {
            $code .= "\tmovf $var, W\n";
        } else {
            carp "Not implemented. use the 'shr' instruction\n";
            return;
        }
    } elsif ($var =~ $literal and $bits =~ $literal) {
        my $res = $var >> $bits;
        $code .= "\t;;;; perform $var >> $bits = $res\n";
        $code .= sprintf "\tmovlw 0x%02X\n", $res;
    } else {
        carp "Unable to handle $var >> $bits";
        return;
    }
    $code .= $self->op_assign_wreg($extra{RESULT}) if $extra{RESULT};
    return $code;
}

sub shl {
    my ($self, $var, $bits) = @_;
    return unless $self->doesroles(qw(Operators Chip));
    unless (exists $self->registers->{STATUS}) {
        carp "The STATUS register does not exist for the chip ", $self->type;
        return;
    }
    $var = uc $var;
    my $code = '';
    for (1 .. $bits) {
        $code .= << "...";
\trlf $var, 1
...
    }
    $code .= << "...";
\tbcf STATUS, C
...
}

sub shr {
    my ($self, $var, $bits) = @_;
    return unless $self->doesroles(qw(Operators Chip));
    unless (exists $self->registers->{STATUS}) {
        carp "The STATUS register does not exist for the chip ", $self->type;
        return;
    }
    $var = uc $var;
    my $code = '';
    for (1 .. $bits) {
        $code .= << "...";
\trrf $var, 1
...
    }
    $code .= << "...";
\tbcf STATUS, C
...
}

sub op_not {
    my $self = shift;
    my $var2 = shift;
    return unless $self->doesroles(qw(Operators Chip));
    unless (exists $self->registers->{STATUS}) {
        carp "The STATUS register does not exist for the chip ", $self->type;
        return;
    }
    my $pred = '';
    if (@_) {
        my ($dummy, %extra) = @_;
        $pred .= $self->op_assign_wreg($extra{RESULT}) if $extra{RESULT};
    }
    $var2 = uc $var2;
    return << "...";
\t;;;; generate code for !$var2
\tmovf $var2, W
\tbtfss STATUS, Z
\tgoto \$ + 3
\tmovlw 1
\tgoto \$ + 2
\tclrw
$pred
...
# used to be
#;;\tcomf $var2, W
#;;\tbtfsc STATUS, Z
#;;\tmovlw 1
}

sub op_comp {
    my $self = shift;
    my $var2 = shift;
    my $pred = '';
    if (@_) {
        my ($dummy, %extra) = @_;
        $pred .= $self->op_assign_wreg($extra{RESULT}) if $extra{RESULT};
    }
    $var2 = uc $var2;
    return << "...";
\t;;;; generate code for ~$var2
\tcomf $var2, W
$pred
...
}

sub op_add_assign_literal {
    my ($self, $var, $val, %extra) = @_;
    return unless $self->doesroles(qw(Operators Chip));
    unless (exists $self->registers->{STATUS}) {
        carp "The STATUS register does not exist for the chip ", $self->type;
        return;
    }
    my $b1 = POSIX::ceil($self->address_bits($var) / 8);
    $var = uc $var;
    my $nibbles = 2 * $b1;
    my $code = sprintf "\t;; $var = $var + 0x%0${nibbles}X\n", $val;
    return $code if $val == 0;
    # we expect b1 == 1,2,4,8
    my $b2 = 1 if $val < 2 ** 8;
    $b2 = 2 if ($val < 2 ** 16 and $val >= 2 ** 8);
    $b2 = 4 if ($val < 2 ** 32 and $val >= 2 ** 16);
    $b2 = 8 if ($val < 2 ** 64 and $val >= 2 ** 32);
    if ($b1 > $b2) {
    } elsif ($b1 < $b2) {

    } else {
        # $b1 == $b2
        my $valbyte = $val & ((2 ** 8) - 1);
        $code .= sprintf "\t;; add 0x%02X to byte[0]\n", $valbyte;
        $code .= sprintf "\tmovlw 0x%02X\n\taddwf $var, F\n", $valbyte if $valbyte > 0;
        $code .= sprintf "\tbcf STATUS, C\n" if $valbyte == 0;
        for (2 .. $b1) {
            my $k = $_ * 8;
            my $i = $_ - 1;
            my $j = $i * 8;
            # get the right byte. 64-bit math requires bigint
            $valbyte = (($val & ((2 ** $k) - 1)) & (2 ** $k - 2 ** $j)) >> $j;
            $code .= sprintf "\t;; add 0x%02X to byte[$i]\n", $valbyte;
            $code .= "\tbtfsc STATUS, C\n\tincf $var + $i, F\n";
            $code .= sprintf "\tmovlw 0x%02X\n\taddwf $var + $i, F\n", $valbyte if $valbyte > 0;
        }
    }
    $code .= $self->op_assign_wreg($extra{RESULT}) if $extra{RESULT};
    return $code;
}

## TODO: handle carry bit
sub op_add_assign {
    my ($self, $var, $var2, %extra) = @_;
    my $literal = qr/^\d+$/;
    return $self->op_add_assign_literal($var, $var2, %extra) if $var2 =~ $literal;
    $var = uc $var;
    $var2 = uc $var2;
    my $code = '';
    $code .= $self->op_assign_wreg($extra{RESULT}) if $extra{RESULT};
    return << "...";
\t;;moves $var2 to W
\tmovf $var2, W
\taddwf $var, F
$code
...
}

## TODO: handle carry bit
sub op_sub_assign {
    my ($self, $var, $var2) = @_;
    my ($code, $funcs, $macros) = $self->op_sub($var, $var2);
    $code .= $self->op_assign_wreg($var);
    return wantarray ? ($code, $funcs, $macros) : $code;
}

sub op_mul_assign {
    my ($self, $var, $var2) = @_;
    my ($code, $funcs, $macros) = $self->op_mul($var, $var2);
    $code .= $self->op_assign_wreg($var);
    return wantarray ? ($code, $funcs, $macros) : $code;
}

sub op_div_assign {
    my ($self, $var, $var2) = @_;
    my ($code, $funcs, $macros) = $self->op_div($var, $var2);
    $code .= $self->op_assign_wreg($var);
    return wantarray ? ($code, $funcs, $macros) : $code;
}

sub op_mod_assign {
    my ($self, $var, $var2) = @_;
    my ($code, $funcs, $macros) = $self->op_mod($var, $var2);
    $code .= $self->op_assign_wreg($var);
    return wantarray ? ($code, $funcs, $macros) : $code;
}

sub op_bxor_assign {
    my ($self, $var, $var2) = @_;
    my ($code, $funcs, $macros) = $self->op_bxor($var, $var2);
    $code .= $self->op_assign_wreg($var);
    return wantarray ? ($code, $funcs, $macros) : $code;
}

sub op_band_assign {
    my ($self, $var, $var2) = @_;
    my ($code, $funcs, $macros) = $self->op_band($var, $var2);
    $code .= $self->op_assign_wreg($var);
    return wantarray ? ($code, $funcs, $macros) : $code;
}

sub op_bor_assign {
    my ($self, $var, $var2) = @_;
    my ($code, $funcs, $macros) = $self->op_bor($var, $var2);
    $code .= $self->op_assign_wreg($var);
    return wantarray ? ($code, $funcs, $macros) : $code;
}

sub op_shl_assign {
    my ($self, $var, $var2) = @_;
    my ($code, $funcs, $macros) = $self->op_shl($var, $var2);
    $code .= $self->op_assign_wreg($var);
    return wantarray ? ($code, $funcs, $macros) : $code;
}

sub op_shr_assign {
    my ($self, $var, $var2) = @_;
    my ($code, $funcs, $macros) = $self->op_shr($var, $var2);
    $code .= $self->op_assign_wreg($var);
    return wantarray ? ($code, $funcs, $macros) : $code;
}

sub op_inc {
    my ($self, $var) = @_;
    return unless $self->doesroles(qw(Operators Chip));
    unless (exists $self->registers->{STATUS}) {
        carp "The STATUS register does not exist for the chip ", $self->type;
        return;
    }
    # we expect b1 == 1,2,4,8
    my $b1 = POSIX::ceil($self->address_bits($var) / 8);
    my $code = "\t;; increments $var in place\n";
    $code .= "\t;; increment byte[0]\n\tincf $var, F\n";
    for (2 .. $b1) {
        my $j = $_ - 1;
        my $i = $_ - 2;
        $code .= << "...";
\t;; increment byte[$j] iff byte[$i] == 0
\tbtfsc STATUS, Z
\tincf $var + $j, F
...
    }
    return $code;
}

sub op_dec {
    my ($self, $var) = @_;
    return unless $self->doesroles(qw(Operators Chip));
    unless (exists $self->registers->{STATUS}) {
        carp "The STATUS register does not exist for the chip ", $self->type;
        return;
    }
    my $b1 = POSIX::ceil($self->address_bits($var) / 8);
    my $code = "\t;; decrements $var in place\n";
    $code .= "\tmovf $var, W\n" if $b1 > 1;
    for (2 .. $b1) {
        my $i = $_ - 1;
        my $j = $i - 1;
        $code .= << "...";
\t;; decrement byte[$i] iff byte[$j] == 0
\tbtfsc STATUS, Z
\tdecf $var + $i, F
...
    }
    $code .= "\t;; decrement byte[0]\n\tdecf $var, F\n";
    return $code;
}

sub op_add {
    my ($self, $var1, $var2, %extra) = @_;
    return unless $self->doesrole('Chip');
    my $literal = qr/^\d+$/;
    my $code = '';
    #TODO: temporary only 8-bit math
    my ($b1, $b2);
    if ($var1 !~ $literal and $var2 !~ $literal) {
        $var1 = uc $var1;
        $var2 = uc $var2;
        $b1 = $self->address_bits($var1);
        $b2 = $self->address_bits($var2);
        # both are variables
        $code .= << "...";
\t;; add $var1 and $var2 without affecting either
\tmovf $var1, W
\taddwf $var2, W
...
    } elsif ($var1 =~ $literal and $var2 !~ $literal) {
        $var2 = uc $var2;
        $var1 = sprintf "0x%02X", $var1;
        $b2 = $self->address_bits($var2);
        # var1 is literal and var2 is variable
        # TODO: check for bits for var1
        $code .= << "...";
\t;; add $var1 and $var2 without affecting $var2
\tmovf  $var2, W
\taddlw $var1
...
    } elsif ($var1 !~ $literal and $var2 =~ $literal) {
        $var1 = uc $var1;
        $var2 = sprintf "0x%02X", $var2;
        # var2 is literal and var1 is variable
        $b1 = $self->address_bits($var1);
        # TODO: check for bits for var1
        $code .= << "...";
\t;; add $var2 and $var1 without affecting $var1
\tmovf $var1, W
\taddlw $var2
...
    } else {
        # both are literals
        # TODO: check for bits
        my $var3 = $var1 + $var2;
        $var3 = sprintf "0x%02X", $var3;
        $code .= << "...";
\t;; $var1 + $var2 = $var3
\tmovlw $var3
...
    }
    $code .= $self->op_assign_wreg($extra{RESULT}) if $extra{RESULT};
    return $code;
}

sub op_sub {
    my ($self, $var1, $var2, %extra) = @_;
    return unless $self->doesrole('Chip');
    my $literal = qr/^\d+$/;
    my $code = '';
    #TODO: temporary only 8-bit math
    my ($b1, $b2);
    if ($var1 !~ $literal and $var2 !~ $literal) {
        $var1 = uc $var1;
        $var2 = uc $var2;
        $b1 = $self->address_bits($var1);
        $b2 = $self->address_bits($var2);
        # both are variables
        $code .= << "...";
\t;; perform $var1 - $var2 without affecting either
\tmovf $var2, W
\tsubwf $var1, W
...
    } elsif ($var1 =~ $literal and $var2 !~ $literal) {
        $var2 = uc $var2;
        $var1 = sprintf "0x%02X", $var1;
        $b2 = $self->address_bits($var2);
        # var1 is literal and var2 is variable
        # TODO: check for bits for var1
        $code .= << "...";
\t;; perform $var1 - $var2 without affecting $var2
\tmovf $var2, W
\tsublw $var1
...
    } elsif ($var1 !~ $literal and $var2 =~ $literal) {
        $var1 = uc $var1;
        $var2 = sprintf "0x%02X", $var2;
        # var2 is literal and var1 is variable
        $b1 = $self->address_bits($var1);
        # TODO: check for bits for var1
        $code .= << "...";
\t;; perform $var1 - $var2 without affecting $var1
\tmovlw $var2
\tsubwf $var1, W
...
    } else {
        # both are literals
        # TODO: check for bits
        my $var3 = $var1 - $var2;
        $var3 = sprintf "0x%02X", $var3;
        $code .= << "...";
\t;; $var1 - $var2 = $var3
\tmovlw $var3
...
    }
    $code .= $self->op_assign_wreg($extra{RESULT}) if $extra{RESULT};
    return $code;
}

sub _macro_multiply_var {
    # TODO: do more than 8 bits
    return << "...";
;;;;;; VIC_VAR_MULTIPLY VARIABLES ;;;;;;;

VIC_VAR_MULTIPLY_UDATA udata
VIC_VAR_MULTIPLICAND res 2
VIC_VAR_MULTIPLIER res 2
VIC_VAR_PRODUCT res 2
...
}

sub _macro_multiply_macro {
    return << "...";
;;;;;; Taken from Microchip PIC examples.
;;;;;; multiply v1 and v2 using shifting. multiplication of 8-bit values is done
;;;;;; using 16-bit variables. v1 is a variable and v2 is a constant
m_multiply_internal macro
    local _m_multiply_loop_0, _m_multiply_skip
    clrf VIC_VAR_PRODUCT
    clrf VIC_VAR_PRODUCT + 1
_m_multiply_loop_0:
    rrf VIC_VAR_MULTIPLICAND, F
    btfss STATUS, C
    goto _m_multiply_skip
    movf VIC_VAR_MULTIPLIER + 1, W
    addwf VIC_VAR_PRODUCT + 1, F
    movf VIC_VAR_MULTIPLIER, W
    addwf VIC_VAR_PRODUCT, F
    btfsc STATUS, C
    incf VIC_VAR_PRODUCT + 1, F
_m_multiply_skip:
    bcf STATUS, C
    rlf VIC_VAR_MULTIPLIER, F
    rlf VIC_VAR_MULTIPLIER + 1, F
    movf VIC_VAR_MULTIPLICAND, F
    btfss STATUS, Z
    goto _m_multiply_loop_0
    movf VIC_VAR_PRODUCT, W
    endm
;;;;;;; v1 is variable and v2 is literal
m_multiply_1 macro v1, v2
    movf v1, W
    movwf VIC_VAR_MULTIPLIER
    clrf VIC_VAR_MULTIPLIER + 1
    movlw v2
    movwf VIC_VAR_MULTIPLICAND
    clrf VIC_VAR_MULTIPLICAND + 1
    m_multiply_internal
    endm
;;;;;; multiply v1 and v2 using shifting. multiplication of 8-bit values is done
;;;;;; using 16-bit variables. v1 and v2 are variables
m_multiply_2 macro v1, v2
    movf v1, W
    movwf VIC_VAR_MULTIPLIER
    clrf VIC_VAR_MULTIPLIER + 1
    movf v2, W
    movwf VIC_VAR_MULTIPLICAND
    clrf VIC_VAR_MULTIPLICAND + 1
    m_multiply_internal
    endm
...
}

sub op_mul {
    my ($self, $var1, $var2, %extra) = @_;
    my $literal = qr/^\d+$/;
    my $code = '';
    #TODO: temporary only 8-bit math
    my ($b1, $b2);
    if ($var1 !~ $literal and $var2 !~ $literal) {
        $var1 = uc $var1;
        $var2 = uc $var2;
        $b1 = $self->address_bits($var1);
        $b2 = $self->address_bits($var2);
        # both are variables
        $code .= << "...";
\t;; perform $var1 * $var2 without affecting either
\tm_multiply_2 $var1, $var2
...
    } elsif ($var1 =~ $literal and $var2 !~ $literal) {
        $var2 = uc $var2;
        $var1 = sprintf "0x%02X", $var1;
        $b2 = $self->address_bits($var2);
        # var1 is literal and var2 is variable
        # TODO: check for bits for var1
        $code .= << "...";
\t;; perform $var1 * $var2 without affecting $var2
\tm_multiply_1 $var2, $var1
...
    } elsif ($var1 !~ $literal and $var2 =~ $literal) {
        $var1 = uc $var1;
        $var2 = sprintf "0x%02X", $var2;
        # var2 is literal and var1 is variable
        $b1 = $self->address_bits($var1);
        # TODO: check for bits for var1
        $code .= << "...";
\t;; perform $var1 * $var2 without affecting $var1
\tm_multiply_1 $var1, $var2
...
    } else {
        # both are literals
        # TODO: check for bits
        my $var3 = $var1 * $var2;
        $var3 = sprintf "0x%02X", $var3;
        $code .= << "...";
\t;; $var1 * $var2 = $var3
\tmovlw $var3
...
    }
    my $macros = {
        m_multiply_var => $self->_macro_multiply_var,
        m_multiply_macro => $self->_macro_multiply_macro,
    };
    $code .= $self->op_assign_wreg($extra{RESULT}) if $extra{RESULT};
    return wantarray ? ($code, {}, $macros) : $code;
}

sub _macro_divide_var {
    # TODO: do more than 8 bits
    return << "...";
;;;;;; VIC_VAR_DIVIDE VARIABLES ;;;;;;;

VIC_VAR_DIVIDE_UDATA udata
VIC_VAR_DIVISOR res 2
VIC_VAR_REMAINDER res 2
VIC_VAR_QUOTIENT res 2
VIC_VAR_BITSHIFT res 2
VIC_VAR_DIVTEMP res 1
...
}

sub _macro_divide_macro {
    return << "...";
;;;;;; Taken from Microchip PIC examples.
m_divide_internal macro
    local _m_divide_shiftuploop, _m_divide_loop, _m_divide_shift
    clrf VIC_VAR_QUOTIENT
    clrf VIC_VAR_QUOTIENT + 1
    clrf VIC_VAR_BITSHIFT + 1
    movlw 0x01
    movwf VIC_VAR_BITSHIFT
_m_divide_shiftuploop:
    bcf STATUS, C
    rlf VIC_VAR_DIVISOR, F
    rlf VIC_VAR_DIVISOR + 1, F
    bcf STATUS, C
    rlf VIC_VAR_BITSHIFT, F
    rlf VIC_VAR_BITSHIFT + 1, F
    btfss VIC_VAR_DIVISOR + 1, 7
    goto _m_divide_shiftuploop
_m_divide_loop:
    movf VIC_VAR_DIVISOR, W
    subwf VIC_VAR_REMAINDER, W
    movwf VIC_VAR_DIVTEMP
    movf VIC_VAR_DIVISOR + 1, W
    btfss STATUS, C
    addlw 0x01
    subwf VIC_VAR_REMAINDER + 1, W
    btfss STATUS, C
    goto _m_divide_shift
    movwf VIC_VAR_REMAINDER + 1
    movf VIC_VAR_DIVTEMP, W
    movwf VIC_VAR_REMAINDER
    movf VIC_VAR_BITSHIFT + 1, W
    addwf VIC_VAR_QUOTIENT + 1, F
    movf VIC_VAR_BITSHIFT, W
    addwf VIC_VAR_QUOTIENT, F
_m_divide_shift:
    bcf STATUS, C
    rrf VIC_VAR_DIVISOR + 1, F
    rrf VIC_VAR_DIVISOR, F
    bcf STATUS, C
    rrf VIC_VAR_BITSHIFT + 1, F
    rrf VIC_VAR_BITSHIFT, F
    btfss STATUS, C
    goto _m_divide_loop
    endm
;;;;;; v1 and v2 are variables
m_divide_2 macro v1, v2
    movf v1, W
    movwf VIC_VAR_REMAINDER
    clrf VIC_VAR_REMAINDER + 1
    movf v2, W
    movwf VIC_VAR_DIVISOR
    clrf VIC_VAR_DIVISOR + 1
    m_divide_internal
    movf VIC_VAR_QUOTIENT, W
    endm
;;;;;; v1 is literal and v2 is variable
m_divide_1a macro v1, v2
    movlw v1
    movwf VIC_VAR_REMAINDER
    clrf VIC_VAR_REMAINDER + 1
    movf v2, W
    movwf VIC_VAR_DIVISOR
    clrf VIC_VAR_DIVISOR + 1
    m_divide_internal
    movf VIC_VAR_QUOTIENT, W
    endm
;;;;;;; v2 is literal and v1 is variable
m_divide_1b macro v1, v2
    movf v1, W
    movwf VIC_VAR_REMAINDER
    clrf VIC_VAR_REMAINDER + 1
    movlw v2
    movwf VIC_VAR_DIVISOR
    clrf VIC_VAR_DIVISOR + 1
    m_divide_internal
    movf VIC_VAR_QUOTIENT, W
    endm
m_mod_2 macro v1, v2
    m_divide_2 v1, v2
    movf VIC_VAR_REMAINDER, W
    endm
;;;;;; v1 is literal and v2 is variable
m_mod_1a macro v1, v2
    m_divide_1a v1, v2
    movf VIC_VAR_REMAINDER, W
    endm
;;;;;;; v2 is literal and v1 is variable
m_mod_1b macro v1, v2
    m_divide_1b v1, v2
    movf VIC_VAR_REMAINDER, W
    endm
...
}

sub op_div {
    my ($self, $var1, $var2, %extra) = @_;
    my $literal = qr/^\d+$/;
    my $code = '';
    #TODO: temporary only 8-bit math
    my ($b1, $b2);
    if ($var1 !~ $literal and $var2 !~ $literal) {
        $var1 = uc $var1;
        $var2 = uc $var2;
        $b1 = $self->address_bits($var1);
        $b2 = $self->address_bits($var2);
        # both are variables
        $code .= << "...";
\t;; perform $var1 / $var2 without affecting either
\tm_divide_2 $var1, $var2
...
    } elsif ($var1 =~ $literal and $var2 !~ $literal) {
        $var2 = uc $var2;
        $var1 = sprintf "0x%02X", $var1;
        $b2 = $self->address_bits($var2);
        # var1 is literal and var2 is variable
        # TODO: check for bits for var1
        $code .= << "...";
\t;; perform $var1 / $var2 without affecting $var2
\tm_divide_1a $var1, $var2
...
    } elsif ($var1 !~ $literal and $var2 =~ $literal) {
        $var1 = uc $var1;
        $var2 = sprintf "0x%02X", $var2;
        # var2 is literal and var1 is variable
        $b1 = $self->address_bits($var1);
        # TODO: check for bits for var1
        $code .= << "...";
\t;; perform $var1 / $var2 without affecting $var1
\tm_divide_1b $var1, $var2
...
    } else {
        # both are literals
        # TODO: check for bits
        my $var3 = int($var1 / $var2);
        $var3 = sprintf "0x%02X", $var3;
        $code .= << "...";
\t;; $var1 / $var2 = $var3
\tmovlw $var3
...
    }
    my $macros = {
        m_divide_var => $self->_macro_divide_var,
        m_divide_macro => $self->_macro_divide_macro,
    };
    $code .= $self->op_assign_wreg($extra{RESULT}) if $extra{RESULT};
    return wantarray ? ($code, {}, $macros) : $code;
}

sub op_mod {
    my ($self, $var1, $var2, %extra) = @_;
    my $literal = qr/^\d+$/;
    my $code = '';
    #TODO: temporary only 8-bit math
    my ($b1, $b2);
    if ($var1 !~ $literal and $var2 !~ $literal) {
        $var1 = uc $var1;
        $var2 = uc $var2;
        $b1 = $self->address_bits($var1);
        $b2 = $self->address_bits($var2);
        # both are variables
        $code .= << "...";
\t;; perform $var1 / $var2 without affecting either
\tm_mod_2 $var1, $var2
...
    } elsif ($var1 =~ $literal and $var2 !~ $literal) {
        $var2 = uc $var2;
        $var1 = sprintf "0x%02X", $var1;
        $b2 = $self->address_bits($var2);
        # var1 is literal and var2 is variable
        # TODO: check for bits for var1
        $code .= << "...";
\t;; perform $var1 / $var2 without affecting $var2
\tm_mod_1a $var1, $var2
...
    } elsif ($var1 !~ $literal and $var2 =~ $literal) {
        $var1 = uc $var1;
        $var2 = sprintf "0x%02X", $var2;
        # var2 is literal and var1 is variable
        $b1 = $self->address_bits($var1);
        # TODO: check for bits for var1
        $code .= << "...";
\t;; perform $var1 / $var2 without affecting $var1
\tm_mod_1b $var1, $var2
...
    } else {
        # both are literals
        # TODO: check for bits
        my $var3 = int($var1 % $var2);
        $var3 = sprintf "0x%02X", $var3;
        $code .= << "...";
\t;; $var1 / $var2 = $var3
\tmovlw $var3
...
    }
    my $macros = {
        m_divide_var => $self->_macro_divide_var,
        m_divide_macro => $self->_macro_divide_macro,
    };
    $code .= $self->op_assign_wreg($extra{RESULT}) if $extra{RESULT};
    return wantarray ? ($code, {}, $macros) : $code;
}

sub op_bxor {
    my ($self, $var1, $var2, %extra) = @_;
    my $literal = qr/^\d+$/;
    my $code = '';
    $code .= $self->op_assign_wreg($extra{RESULT}) if $extra{RESULT};
    if ($var1 !~ $literal and $var2 !~ $literal) {
        $var1 = uc $var1;
        $var2 = uc $var2;
        return << "...";
\t;; perform $var1 ^ $var2 and move into W
\tmovf $var1, W
\txorwf $var2, W
$code
...
    } elsif ($var1 !~ $literal and $var2 =~ $literal) {
        $var1 = uc $var1;
        $var2 = sprintf "0x%02X", $var2;
        return << "...";
\t;; perform $var1 ^ $var2 and move into W
\tmovlw $var2
\txorwf $var1, W
$code
...
    } elsif ($var1 =~ $literal and $var2 !~ $literal) {
        $var2 = uc $var2;
        $var1 = sprintf "0x%02X", $var1;
        return << "...";
\t;; perform $var1 ^ $var2 and move into W
\tmovlw $var1
\txorwf $var2, W
$code
...
    } else {
        my $var3 = $var1 ^ $var2;
        $var3 = sprintf "0x%02X", $var3;
        return << "...";
\t;; $var3 = $var1 ^ $var2. move into W
\tmovlw $var3
$code
...
    }
}

sub op_band {
    my ($self, $var1, $var2, %extra) = @_;
    my $literal = qr/^\d+$/;
    my $code = '';
    $code .= $self->op_assign_wreg($extra{RESULT}) if $extra{RESULT};
    if ($var1 !~ $literal and $var2 !~ $literal) {
        $var1 = uc $var1;
        $var2 = uc $var2;
        return << "...";
\t;; perform $var1 & $var2 and move into W
\tmovf $var1, W
\tandwf $var2, W
$code
...
    } elsif ($var1 !~ $literal and $var2 =~ $literal) {
        $var1 = uc $var1;
        $var2 = sprintf "0x%02X", $var2;
        return << "...";
\t;; perform $var1 & $var2 and move into W
\tmovlw $var2
\tandwf $var1, W
$code
...
    } elsif ($var1 =~ $literal and $var2 !~ $literal) {
        $var2 = uc $var2;
        $var1 = sprintf "0x%02X", $var1;
        return << "...";
\t;; perform $var1 & $var2 and move into W
\tmovlw $var1
\tandwf $var2, W
$code
...
    } else {
        my $var3 = $var2 & $var1;
        $var3 = sprintf "0x%02X", $var3;
        return << "...";
\t;; $var3 = $var1 & $var2. move into W
\tmovlw $var3
$code
...
    }
}

sub op_bor {
    my ($self, $var1, $var2, %extra) = @_;
    my $literal = qr/^\d+$/;
    my $code = '';
    $code .= $self->op_assign_wreg($extra{RESULT}) if $extra{RESULT};
    if ($var1 !~ $literal and $var2 !~ $literal) {
        $var1 = uc $var1;
        $var2 = uc $var2;
        return << "...";
\t;; perform $var1 | $var2 and move into W
\tmovf $var1, W
\tiorwf $var2, W
$code
...
    } elsif ($var1 !~ $literal and $var2 =~ $literal) {
        $var1 = uc $var1;
        $var2 = sprintf "0x%02X", $var2;
        return << "...";
\t;; perform $var1 | $var2 and move into W
\tmovlw $var2
\tiorwf $var1, W
$code
...
    } elsif ($var1 =~ $literal and $var2 !~ $literal) {
        $var2 = uc $var2;
        $var1 = sprintf "0x%02X", $var1;
        return << "...";
\t;; perform $var1 | $var2 and move into W
\tmovlw $var1
\tiorwf $var2, W
$code
...
    } else {
        my $var3 = $var1 | $var2;
        $var3 = sprintf "0x%02X", $var3;
        return << "...";
\t;; $var3 = $var1 | $var2. move into W
\tmovlw $var3
$code
...
    }
}

sub _get_predicate {
    my ($self, $comment, %extra) = @_;
    my $pred = '';
    my %labels = ();
    ## predicate can be either a result or a jump block
    unless (defined $extra{RESULT}) {
        my $flabel = $extra{SWAP} ? $extra{TRUE} : $extra{FALSE};
        my $tlabel = $extra{SWAP} ? $extra{FALSE} : $extra{TRUE};
        my $elabel = $extra{END};
        $labels{TRUE} = $tlabel;
        $labels{FALSE} = $flabel;
        $labels{END} = $elabel;
        $pred .= << "..."
;; $comment
\tgoto $flabel
\tgoto $tlabel
$elabel:
...
    } else {
        my $flabel = $extra{SWAP} ? "$extra{END}_t_$extra{COUNTER}" :
                        "$extra{END}_f_$extra{COUNTER}";
        my $tlabel = $extra{SWAP} ? "$extra{END}_f_$extra{COUNTER}" :
                        "$extra{END}_t_$extra{COUNTER}";
        my $elabel = "$extra{END}_e_$extra{COUNTER}";
        $labels{TRUE} = $tlabel;
        $labels{FALSE} = $flabel;
        $labels{END} = $elabel;
        $pred .=  << "...";
;; $comment
\tgoto $flabel
\tgoto $tlabel
$flabel:
\tclrw
\tgoto $elabel
$tlabel:
\tmovlw 0x01
$elabel:
...
        $pred .= $self->op_assign_wreg($extra{RESULT});
    }
    return wantarray ? ($pred, %labels) : $pred;
}

sub _get_predicate_literals {
    my ($self, $comment, $res, %extra) = @_;
    if (defined $extra{RESULT}) {
        my $tcode = 'movlw 0x01';
        my $fcode = 'clrw';
        my $code;
        if ($res) {
            $code = $extra{SWAP} ? $fcode : $tcode;
        } else {
            $code = $extra{SWAP} ? $tcode : $fcode;
        }
        my $ecode = $self->op_assign_wreg($extra{RESULT});
        return "\t$code ;;$comment\n$ecode\n";
    } else {
        my $label;
        if ($res) {
            $label = $extra{SWAP} ? $extra{FALSE} : $extra{TRUE};
        } else {
            $label = $extra{SWAP} ? $extra{TRUE} : $extra{FALSE};
        }
        return "\tgoto $label ;; $comment\n$extra{END}:\n";
    }
}

sub op_eq {
    my ($self, $lhs, $rhs, %extra) = @_;
    return unless $self->doesroles(qw(Operators Chip));
    unless (exists $self->registers->{STATUS}) {
        carp "The STATUS register does not exist for the chip ", $self->type;
        return;
    }
    my $comment = $extra{SWAP} ? "$lhs != $rhs" : "$lhs == $rhs";
    my $pred = $self->_get_predicate($comment, %extra);
    my $literal = qr/^\d+$/;
    if ($lhs !~ $literal and $rhs !~ $literal) {
        # lhs and rhs are variables
        $rhs = uc $rhs;
        $lhs = uc $lhs;
        return << "...";
\tbcf STATUS, Z
\tmovf $rhs, W
\txorwf $lhs, W
\tbtfss STATUS, Z
$pred
...
    } elsif ($rhs !~ $literal and $lhs =~ $literal) {
        # rhs is variable and lhs is a literal
        $rhs = uc $rhs;
        $lhs = sprintf "0x%02X", $lhs;
        return << "...";
\tbcf STATUS, Z
\tmovf $rhs, W
\txorlw $lhs
\tbtfss STATUS, Z ;; $comment
$pred
...
    } elsif ($rhs =~ $literal and $lhs !~ $literal) {
        # rhs is a literal and lhs is a variable
        $lhs = uc $lhs;
        $rhs = sprintf "0x%02X", $rhs;
        return << "...";
\tbcf STATUS, Z
\tmovf $lhs, W
\txorlw $rhs
\tbtfss STATUS, Z ;; $comment
$pred
...
    } else {
        # both rhs and lhs are literals
        my $res = $lhs == $rhs ? 1 : 0;
        return $self->_get_predicate_literals("$lhs == $rhs => $res", $res, %extra);
    }
}

sub op_lt {
    my ($self, $lhs, $rhs, %extra) = @_;
    return unless $self->doesroles(qw(Operators Chip));
    unless (exists $self->registers->{STATUS}) {
        carp "The STATUS register does not exist for the chip ", $self->type;
        return;
    }
    my $pred = $self->_get_predicate("$lhs < $rhs", %extra);
    my $literal = qr/^\d+$/;
    if ($lhs !~ $literal and $rhs !~ $literal) {
        # lhs and rhs are variables
        $rhs = uc $rhs;
        $lhs = uc $lhs;
        return << "...";
\t;; perform check for $lhs < $rhs or $rhs > $lhs
\tbcf STATUS, C
\tmovf $rhs, W
\tsubwf $lhs, W
\tbtfsc STATUS, C ;; W($rhs) > F($lhs) => C = 0
$pred
...
    } elsif ($rhs !~ $literal and $lhs =~ $literal) {
        # rhs is variable and lhs is a literal
        $rhs = uc $rhs;
        $lhs = sprintf "0x%02X", $lhs;
        return << "...";
\t;; perform check for $lhs < $rhs or $rhs > $lhs
\tbcf STATUS, C
\tmovf $rhs, W
\tsublw $lhs
\tbtfsc STATUS, C ;; W($rhs) > k($lhs) => C = 0
$pred
...
    } elsif ($rhs =~ $literal and $lhs !~ $literal) {
        # rhs is a literal and lhs is a variable
        $lhs = uc $lhs;
        $rhs = sprintf "0x%02X", $rhs;
        return << "...";
\t;; perform check for $lhs < $rhs or $rhs > $lhs
\tbcf STATUS, C
\tmovlw $rhs
\tsubwf $lhs, W
\tbtfsc STATUS, C ;; W($rhs) > F($lhs) => C = 0
$pred
...
    } else {
        # both rhs and lhs are literals
        my $res = $lhs < $rhs ? 1 : 0;
        return $self->_get_predicate_literals("$lhs < $rhs => $res", $res, %extra);
    }
}

sub op_ge {
    my ($self, $lhs, $rhs, %extra) = @_;
    return unless $self->doesroles(qw(Operators Chip));
    unless (exists $self->registers->{STATUS}) {
        carp "The STATUS register does not exist for the chip ", $self->type;
        return;
    }
    my $pred = $self->_get_predicate("$lhs >= $rhs", %extra);
    my $literal = qr/^\d+$/;
    if ($lhs !~ $literal and $rhs !~ $literal) {
        # lhs and rhs are variables
        $rhs = uc $rhs;
        $lhs = uc $lhs;
        return << "...";
\t;; perform check for $lhs >= $rhs or $rhs <= $lhs
\tbcf STATUS, C
\tmovf $rhs, W
\tsubwf $lhs, W
\tbtfss STATUS, C ;; W($rhs) <= F($lhs) => C = 1
$pred
...
    } elsif ($rhs !~ $literal and $lhs =~ $literal) {
        # rhs is variable and lhs is a literal
        $rhs = uc $rhs;
        $lhs = sprintf "0x%02X", $lhs;
        return << "...";
\t;; perform check for $lhs >= $rhs or $rhs <= $lhs
\tbcf STATUS, C
\tmovf $rhs, W
\tsublw $lhs
\tbtfss STATUS, C ;; W($rhs) <= k($lhs) => C = 1
$pred
...
    } elsif ($rhs =~ $literal and $lhs !~ $literal) {
        # rhs is a literal and lhs is a variable
        $lhs = uc $lhs;
        $rhs = sprintf "0x%02X", $rhs;
        return << "...";
\t;; perform check for $lhs >= $rhs or $rhs <= $lhs
\tbcf STATUS, C
\tmovlw $rhs
\tsubwf $lhs, W
\tbtfss STATUS, C ;; W($rhs) <= F($lhs) => C = 1
$pred
...
    } else {
        # both rhs and lhs are literals
        my $res = $lhs >= $rhs ? 1 : 0;
        return $self->_get_predicate_literals("$lhs >= $rhs => $res", $res, %extra);
    }
}

sub op_ne {
    my ($self, $lhs, $rhs, %extra) = @_;
    return $self->op_eq($lhs, $rhs, %extra, SWAP => 1);
}

sub op_le {
    my ($self, $lhs, $rhs, %extra) = @_;
    # we swap the lhs/rhs stuff instead of using SWAP
    return $self->op_ge($rhs, $lhs, %extra);
}

sub op_gt {
    my ($self, $lhs, $rhs, %extra) = @_;
    # we swap the lhs/rhs stuff instead of using SWAP
    return $self->op_lt($rhs, $lhs, %extra);
}

sub op_and {
    my ($self, $lhs, $rhs, %extra) = @_;
    return unless $self->doesroles(qw(Operators Chip));
    unless (exists $self->registers->{STATUS}) {
        carp "The STATUS register does not exist for the chip ", $self->type;
        return;
    }
    my ($pred, %labels) = $self->_get_predicate("$lhs && $rhs", %extra);
    my $literal = qr/^\d+$/;
    if ($lhs !~ $literal and $rhs !~ $literal) {
        # lhs and rhs are variables
        $rhs = uc $rhs;
        $lhs = uc $lhs;
        return << "...";
\t;; perform check for $lhs && $rhs
\tbcf STATUS, Z
\tmovf $lhs, W
\tbtfss STATUS, Z  ;; $lhs is false if it is set else true
\tgoto $labels{FALSE}
\tmovf $rhs, W
\tbtfss STATUS, Z ;; $rhs is false if it is set else true
$pred
...
    } elsif ($rhs !~ $literal and $lhs =~ $literal) {
        # rhs is variable and lhs is a literal
        $rhs = uc $rhs;
        $lhs = sprintf "0x%02X", $lhs;
        return << "...";
\t;; perform check for $lhs && $rhs
\tbcf STATUS, Z
\tmovlw $lhs
\txorlw 0x00        ;; $lhs ^ 0 will set the Z bit
\tbtfss STATUS, Z  ;; $lhs is false if it is set else true
\tgoto $labels{FALSE}
\tmovf $rhs, W
\tbtfss STATUS, Z ;; $rhs is false if it is set else true
$pred
...
    } elsif ($rhs =~ $literal and $lhs !~ $literal) {
        # rhs is a literal and lhs is a variable
        $lhs = uc $lhs;
        $rhs = sprintf "0x%02X", $rhs;
        return << "...";
\t;; perform check for $lhs && $rhs
\tbcf STATUS, Z
\tmovlw $rhs
\txorlw 0x00        ;; $rhs ^ 0 will set the Z bit
\tbtfss STATUS, Z  ;; $rhs is false if it is set else true
\tgoto $labels{FALSE}
\tmovf $lhs, W
\tbtfss STATUS, Z ;; $lhs is false if it is set else true
$pred
...
    } else {
        # both rhs and lhs are literals
        my $res = ($lhs && $rhs) ? 1 : 0;
        return $self->_get_predicate_literals("$lhs && $rhs => $res", $res, %extra);
    }
}

sub op_or {
    my ($self, $lhs, $rhs, %extra) = @_;
    return unless $self->doesroles(qw(Operators Chip));
    unless (exists $self->registers->{STATUS}) {
        carp "The STATUS register does not exist for the chip ", $self->type;
        return;
    }
    my ($pred, %labels) = $self->_get_predicate("$lhs || $rhs", %extra);
    my $literal = qr/^\d+$/;
    if ($lhs !~ $literal and $rhs !~ $literal) {
        # lhs and rhs are variables
        $rhs = uc $rhs;
        $lhs = uc $lhs;
        return << "...";
\t;; perform check for $lhs || $rhs
\tbcf STATUS, Z
\tmovf $lhs, W
\tbtfss STATUS, Z  ;; $lhs is false if it is set else true
\tgoto $labels{TRUE}
\tmovf $rhs, W
\tbtfsc STATUS, Z ;; $rhs is false if it is set else true
$pred
...
    } elsif ($rhs !~ $literal and $lhs =~ $literal) {
        # rhs is variable and lhs is a literal
        $rhs = uc $rhs;
        $lhs = sprintf "0x%02X", $lhs;
        return << "...";
\t;; perform check for $lhs || $rhs
\tbcf STATUS, Z
\tmovlw $lhs
\txorlw 0x00        ;; $lhs ^ 0 will set the Z bit
\tbtfss STATUS, Z  ;; $lhs is false if it is set else true
\tgoto $labels{TRUE}
\tmovf $rhs, W
\tbtfsc STATUS, Z ;; $rhs is false if it is set else true
$pred
...
    } elsif ($rhs =~ $literal and $lhs !~ $literal) {
        # rhs is a literal and lhs is a variable
        $lhs = uc $lhs;
        $rhs = sprintf "0x%02X", $rhs;
        return << "...";
\t;; perform check for $lhs || $rhs
\tbcf STATUS, Z
\tmovlw $rhs
\txorlw 0x00        ;; $rhs ^ 0 will set the Z bit
\tbtfss STATUS, Z  ;; $rhs is false if it is set else true
\tgoto $labels{TRUE}
\tmovf $lhs, W
\tbtfsc STATUS, Z ;; $lhs is false if it is set else true
$pred
...
    } else {
        # both rhs and lhs are literals
        my $res = ($lhs || $rhs) ? 1 : 0;
        return $self->_get_predicate_literals("$lhs || $rhs => $res", $res, %extra);
    }
}

sub _macro_sqrt_var {
    return << '...';
;;;;;; VIC_VAR_SQRT VARIABLES ;;;;;;
VIC_VAR_SQRT_UDATA udata
VIC_VAR_SQRT_VAL res 2
VIC_VAR_SQRT_RES res 2
VIC_VAR_SQRT_SUM res 2
VIC_VAR_SQRT_ODD res 2
VIC_VAR_SQRT_TMP res 2
...
}

sub _macro_sqrt_macro {
    return << '...';
;;;;;; Taken from Microchip PIC examples.
;;;;;; reverse of Finite Difference Squaring
m_sqrt_internal macro
    local _m_sqrt_loop, _m_sqrt_loop_break
    movlw 0x01
    movwf VIC_VAR_SQRT_ODD
    clrf VIC_VAR_SQRT_ODD + 1
    clrf VIC_VAR_SQRT_RES
    clrf VIC_VAR_SQRT_RES + 1
    clrf VIC_VAR_SQRT_SUM
    clrf VIC_VAR_SQRT_SUM + 1
    clrf VIC_VAR_SQRT_TMP
    clrf VIC_VAR_SQRT_TMP + 1
_m_sqrt_loop:
    movf VIC_VAR_SQRT_SUM + 1, W
    addwf VIC_VAR_SQRT_ODD + 1, W
    movwf VIC_VAR_SQRT_TMP + 1
    movf VIC_VAR_SQRT_SUM, W
    addwf VIC_VAR_SQRT_ODD, W
    movwf VIC_VAR_SQRT_TMP
    btfsc STATUS, C
    incf VIC_VAR_SQRT_TMP + 1, F
    movf VIC_VAR_SQRT_TMP, W
    subwf VIC_VAR_SQRT_VAL, W
    movf VIC_VAR_SQRT_TMP + 1, W
    btfss STATUS, C
    addlw 0x01
    subwf VIC_VAR_SQRT_VAL + 1, W
    btfss STATUS, C
    goto _m_sqrt_loop_break
    movf VIC_VAR_SQRT_TMP + 1, W
    movwf VIC_VAR_SQRT_SUM + 1
    movf VIC_VAR_SQRT_TMP, W
    movwf VIC_VAR_SQRT_SUM
    movlw 0x02
    addwf VIC_VAR_SQRT_ODD, F
    btfsc STATUS, C
    incf VIC_VAR_SQRT_ODD + 1, F
    incf VIC_VAR_SQRT_RES, F
    btfsc STATUS, Z
    incf VIC_VAR_SQRT_RES + 1, F
    goto _m_sqrt_loop
_m_sqrt_loop_break:
    endm
m_sqrt_8bit macro v1
    movf v1, W
    movwf VIC_VAR_SQRT_VAL
    clrf VIC_VAR_SQRT_VAL + 1
    m_sqrt_internal
    movf VIC_VAR_SQRT_RES, W
    endm
m_sqrt_16bit macro v1
    movf high v1, W
    movwf VIC_VAR_SQRT_VAL + 1
    movf low v1, W
    movwf VIC_VAR_SQRT_VAL
    m_sqrt_internal
    movf VIC_VAR_SQRT_RES, W
    endm
...
}

sub op_sqrt {
    my ($self, $var1, $dummy, %extra) = @_;
    my $literal = qr/^\d+$/;
    my $code = '';
    #TODO: temporary only 8-bit math
    if ($var1 !~ $literal) {
        $var1 = uc $var1;
        my $b1 = $self->address_bits($var1) || 8;
        # both are variables
        $code .= << "...";
\t;; perform sqrt($var1)
\tm_sqrt_${b1}bit $var1
...
    } elsif ($var1 =~ $literal) {
        my $svar = sqrt $var1;
        my $var2 = sprintf "0x%02X", int($svar);
        $code .= << "...";
\t;; sqrt($var1) = $svar -> $var2;
\tmovlw $var2
...
    } else {
        carp "Warning: $var1 cannot have a square root";
        return;
    }
    my $macros = {
        m_sqrt_var => $self->_macro_sqrt_var,
        m_sqrt_macro => $self->_macro_sqrt_macro,
    };
    $code .= $self->op_assign_wreg($extra{RESULT}) if $extra{RESULT};
    return wantarray ? ($code, {}, $macros) : $code;
}

sub break { return 'BREAK'; }
sub continue { return 'CONTINUE'; }

sub store_string {
    my ($self, $str, $strvar, $lenvar) = @_;
    my $nstr = $str;
    $nstr = $str->{string} if ref $str eq 'HASH';
    my $label = $strvar;
    $label = $str->{name} if ref $str eq 'HASH';
    my ($code, $szdecl) = ('', '');
    if ($str->{empty}) {
        $code = "\t;; not storing an empty string\n";
        my $sz = $self->code_config->{string}->{size};
        my $len = sprintf "0x%02X", $sz;
        my $idxvar = $self->_get_idx_var($strvar);
        $szdecl = << "...";
$strvar res $len; allocate memory for $strvar
$idxvar res 1; index for accessing $strvar elements
$lenvar equ $len; $lenvar is length of $strvar
...
    } else {
        my @bytearr = split //, $nstr;
        my $bytes = [(map { sprintf "0x%02X", ord($_) } @bytearr), "0x00"];
        my $len = sprintf "0x%02X", scalar(@$bytes) + 1;
        my $slen = sprintf "0x%02X", scalar(@$bytes);
        my $nstr2 = $nstr;
        $nstr2 =~ s/[\n]/\\n/gs;
        $nstr2 =~ s/[\r]/\\r/gs;
        $code = "\t;; storing string '$nstr2'\n";
        $code .= "$label:\n\taddwf PCL, F\n\tdt " . join(',', @$bytes) . "\n";
        $szdecl = "$strvar res $len; allocate memory for $strvar\n$lenvar equ $slen; $lenvar is length of $label\n";
    }
    return wantarray ? ($code, $szdecl) : $code;
}

sub store_array {
    my ($self, $arr, $arrvar, $sz, $szvar) = @_;
    # use db in 16-bit MCUs for 8-bit values
    # arrays are read-write objects
    my $arrstr = join (",", @$arr) if scalar @$arr;
    $arrstr = '0' unless $arrstr;
    $sz = sprintf "0x%02X", $sz;
    ### FIXME: this is not correct. you need to do like the string stuff
    return << "..."
$arrvar db $arr ; array stored as accessible bytes
$szvar equ $sz   ; length of array $arrvar is a constant
...
}

sub store_table {
    my ($self, $table, $label, $tblsz, $tblszvar) = @_;
    return unless $self->doesrole('Chip');
    unless (exists $self->registers->{PCL}) {
        carp $self->type, " does not have the PCL register";
        return;
    }
    my $code = "$label:\n";
    $code .= "\taddwf PCL, F\n";
    if (scalar @$table) {
        foreach (@$table) {
            my $d = sprintf "0x%02X", $_;
            $code .= "\tdt $d\n";
        }
    } else {
        # table is empty
        $code .= "\tdt 0\n";
    }
    $tblsz = sprintf "0x%02X", $tblsz;
    my $szdecl = "$tblszvar equ $tblsz ; size of table at $label\n";
    return wantarray ? ($code, $szdecl) : $code;
}

sub op_tblidx {
    my ($self, $table, $idx, %extra) = @_;
    return unless defined $extra{RESULT};
    my $sz = $extra{SIZE};
    $idx = uc $idx;
    $sz = uc $sz if $sz;
    my $szcode = '';
    # check bounds
    $szcode = "\tandlw $sz - 1" if $sz;
    return << "..."
\tmovwf $idx
$szcode
\tcall $table
\tmovwf $extra{RESULT}
...
}

sub op_arridx {
    my ($self, $array, $idx, %extra) = @_;
    #XXX { array => $array, index => $idx, %extra };
}

sub op_stridx {
    my ($self, $string, $idx, %extra) = @_;
    #XXX { string => $string, index => $idx, %extra };
}

sub store_bytes {
    my ($self, $tables) = @_;
    return unless defined $tables;
    return unless $self->doesrole('Chip');

    unless (ref $tables eq 'ARRAY') {
        $tables = [ $tables ];
    }
    return '' unless scalar @$tables;
    my $code = '';
    foreach (@$tables) {
        my $name = $_->{name};
        next unless defined $name;
        next unless exists $_->{bytes};
        next unless ref $_->{bytes} eq 'ARRAY';
        my $bytes = join(',', @{$_->{bytes}});
        $code .= $_->{comment} . "\n" if defined $_->{comment};
        my $row = "$name:\n\taddwf PCL, F\n\tdt $bytes\n";
        $code .= $row;
    }
    return $code;
}

sub string_concat {
    return ";;;; string concatenation not implemented";
}

sub _op_concat_bytev {
    return << "...";
m_op_concat_bytev macro dvar, dlen, didx, bvar
\tlocal _op_concat_bytev_end
\t;;;; check for space first and then add byte
\tbanksel didx
\tmovf didx, W
\tbanksel VIC_VAR_ASSIGN_STRIDX
\tmovwf VIC_VAR_ASSIGN_STRIDX
\tmovlw dlen
\tmovwf VIC_VAR_ASSIGN_STRLEN
\tbcf STATUS, Z
\tbcf STATUS, C
\tmovf VIC_VAR_ASSIGN_STRIDX, W
\tsubwf VIC_VAR_ASSIGN_STRLEN, W
\t;; W == 0
\tbtfsc STATUS, Z
\tgoto _op_concat_bytev_end
\t;; we have space, let's add byte
\tbanksel dvar
\tmovlw dvar
\tmovwf FSR
\tbanksel didx
\tmovf didx, W
\taddwf FSR, F
\tbanksel bvar
\tmovf bvar, W
\tmovwf INDF
\tbanksel didx
\tincf didx, F
_op_concat_bytev_end:
\tnop ;; no space left
\tendm
...
}

sub byte_concat {
    my $self = shift;
    my $dvar = shift;
    my $svar = shift;
    $svar = uc $svar;
    my ($code, $funcs, $macros) = ('', {}, {});
    if (ref $dvar eq 'HASH' and $dvar->{type} eq 'string') {
        my $dname = $dvar->{name};
        my $idxvar = $self->_get_idx_var($dname);
        my $dlen = $dvar->{size};
        $macros->{m_op_assign_var} = $self->_op_assign_str_var;
        $macros->{m_op_concat_bytev} = $self->_op_concat_bytev($dname, $dlen, $idxvar, $svar);
        $code = "\tm_op_concat_bytev $dname, $dlen, $idxvar, $svar\n";
    } else {
        carp $dvar->{name} . " is not a string. Concatenation not valid\n";
        return;
    }
    return wantarray ? ($code, $funcs, $macros) : $code;
}

sub op_cat_assign {
    my $self = shift;
    my ($var1, $var2) = @_;
    if (ref $var2 eq 'HASH') {
        return $self->string_concat(@_);
    } else {
        return $self->byte_concat(@_);
    }
}

1;
__END__

