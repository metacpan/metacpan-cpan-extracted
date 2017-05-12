package VIC::PIC::Functions::GPIO;
use strict;
use warnings;
use bigint;
our $VERSION = '0.31';
$VERSION = eval $VERSION;
use Carp;
use POSIX ();
use Scalar::Util qw(looks_like_number);
use Moo::Role;

sub get_output_pin {
    my ($self, $ipin) = @_;
    return $ipin if exists $self->output_pins->{$ipin};
    # find the correct GPIO pin then matching this pin
    my $pin_no = $self->pins->{$ipin};
    my $allpins = $self->pins->{$pin_no};
    unless (ref $allpins eq 'ARRAY') {
        carp "Invalid data for pin $pin_no";
        return;
    }
    my $opin;
    foreach my $iopin (@$allpins) {
        next unless exists $self->output_pins->{$iopin};
        # we have now found the correct iopin for the analog_pin
        $opin = $iopin;
        last;
    }
    return $opin;
}

sub get_input_pin {
    my ($self, $ipin) = @_;
    return $ipin if exists $self->input_pins->{$ipin};
    # find the correct GPIO pin then matching this pin
    my $pin_no = $self->pins->{$ipin};
    my $allpins = $self->pins->{$pin_no};
    unless (ref $allpins eq 'ARRAY') {
        carp "Invalid data for pin $pin_no";
        return;
    }
    my $opin;
    foreach my $iopin (@$allpins) {
        next unless exists $self->input_pins->{$iopin};
        # we have now found the correct iopin for the analog_pin
        $opin = $iopin;
        last;
    }
    return $opin;
}

sub _gpio_select {
    my $self = shift;
    my ($io, $ad, $outp) = @_;
    return unless $self->doesroles(qw(Chip GPIO));
    return unless defined $outp;
    $io = 0 if $io =~ /output/i;
    $io = 1 if $io =~ /input/i;
    $ad = 0 if $ad =~ /digital/i;
    $ad = 1 if $ad =~ /analog/i;
    return unless (($io == 0 or $io == 1) and ($ad == 0 or $ad == 1));
    #TODO: check if banksel works for all chips
    #if not then allow for a way to map instruction codes
    #to something else

    # is this a register
    my ($trisp_code, $port_code, $an_code) = ('', '', '');
    if (exists $self->io_ports->{$outp} and
        exists $self->registers->{$outp}) {
        my $trisp = $self->io_ports->{$outp};
        my $flags = ($ad == 0) ? 0xFF : 0;
        my $flagsH = ($ad == 0) ? 0xFF : 0;
        if (exists $self->registers->{ANSEL}) {
            # get the pins that belong to the register
            my @portpins = ();
            if ($io == 0) {
                foreach (keys %{$self->output_pins}) {
                    push @portpins, $_ if $self->output_pins->{$_}->[0] eq $outp;
                }
            } else {
                foreach (keys %{$self->input_pins}) {
                    push @portpins, $_ if $self->input_pins->{$_}->[0] eq $outp;
                }
            }
            foreach (@portpins) {
                my $pin_no = $self->pins->{$_};
                next unless defined $pin_no;
                my $allpins = $self->pins->{$pin_no};
                next unless ref $allpins eq 'ARRAY';
                foreach my $anpin (@$allpins) {
                    next unless exists $self->analog_pins->{$anpin};
                    my ($pno, $pbit) = @{$self->analog_pins->{$anpin}};
                    $flags ^= 1 << $pbit if $pbit < 8;
                    $flagsH ^= 1 << ($pbit - 8) if $pbit >= 8;
                }
            }
            my $iorandwf = ($ad == 0) ? 'andwf' : 'iorwf';
            if ($flags != 0) {
                $flags = sprintf "0x%02X", $flags;
                $an_code .= "\tbanksel ANSEL\n";
                $an_code .= "\tmovlw $flags\n";
                $an_code .= "\t$iorandwf ANSEL, F\n";
            }
            if (exists $self->registers->{ANSELH}) {
                if ($flagsH != 0) {
                    $flagsH = sprintf "0x%02X", $flagsH;
                    $an_code .= "\tbanksel ANSELH\n";
                    $an_code .= "\tmovlw $flagsH\n";
                    $an_code .= "\t$iorandwf ANSELH, F\n";
                }
            }
        }
        if ($io == 0) { # output
            $trisp_code = "\tbanksel $trisp\n\tclrf $trisp";
            $port_code = "\tbanksel $outp\n\tclrf $outp";
        } else { # input
            $trisp_code = "\tbanksel $trisp\n\tmovlw 0xFF\n\tmovwf $trisp";
            $port_code = "\tbanksel $outp";
        }
    } elsif (exists $self->pins->{$outp}) {
        my $iopin = ($io == 0) ? $self->get_output_pin($outp) :
                                    $self->get_input_pin($outp);
        unless (defined $iopin) {
            my $iostr = ($io == 0) ? 'output' : 'input';
            carp "Cannot find $outp in the list of registers or $iostr pins supporting GPIO for the chip " . $self->type;
            return;
        }
        my ($port, $trisp, $pinbit) = ($io == 0) ?
                    @{$self->output_pins->{$iopin}} :
                    @{$self->input_pins->{$iopin}};

        if (exists $self->registers->{ANSEL}) {
            my $pin_no = $self->pins->{$iopin};
            my $allpins = $self->pins->{$pin_no};
            unless (ref $allpins eq 'ARRAY') {
                carp "Invalid data for pin $pin_no";
                return;
            }
            foreach my $anpin (@$allpins) {
                next unless exists $self->analog_pins->{$anpin};
                my ($pno, $pbit) = @{$self->analog_pins->{$anpin}};
                my $ansel = 'ANSEL';
                if (exists $self->registers->{ANSELH}) {
                    $ansel = ($pbit >= 8) ? 'ANSELH' : 'ANSEL';
                }
                ##TODO: make sure that ANS$pbit exists for all header files
                my $bcfbsf = ($ad == 0) ? 'bcf' : 'bsf';
                $an_code = "\tbanksel $ansel\n\t$bcfbsf $ansel, ANS$pbit";
                last;
            }
        }
        if ($io == 0) { # output
            $trisp_code = "\tbanksel $trisp\n\tbcf $trisp, $trisp$pinbit";
            $port_code = "\tbanksel $port\n\tbcf $port, $pinbit";
        } else { # input
            $trisp_code = "\tbanksel $trisp\n\tbsf $trisp, $trisp$pinbit";
            $port_code = "\tbanksel $port";
        }
    } else {
        carp "Cannot find $outp in the list of registers or pins supporting GPIO";
        return;
    }
    return << "...";
$trisp_code
$an_code
$port_code
...
}

