package VIC::PIC::Functions::ECCP;
use strict;
use warnings;
use bigint;
our $VERSION = '0.31';
$VERSION = eval $VERSION;
use Carp;
use POSIX ();
use Moo::Role;

#FIXME: C2OUT and P1B may be conflicting. check datasheet
sub _pwm_details {
    my ($self, $pwm_frequency, $duty, $type, @pins) = @_;
    return unless $self->doesrole('Chip');
    unless (exists $self->registers->{CCP1CON}) {
        carp $self->type, " does not have CCP1CON for ECCP features";
        return;
    }
    no bigint;
    #pulse_width = $duty / $pwm_frequency;
    # timer2 prescaler
    my $prescaler = 1; # can be 1, 4 or 16
    # Tosc = 1 / Fosc
    my $f_osc = $self->f_osc;
    my $pr2 = POSIX::ceil(($f_osc / 4) / $pwm_frequency); # assume prescaler = 1 here
    if (($pr2 - 1) <= 0xFF) {
        $prescaler = 1; # prescaler stays 1
    } else {
        $pr2 = POSIX::ceil($pr2 / 4); # prescaler is 4 or 16
        $prescaler = (($pr2 - 1) <= 0xFF) ? 4 : 16;
    }
    my $t2con = q{b'00000100'}; # prescaler is 1 or anything else
    $t2con = q{b'00000101'} if $prescaler == 4;
    $t2con = q{b'00000111'} if $prescaler == 16;
    # readjusting PR2 as per supported pre-scalers
    $pr2 = POSIX::ceil((($f_osc / 4) / $pwm_frequency) / $prescaler);
    $pr2--;
    $pr2 &= 0xFF;
    my $ccpr1l_ccp1con54 = POSIX::ceil(($duty * 4 * ($pr2)) / 100.0);
    my $ccp1con5 = ($ccpr1l_ccp1con54 & 0x02); #bit 5
    my $ccp1con4 = ($ccpr1l_ccp1con54 & 0x01); #bit 4
    my $ccpr1l = ($ccpr1l_ccp1con54 >> 2) & 0xFF;
    my $ccpr1l_x = sprintf "0x%02X", $ccpr1l;
    my $pr2_x = sprintf "0x%02X", ($pr2 - 1); ##HACK
    my $p1m = '00' if $type eq 'single';
    $p1m = '01' if $type eq 'full_forward';
    $p1m = '10' if $type eq 'half';
    $p1m = '11' if $type eq 'full_reverse';
    $p1m = '00' unless defined $p1m;
    my $ccp1con = sprintf "b'%s%d%d1100'", $p1m, $ccp1con5, $ccp1con4;
    my %str = (CCP1 => 0, P1D => 0, P1C => 0, P1B => 0, P1A => 0); # default all are port pins
    my %trisc = ();
    foreach my $pin (@pins) {
        unless (exists $self->pins->{$pin}) {
            carp "$pin is not a valid pin on the microcontroller. Ignoring\n";
            next;
        }
        my $pinno = $self->pins->{$pin};
        my $allpins = $self->pins->{$pinno};
        my $pwm_pin;
        foreach (@$allpins) {
            next unless exists $self->eccp_pins->{$_};
            $pwm_pin = $_;
            last;
        } 
        next unless defined $pwm_pin;
        # the user may use say RC5 instead of CCP1 and we still want the
        # CCP1 name which should really be returned as P1A here
        # pulse steering only needed in Single mode
        my ($p0, $trisp, $portpin) = @{$self->eccp_pins->{$pwm_pin}};
        $str{$pwm_pin} = 1 if $type eq 'single';
        $trisc{$portpin} = $trisp;
    }
    my $p1a = $str{P1A} || $str{CCP1};
    my $pstrcon = sprintf "b'0001%d%d%d%d'", $str{P1D}, $str{P1C}, $str{P1B}, $p1a;
    my $trisc_bsf = '';
    my $trisc_bcf = '';
    foreach (sort (keys %trisc)) {
        my $trisp = $trisc{$_};
        $trisc_bsf .= "\tbsf $trisp, $trisp$_\n";
        $trisc_bcf .= "\tbcf $trisp, $trisp$_\n";
    }
    my $pstrcon_code = '';
    if ($type eq 'single') {
        $pstrcon_code = << "...";
\tbanksel PSTRCON
\tmovlw $pstrcon
\tmovwf PSTRCON
...
    }
    return (
        # actual register values
        CCP1CON => $ccp1con,
        PR2 => $pr2_x,
        T2CON => $t2con,
        CCPR1L => $ccpr1l_x,
        PSTRCON => $pstrcon,
        PSTRCON_CODE => $pstrcon_code,
        # no ECCPAS
        PWM1CON => '0x80', # default
        # code to be added
        TRISC_BSF => $trisc_bsf,
        TRISC_BCF => $trisc_bcf,
        # general comments
        CCPR1L_CCP1CON54 => $ccpr1l_ccp1con54,
        FOSC => $f_osc,
        PRESCALER => $prescaler,
        PWM_FREQUENCY => $pwm_frequency,
        DUTYCYCLE => $duty,
        PINS => \@pins,
        TYPE => $type,
    );
}

