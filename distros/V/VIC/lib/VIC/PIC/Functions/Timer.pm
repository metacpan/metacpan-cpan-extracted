package VIC::PIC::Functions::Timer;
use strict;
use warnings;
our $VERSION = '0.32';
$VERSION = eval $VERSION;
use Carp;
use POSIX ();
use Moo::Role;

sub _get_timer_prescaler {
    my ($self, $freq) = @_;
    my $f_osc = $self->f_osc;
    my $scale = POSIX::ceil(($f_osc / 4) / $freq); # assume prescaler = 1 here
    if ($scale <=2) {
        $scale = 2;
    } elsif ($scale > 2 && $scale <= 4) {
        $scale = 4;
    } elsif ($scale > 4 && $scale <= 8) {
        $scale = 8;
    } elsif ($scale > 8 && $scale <= 16) {
        $scale = 16;
    } elsif ($scale > 16 && $scale <= 32) {
        $scale = 32;
    } elsif ($scale > 32 && $scale <= 64) {
        $scale = 64;
    } elsif ($scale > 64 && $scale <= 128) {
        $scale = 128;
    } elsif ($scale > 128 && $scale <= 256) {
        $scale = 256;
    } else {
        $scale = 256;
    }
    my $psx = $self->timer_prescaler->{$scale} || $self->timer_prescaler->{256};
    return $psx;
}

sub _get_wdt_prescaler {
    my ($self, $period) = @_;
    my $lfintosc = $self->wdt_prescaler->{LFINTOSC};
    #period is in microseconds. convert to seconds
    $period = ($period * 1.0) / 1.0e6;
    my $scale = POSIX::floor($lfintosc * $period);
    my $wdtps = $self->wdt_prescaler->{WDT};
    my @psv = sort { $a <=> $b } keys %$wdtps;
    my $minscale = $psv[0];
    foreach (@psv) {
        ## if the scale is 25% above the level, just use the lower level instead
        #of the higher level
        if ($scale <= ($_ + $_ / 4)) {
            return wantarray ? ($_, $wdtps->{$_}) : $wdtps->{$_};
        }
    }
    my $maxscale = pop @psv;
    return wantarray ? ($maxscale, $wdtps->{$maxscale}) : $wdtps->{$maxscale};
}

sub timer_enable {
    my ($self, $tmr, $freq, %isr) = @_;
    return unless $self->doesroles(qw(Timer Chip));
    my ($code, $funcs, $macros) = ('', {}, {});
    if ($tmr eq 'WDT') {
        unless (exists $self->registers->{WDTCON}) {
            carp $self->type, " does not have the register WDTCON";
            return;
        }
        if (defined $self->chip_config->{on_off}) {
            foreach (keys %{$self->chip_config->{on_off}}) {
                $self->chip_config->{on_off}->{$_} = 1 if $_ =~ /WDT/;
            }
        }
        my ($wdtps, $wdtpsbits) = $self->_get_wdt_prescaler($freq);
        $code = << "...";
;;; Period is $freq us so scale is 1:$wdtps
\tclrwdt
\tclrw
\tbanksel WDTCON
\tiorlw B'000${wdtpsbits}1'
\tmovwf WDTCON
...
    } else {
        unless (exists $self->timer_pins->{$tmr}) {
            carp "$tmr is not a timer.";
            return;
        }
        unless (exists $self->registers->{OPTION_REG}) {
            carp $self->type, " does not have the register OPTION_REG";
            return;
        }
        my $psx = $self->_get_timer_prescaler($freq);
        my $th = $self->timer_pins->{$tmr};
        unless (ref $th eq 'HASH') {
            carp "$tmr does not have a HASH ref as its value";
            return;
        }
        $code = << "...";
;; timer prescaling
\tbanksel OPTION_REG
\tclrw
\tiorlw B'00000$psx'
\tmovwf OPTION_REG
...
        my $end_code = << "...";
;; clear the timer
\tbanksel $tmr
\tclrf $tmr
...
        if (%isr) {
            $code .= $self->isr_timer($th);
        }
        $code .= "\n$end_code\n";
        if (%isr) {
            $funcs->{isr_timer} = $self->isr_timer($th, %isr);
        }
    }
    return wantarray ? ($code, $funcs, $macros) : $code;
}

sub timer_disable {
    my ($self, $tmr) = @_;
    return unless $self->doesroles(qw(Timer Chip));
    unless (exists $self->timer_pins->{$tmr}) {
        carp "$tmr is not a timer.";
        return;
    }
    unless (exists $self->registers->{OPTION_REG} and
        exists $self->registers->{INTCON}) {
        carp $self->type, " does not have the register OPTION_REG/INTCON";
        return;
    }
    my $th = $self->timer_pins->{$tmr};
    my $tm_en = $th->{enable} || 'T0IE';
    my $tm_ereg = $th->{ereg} || 'INTCON';
    return << "...";
\tbanksel $tm_ereg
\tbcf $tm_ereg, $tm_en ;; disable only the timer bit
\tbanksel OPTION_REG
\tmovlw B'00001000'
\tmovwf OPTION_REG
\tbanksel $tmr
\tclrf $tmr
...

}

sub timer {
    my ($self, $tmr, %action) = @_;
    return unless exists $action{ACTION};
    return unless $self->doesroles(qw(Timer Chip));
    return unless exists $action{END};
    unless (exists $self->registers->{INTCON}) {
        carp $self->type, " does not have the register INTCON";
        return;
    }
    my $th = $self->timer_pins->{$tmr};
    my $tm_f = $th->{flag} || 'T0IF';
    my $tm_freg = $th->{freg} || 'INTCON';
    return << "...";
\tbtfss $tm_freg, $tm_f
\tgoto $action{END}
\tbcf $tm_freg, $tm_f
\tgoto $action{ACTION}
$action{END}:
...
}

1;
__END__