sub digital_output {
    my $self = shift;
    return $self->_gpio_select(output => 'digital', @_);
}

sub digital_input {
    my $self = shift;
    return $self->_gpio_select(input => 'digital', @_);
}

sub analog_input {
    my $self = shift;
    return $self->_gpio_select(input => 'analog', @_);
}

sub setup {
    my $self = shift;
    my ($outp) = @_;
    if ($outp =~ /US?ART/) {
        if ($self->doesrole('USART') and exists $self->usart_pins->{$outp}) {
            return $self->usart_setup(@_);
        }
    }
    carp "The 'setup' function is not valid for $outp. Use something else.";
    return;
}

sub write {
    my $self = shift;
    my ($outp, $val) = @_;
    return unless $self->doesroles(qw(CodeGen Operations Chip GPIO));
    return unless defined $outp;
    if (exists $self->io_ports->{$outp} and
        exists $self->registers->{$outp}) {
        my $port = $self->io_ports->{$outp};
        unless (defined $val) {
            return << "...";
\tclrf $outp
\tcomf $outp, 1
...
        }
        if ($self->validate($val)) {
            # ok we want to write the value of a pin to a port
            # that doesn't seem right so let's provide a warning
            if ($self->pins->{$val}) {
                carp "$val is a pin and you're trying to write a pin to a port" .
                    " $outp. You can write a pin to a pin or a port to a port only.\n";
                return;
            }
        }
        # this handles the variable to port assigning
        return $self->op_assign($outp, $val);
    } elsif (exists $self->pins->{$outp}) {
        my $iopin = $self->get_output_pin($outp);
        unless (defined $iopin) {
            carp "Cannot find $outp in the list of VALID ports, register or pins to write to";
            return;
        }
        my ($port, $trisp, $pinbit) = @{$self->output_pins->{$iopin}};
        if ($val =~ /^\d+$/) {
            return "\tbanksel $port\n\tbcf $port, $pinbit\n" if "$val" eq '0';
            return "\tbanksel $port\n\tbsf $port, $pinbit\n" if "$val" eq '1';
            carp "$val cannot be applied to a pin $outp\n";
            return;
        } elsif (exists $self->pins->{$val}) {
            # ok we want to short two pins, and this is not bit-banging
            # although seems like it
            my $vpin = $self->get_output_pin($val);
            if ($vpin) {
                my ($vport, $vtris, $vpinbit) = @{$self->output_pins->{$vpin}};
                return << "...";
\tbtfss $vport, $vpin
\tbcf $port, $outp
\tbtfsc $vport, $vpin
\tbsf $port, $outp
...
            } else {
                carp "$val is a port or unknown pin and cannot be written to a pin $outp. ".
                    "Only a pin can be written to a pin.\n";
                return;
            }
        } elsif ($self->is_variable($val)) {
            $val = uc $val;
            return << "...";
;;;; assigning $val to a pin => using the last bit
\tbtfss $val, 0
\tbcf $port, $outp
\tbtfsc $val, 0
\tbsf $port, $outp
...
        } else {
            carp "$val is a port or unknown pin and cannot be written to a pin $outp. ".
            "Only a pin can be written to a pin.\n";
            return;
        }
        return $self->op_assign($port, $val);
    } elsif (exists $self->registers->{$outp}) { # write a value to a register
        my $code = "\tbanksel $outp\n";
        $code .= $self->op_assign($outp, $val);
        return $code;
    } else {
        if ($self->doesrole('USART') and exists $self->usart_pins->{$outp}) {
            return $self->usart_write(@_);
        }
        carp "Cannot find $outp in the list of ports, register or pins to write to";
        return;
    }
}