sub _pwm_code {
    my $self = shift;
    my %details = @_;
    my @pins = @{$details{PINS}};
    return << "...";
;;; PWM Type: $details{TYPE}
;;; PWM Frequency = $details{PWM_FREQUENCY} Hz
;;; Duty Cycle = $details{DUTYCYCLE} / 100
;;; CCPR1L:CCP1CON<5:4> = $details{CCPR1L_CCP1CON54}
;;; CCPR1L = $details{CCPR1L}
;;; CCP1CON = $details{CCP1CON}
;;; T2CON = $details{T2CON}
;;; PR2 = $details{PR2}
;;; PSTRCON = $details{PSTRCON}
;;; PWM1CON = $details{PWM1CON}
;;; Prescaler = $details{PRESCALER}
;;; Fosc = $details{FOSC}
;;; disable the PWM output driver for @pins by setting the associated TRIS bit
\tbanksel TRISC
$details{TRISC_BSF}
;;; set PWM period by loading PR2
\tbanksel PR2
\tmovlw $details{PR2}
\tmovwf PR2
;;; configure the CCP module for the PWM mode by setting CCP1CON
\tbanksel CCP1CON
\tmovlw $details{CCP1CON}
\tmovwf CCP1CON
;;; set PWM duty cycle
\tmovlw $details{CCPR1L}
\tmovwf CCPR1L
;;; configure and start TMR2
;;; - clear TMR2IF flag of PIR1 register
\tbanksel PIR1
\tbcf PIR1, TMR2IF
\tmovlw $details{T2CON}
\tmovwf T2CON
;;; enable PWM output after a new cycle has started
\tbtfss PIR1, TMR2IF
\tgoto \$ - 1
\tbcf PIR1, TMR2IF
;;; enable @pins pin output driver by clearing the associated TRIS bit
$details{PSTRCON_CODE}
;;; disable auto-shutdown mode
\tbanksel ECCPAS
\tclrf ECCPAS
;;; set PWM1CON if half bridge mode
\tbanksel PWM1CON
\tmovlw $details{PWM1CON}
\tmovwf PWM1CON
\tbanksel TRISC
$details{TRISC_BCF}
...
}

sub pwm_single {
    my ($self, $pwm_frequency, $duty, @pins) = @_;
    return unless $self->doesrole('ECCP');
    unless (exists $self->eccp_pins->{P1A}) {
        if (exists $self->eccp_pins->{CCP1}) {
            # override the pins to CCP1
            @pins = qw(CCP1);
        }
    }
    my %details = $self->_pwm_details($pwm_frequency, $duty, 'single', @pins);
    # pulse steering automatically taken care of
    return $self->_pwm_code(%details);
}

