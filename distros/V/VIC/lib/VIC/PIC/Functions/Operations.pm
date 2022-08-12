package VIC::PIC::Functions::Operations;
use strict;
use warnings;
use bigint;
our $VERSION = '0.32';
$VERSION = eval $VERSION;
use Carp;
use POSIX ();
use Moo::Role;

sub _macro_delay_var {
    return <<'...';
;;;;;; DELAY FUNCTIONS ;;;;;;;

VIC_VAR_DELAY_UDATA udata
VIC_VAR_DELAY   res 3

...
}

sub _macro_delay_us {
    return <<'...';
;; 1MHz => 1us per instruction
;; return, goto and call are 2us each
;; hence each loop iteration is 3us
;; the rest including movxx + return = 2us
;; hence usecs - 6 is used
m_delay_us macro usecs
    local _delay_usecs_loop_0
    variable usecs_1 = 0
    variable usecs_2 = 0
if (usecs > D'6')
usecs_1 = usecs / D'3' - 2
usecs_2 = usecs % D'3'
    movlw   usecs_1
    movwf   VIC_VAR_DELAY
    decfsz  VIC_VAR_DELAY, F
    goto    $ - 1
    while usecs_2 > 0
        goto $ + 1
usecs_2--
    endw
else
usecs_1 = usecs
    while usecs_1 > 0
        nop
usecs_1--
    endw
endif
    endm
...
}

sub _macro_delay_wus {
    return <<'...';
m_delay_wus macro
    local _delayw_usecs_loop_0
    movwf   VIC_VAR_DELAY
_delayw_usecs_loop_0:
    decfsz  VIC_VAR_DELAY, F
    goto    _delayw_usecs_loop_0
    endm
...
}

sub _macro_delay_ms {
    return <<'...';
;; 1MHz => 1us per instruction
;; each loop iteration is 3us each
;; there are 2 loops, one for (768 + 3) us
;; and one for the rest in ms
;; we add 3 instructions for the outer loop
;; number of outermost loops = msecs * 1000 / 771 = msecs * 13 / 10
m_delay_ms macro msecs
    local _delay_msecs_loop_0, _delay_msecs_loop_1, _delay_msecs_loop_2
    variable msecs_1 = 0
    variable msecs_2 = 0
msecs_1 = (msecs * D'1000') / D'771'
msecs_2 = ((msecs * D'1000') % D'771') / 3 - 2;; for 3 us per instruction
    movlw   msecs_1
    movwf   VIC_VAR_DELAY + 1
_delay_msecs_loop_1:
    clrf   VIC_VAR_DELAY   ;; set to 0 which gets decremented to 0xFF
_delay_msecs_loop_0:
    decfsz  VIC_VAR_DELAY, F
    goto    _delay_msecs_loop_0
    decfsz  VIC_VAR_DELAY + 1, F
    goto    _delay_msecs_loop_1
if msecs_2 > 0
    ;; handle the balance
    movlw msecs_2
    movwf VIC_VAR_DELAY
_delay_msecs_loop_2:
    decfsz VIC_VAR_DELAY, F
    goto _delay_msecs_loop_2
    nop
endif
    endm
...
}

sub _macro_delay_wms {
    return <<'...';
m_delay_wms macro
    local _delayw_msecs_loop_0, _delayw_msecs_loop_1
    movwf   VIC_VAR_DELAY + 1
_delayw_msecs_loop_1:
    clrf   VIC_VAR_DELAY   ;; set to 0 which gets decremented to 0xFF
_delayw_msecs_loop_0:
    decfsz  VIC_VAR_DELAY, F
    goto    _delayw_msecs_loop_0
    decfsz  VIC_VAR_DELAY + 1, F
    goto    _delayw_msecs_loop_1
    endm
...
}