sub _macro_read_var {
    my $v = $_[1];
    $v = uc $v;
    return << "...";
;;;;;;; $v VARIABLES ;;;;;;
$v\_UDATA udata
$v res 1
...
}

sub read {
    my $self = shift;
    my $inp = shift;
    my $var = undef;
    my %action = ();
    if (scalar(@_) == 1) {
        $var = shift;
    } else {
        %action = @_;
    }
    return unless $self->doesroles(qw(CodeGen Chip GPIO));
    my ($code, $funcs, $macros, $tables) = ('', {}, {}, []);

    if (defined $var) {
        if (looks_like_number($var) or ref $var eq 'HASH') {
            carp "Cannot read from $inp into a constant $var";
            return;
        }
        $var = uc $var;
    } else {
        ## we need only 1 variable here
        if (defined $action{PARAM}) {
            $var = $action{PARAM} . '0';
        } else {
            carp "Implementation errors implementing the Action block";
            return undef;
        }
        $var = uc $var;
        $macros->{lc("m_read_$var")} = $self->_macro_read_var($var);
        return unless (defined $action{ACTION} or defined $action{ISR});
        return unless defined $action{END};
    }
    my $bits = $self->address_bits($var);
    my ($port, $portbit);
    if (exists $self->io_ports->{$inp} and
        exists $self->registers->{$inp}) {
        # this is a port like PORT[A-Z]
        # we may end up reading from all pins on a port
        $port = $inp;
        $code = <<"...";
;;; instant reading from $port into $var
\tbanksel $port
\tmovf $port, W
\tbanksel $var
\tmovwf $var
...
    } elsif (exists $self->pins->{$inp}) {
        my $ipin = $self->get_input_pin($inp);
        unless (defined $ipin) {
            carp "Cannot find $inp in the list of GPIO ports or pins";
            return;
        } else {
            my $tris;
            ($port, $tris, $portbit) = @{$self->input_pins->{$inp}};
            $code = <<"....";
;;; instant reading from $inp into $var
\tclrw
\tbanksel $port
\tbtfsc $port, $portbit
\taddlw 0x01
\tbanksel $var
\tmovwf $var
....
        }
    } else {
        if ($self->doesrole('USART') and exists $self->usart_pins->{$inp}) {
            return $self->usart_read($inp, @_);
        }
        carp "Cannot find $inp in the list of ports or pins to read from";
        return;
    }
    if (%action) {
        if (exists $action{ACTION}) {
            my $action_label = $action{ACTION};
            my $end_label = $action{END};
            $code .= <<"...";
;;; invoking $action_label
\tgoto $action_label
$end_label:\n
...
        } elsif (exists $action{ISR}) {
            ## ok we can read from a port too, so let's do that as well
            if (defined $portbit) {
                # if we are a pin, then find the right pin
                $inp = $self->get_input_pin($inp);
            }
            ## reset the code here since we have to check IOC pins
            my ($ioc_bit, $ioc_reg, $ioc_flag, $ioc_enable);
            if (exists $self->ioc_pins->{$inp}) {
                my $apin;
                ($apin, $ioc_bit, $ioc_reg) = @{$self->ioc_pins->{$inp}};
            } elsif (exists $self->ioc_ports->{$inp}) {
                $ioc_reg = $self->ioc_ports->{$inp};
            } else {
                carp "Reading using interrupt-on-change has to be for a pin ".
                        "that supports it, $inp does not support it or is not a pin.";
                return;
            }
            $ioc_flag = $self->ioc_ports->{FLAG};
            $ioc_enable = $self->ioc_ports->{ENABLE};
            my $ioch = { bit => $ioc_bit, reg => $ioc_reg, flag =>
                    $ioc_flag, enable => $ioc_enable };
            $code = $self->isr_ioc($ioch, $inp);
            my $isr_label = 'isr_' . ((defined $ioc_bit) ? lc($ioc_bit) :
                                     ((defined $ioc_reg) ? lc($ioc_reg) :
                                       lc($inp)));
            $funcs->{$isr_label} = $self->isr_ioc($ioch, $inp, $var, $port, $portbit, %action);
        } else {
            carp "Unknown action requested. Probably a bug in implementation";
            return;
        }
    }
    return wantarray ? ($code, $funcs, $macros, $tables) : $code;
}

1;
__END__