sub pwm_halfbridge {
    my ($self, $pwm_frequency, $duty, $deadband, @pins) = @_;
    return unless $self->doesrole('ECCP');
    if (exists $self->eccp_pins->{P1A} and exists $self->eccp_pins->{P1B}) {
        # we ignore the @pins that comes in
        @pins = qw(P1A P1B);
    } else {
        carp $self->type, " has no Enhanced PWM capabilities";
        return;
    }
    my %details = $self->_pwm_details($pwm_frequency, $duty, 'half', @pins);
    # override PWM1CON
    if (defined $deadband and $deadband > 0) {
        my $fosc = $details{FOSC};
        my $pwm1con = $deadband * $fosc / 4e6; # $deadband is in microseconds
        $pwm1con &= 0x7F; # 6-bits only
        $pwm1con |= 0x80; # clear PRSEN bit
        $details{PWM1CON} = sprintf "0x%02X", $pwm1con;
    }
    return $self->_pwm_code(%details);
}

sub pwm_fullbridge {
    my ($self, $direction, $pwm_frequency, $duty, @pins) = @_;
    return unless $self->doesrole('ECCP');
    if (defined $direction and ref $direction eq 'HASH') {
        $direction = $direction->{string};
    }
    my $type = 'full_forward';
    $type = 'full_reverse' if $direction =~ /reverse|backward|no?|0/i;
    if (exists $self->eccp_pins->{P1A} and exists $self->eccp_pins->{P1B} and
        exists $self->eccp_pins->{P1C} and exists $self->eccp_pins->{P1D}) {
        # we ignore the @pins that comes in
        @pins = qw(P1A P1B P1C P1D);
    } else {
        carp $self->type, " has no Enhanced PWM capabilities";
        return;
    }
    my %details = $self->_pwm_details($pwm_frequency, $duty, $type, @pins);
    return $self->_pwm_code(%details);
}

sub pwm_update {
    my ($self, $pwm_frequency, $duty) = @_;
    return unless $self->doesrole('ECCP');
    # hack into the existing functions to update only what we need
    my @pins = qw(CCP1);
    if (exists $self->eccp_pins->{P1A} and exists $self->eccp_pins->{P1B} and
        exists $self->eccp_pins->{P1C} and exists $self->eccp_pins->{P1D}) {
        # we ignore the @pins that comes in
        @pins = qw(P1A P1B P1C P1D);
    }
    my %details = $self->_pwm_details($pwm_frequency, $duty, 'single', @pins);
    my ($ccp1con5, $ccp1con4);
    $ccp1con4 = $details{CCPR1L_CCP1CON54} & 0x0001;
    $ccp1con5 = ($details{CCPR1L_CCP1CON54} >> 1) & 0x0001;
    if ($ccp1con4) {
        $ccp1con4 = "\tbsf CCP1CON, DC1B0";
    } else {
        $ccp1con4 = "\tbcf CCP1CON, DC1B0";
    }
    if ($ccp1con5) {
        $ccp1con5 = "\tbsf CCP1CON, DC1B1";
    } else {
        $ccp1con5 = "\tbcf CCP1CON, DC1B1";
    }
    return << "...";
;;; updating PWM duty cycle for a given frequency
;;; PWM Frequency = $details{PWM_FREQUENCY} Hz
;;; Duty Cycle = $details{DUTYCYCLE} / 100
;;; CCPR1L:CCP1CON<5:4> = $details{CCPR1L_CCP1CON54}
;;; CCPR1L = $details{CCPR1L}
;;; update CCPR1L and CCP1CON<5:4> or the DC1B[01] bits
$ccp1con4
$ccp1con5
\tmovlw $details{CCPR1L}
\tmovwf CCPR1L
...

}


1;
__END__