sub _macro_delay_s {
    return <<'...';
;; 1MHz => 1us per instruction
;; each loop iteration is 3us each
;; there are 2 loops, one for (768 + 3) us
;; and one for the rest in ms
;; we add 3 instructions for the outermost loop
;; 771 * 256 + 3 = 197379 ~= 200000
;; number of outermost loops = seconds * 1000000 / 200000 = seconds * 5
m_delay_s macro secs
    local _delay_secs_loop_0, _delay_secs_loop_1, _delay_secs_loop_2
    local _delay_secs_loop_3
    variable secs_1 = 0
    variable secs_2 = 0
    variable secs_3 = 0
    variable secs_4 = 0
secs_1 = (secs * D'1000000') / D'197379'
secs_2 = ((secs * D'1000000') % D'197379') / 3
secs_4 = (secs_2 >> 8) & 0xFF - 1
secs_3 = 0xFE
    movlw   secs_1
    movwf   VIC_VAR_DELAY + 2
_delay_secs_loop_2:
    clrf    VIC_VAR_DELAY + 1   ;; set to 0 which gets decremented to 0xFF
_delay_secs_loop_1:
    clrf    VIC_VAR_DELAY   ;; set to 0 which gets decremented to 0xFF
_delay_secs_loop_0:
    decfsz  VIC_VAR_DELAY, F
    goto    _delay_secs_loop_0
    decfsz  VIC_VAR_DELAY + 1, F
    goto    _delay_secs_loop_1
    decfsz  VIC_VAR_DELAY + 2, F
    goto    _delay_secs_loop_2
if secs_4 > 0
    movlw secs_4
    movwf VIC_VAR_DELAY + 1
_delay_secs_loop_3:
    clrf VIC_VAR_DELAY
    decfsz VIC_VAR_DELAY, F
    goto $ - 1
    decfsz VIC_VAR_DELAY + 1, F
    goto _delay_secs_loop_3
endif
if secs_3 > 0
    movlw secs_3
    movwf VIC_VAR_DELAY
    decfsz VIC_VAR_DELAY, F
    goto $ - 1
endif
    endm
...
}

sub _macro_delay_ws {
    return <<'...';
m_delay_ws macro
    local _delayw_secs_loop_0, _delayw_secs_loop_1, _delayw_secs_loop_2
    movwf   VIC_VAR_DELAY + 2
_delayw_secs_loop_2:
    clrf    VIC_VAR_DELAY + 1   ;; set to 0 which gets decremented to 0xFF
_delayw_secs_loop_1:
    clrf    VIC_VAR_DELAY   ;; set to 0 which gets decremented to 0xFF
_delayw_secs_loop_0:
    decfsz  VIC_VAR_DELAY, F
    goto    _delayw_secs_loop_0
    decfsz  VIC_VAR_DELAY + 1, F
    goto    _delayw_secs_loop_1
    decfsz  VIC_VAR_DELAY + 2, F
    goto    _delayw_secs_loop_2
    endm
...
}

sub _delay_w {
    my ($self, $unit, $varname) = @_;
    my $funcs = {};
    my $macros = { m_delay_var => $self->_macro_delay_var };
    my $fn = "_delay_w$unit";
    my $mac = "m_delay_w$unit";
    my $mack = "_macro_delay_w$unit";
    my $code = << "...";
\tmovf $varname, W
\tcall $fn
...
    $funcs->{$fn} = << "....";
\t$mac
\treturn
....
    $macros->{$mac} = $self->$mack;
    return wantarray ? ($code, $funcs, $macros) : $code;
}

sub delay {
    my ($self, $t) = @_;
    return unless $self->doesrole('Operations');
    return $self->_delay_w(s => uc($t)) unless $t =~ /^\d+$/;
    return '' if $t <= 0;
    # divide the time into component seconds, milliseconds and microseconds
    my $sec = POSIX::floor($t / 1e6);
    my $ms = POSIX::floor(($t - $sec * 1e6) / 1000);
    my $us = $t - $sec * 1e6 - $ms * 1000;
    my $code = '';
    my $funcs = {};
    # return all as part of the code always
    my $macros = {
        m_delay_var => $self->_macro_delay_var,
        m_delay_s => $self->_macro_delay_s,
        m_delay_ms => $self->_macro_delay_ms,
        m_delay_us => $self->_macro_delay_us,
    };
    ## more than one function could be called so have them separate
    if ($sec > 0) {
        my $fn = "_delay_${sec}s";
        $code .= "\tcall $fn\n";
        my $fncode = '';
        my $siter = $sec;
        ## the number 50 comes from 255 * 197379 / 1e6
        while ($siter >= 50) {
            $fncode .= "\tm_delay_s D'50'\n";
            $siter -= 50;
        }
        $fncode .= "\tm_delay_s D'$siter'\n" if $siter > 0;
        $fncode .= "\treturn\n";
        $funcs->{$fn} = $fncode;
    }
    if ($ms > 0) {
        my $fn = "_delay_${ms}ms";
        $code .= "\tcall $fn\n";
        my $fncode = '';
        my $msiter = $ms;
        ## the number 196 comes from 255 * 771 / 1000
        while ($msiter >= 196) {
            $fncode .= "\tm_delay_ms D'196'\n";
            $msiter -= 196;
        }
        $fncode .= "\tm_delay_ms D'$msiter'\n" if $msiter > 0;
        $fncode .= "\treturn\n";
        $funcs->{$fn} = $fncode;
    }
    if ($us > 0) {
        # for less than 6 us we just inline the code
        if ($us <= 6) {
            $code .= "\tm_delay_us D'$us'\n";
        } else {
            my $fn = "_delay_${us}us";
            $code .= "\tcall $fn\n";
            my $fncode = '';
            my $usiter = $us;
            ## the number 771 comes from (255 + 2) * 3
            while ($usiter >= 771) {
                $fncode .= "\tm_delay_us D'771'\n";
                $usiter -= 771;
            }
            $fncode .= "\tm_delay_us D'$usiter'\n" if $usiter > 0;
            $fncode .= "\treturn\n";
            $funcs->{$fn} = $fncode;
        }
    }
    return wantarray ? ($code, $funcs, $macros) : $code;
}

sub delay_s {
    my ($self, $t) = @_;
    return $self->delay($t * 1e6) if $t =~ /^\d+$/;
    return $self->_delay_w(s => uc($t));
}

sub delay_ms {
    my ($self, $t) = @_;
    return $self->delay($t * 1000) if $t =~ /^\d+$/;
    return $self->_delay_w(ms => uc($t));
}

sub delay_us {
    my ($self, $t) = @_;
    return $self->delay($t) if $t =~ /^\d+$/;
    return $self->_delay_w(us => uc($t));
}

sub _macro_debounce_var {
    return <<'...';
;;;;;; VIC_VAR_DEBOUNCE VARIABLES ;;;;;;;

VIC_VAR_DEBOUNCE_VAR_IDATA idata
;; initialize state to 1
VIC_VAR_DEBOUNCESTATE db 0x01
;; initialize counter to 0
VIC_VAR_DEBOUNCECOUNTER db 0x00

...
}

sub debounce {
    my ($self, $inp, %action) = @_;
    return unless $self->doesroles(qw(Operations Chip CodeGen GPIO));
    unless (exists $self->registers->{STATUS}) {
        carp $self->type, " does not have the STATUS register";
        return;
    }
    my $action_label = $action{ACTION};
    my $end_label = $action{END};
    return unless $action_label;
    return unless $end_label;
    my ($port, $portbit);
    if (exists $self->pins->{$inp}) {
        my $ipin = $self->get_input_pin($inp);
        unless (defined $ipin) {
            carp "Cannot find $inp in the list of GPIO ports or pins";
            return;
        } else {
            my $tris;
            ($port, $tris, $portbit) = @{$self->input_pins->{$inp}};
        }
    } elsif (exists $self->registers->{$inp}) {
        $port = $inp;
        $portbit = 0;
        carp "Port $port has been supplied. Assuming portbit to debounce is $portbit";
    } else {
        carp "Cannot find $inp in the list of ports or pins";
        return;
    }
    # incase the user does weird stuff override the count and delay
    my $debounce_count = $self->code_config->{debounce}->{count} || 1;
    my $debounce_delay = $self->code_config->{debounce}->{delay} || 1000;
    my ($deb_code, $funcs, $macros) = $self->delay($debounce_delay);
    $macros = {} unless defined $macros;
    $funcs = {} unless defined $funcs;
    $deb_code = 'nop' unless defined $deb_code;
    $macros->{m_debounce_var} = $self->_macro_debounce_var;
    $debounce_count = sprintf "0x%02X", $debounce_count;
    my $code = <<"...";
\t;;; generate code for debounce $port<$portbit>
$deb_code
\t;; has debounce state changed to down (bit 0 is 0)
\t;; if yes go to debounce-state-down
\tbtfsc   VIC_VAR_DEBOUNCESTATE, 0
\tgoto    _debounce_state_up
_debounce_state_down:
\tclrw
\tbtfss   $port, $portbit
\t;; increment and move into counter
\tincf    VIC_VAR_DEBOUNCECOUNTER, 0
\tmovwf   VIC_VAR_DEBOUNCECOUNTER
\tgoto    _debounce_state_check

_debounce_state_up:
\tclrw
\tbtfsc   $port, $portbit
\tincf    VIC_VAR_DEBOUNCECOUNTER, 0
\tmovwf   VIC_VAR_DEBOUNCECOUNTER
\tgoto    _debounce_state_check

_debounce_state_check:
\tmovf    VIC_VAR_DEBOUNCECOUNTER, W
\txorlw   $debounce_count
\t;; is counter == $debounce_count ?
\tbtfss   STATUS, Z
\tgoto    $end_label
\t;; after $debounce_count straight, flip direction
\tcomf    VIC_VAR_DEBOUNCESTATE, 1
\tclrf    VIC_VAR_DEBOUNCECOUNTER
\t;; was it a key-down
\tbtfss   VIC_VAR_DEBOUNCESTATE, 0
\tgoto    $end_label
\tgoto    $action_label
$end_label:\n
...
    return wantarray ? ($code, $funcs, $macros) : $code;
}

1;
__END__
