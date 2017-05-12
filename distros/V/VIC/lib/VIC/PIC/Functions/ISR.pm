package VIC::PIC::Functions::ISR;
use strict;
use warnings;
our $VERSION = '0.31';
$VERSION = eval $VERSION;
use Carp;
use POSIX ();
use Moo::Role;

sub isr_var {
    my $self = shift;
    return unless $self->doesroles(qw(Chip ISR));
    my @common = @{$self->banks->{common}};
    my ($cb_start, $cb_end) = @common;
    if (ref $cb_start eq 'ARRAY') {
        ($cb_start, $cb_end) = @$cb_start;
    }
    $cb_start = 0x70 unless $cb_start;
    $cb_start = sprintf "0x%02X", $cb_start;
    return << "...";
cblock $cb_start ;; unbanked RAM that is common across all banks
ISR_STATUS
ISR_W
endc
...
}

sub isr_entry {
    my $self = shift;
    return unless $self->doesroles(qw(Chip ISR));
    unless (exists $self->registers->{STATUS}) {
        carp $self->type, " has no register named STATUS";
        return;
    }
    #TODO: high/low address ?
    my $isr_addr = $self->address->{isr}->[0];
    my $reset_addr = $self->address->{reset}->[0];
    my $count = $isr_addr - $reset_addr - 1;
    my $nops = '';
    for my $i (1 .. $count) {
        $nops .= "\tnop\n";
    }
    return << "...";
$nops
\torg $isr_addr
ISR:
_isr_entry:
\tmovwf ISR_W
\tmovf STATUS, W
\tmovwf ISR_STATUS
...
}

sub isr_exit {
    my $self = shift;
    return unless $self->doesroles(qw(Chip ISR));
    unless (exists $self->registers->{STATUS}) {
        carp $self->type, " has no register named STATUS";
        return;
    }
    return << "...";
_isr_exit:
\tmovf ISR_STATUS, W
\tmovwf STATUS
\tswapf ISR_W, F
\tswapf ISR_W, W
\tretfie
...
}

sub isr_timer {
    my $self = shift;
    return unless $self->doesroles(qw(Chip ISR));
    my $th = shift;
    return unless (defined $th and ref $th eq 'HASH');
    my $freg = $th->{freg};
    my $ereg = $th->{ereg};
    unless (exists $self->registers->{$freg} and exists $self->registers->{$ereg}) {
        carp $self->type, " has no register named $freg or $ereg";
        return;
    }
    my $tflag = $th->{flag};
    my $tenable = $th->{enable};
    my $treg = (ref $th->{reg} eq 'ARRAY') ? $th->{reg}->[0] : $th->{reg};
    my %isr = @_;
    if (%isr) {
        my $action_label = $isr{ISR};
        my $end_label = $isr{END};
        return unless $action_label;
        return unless $end_label;
        my $isr_label = '_isr_' . lc($treg);
        return  << "..."
$isr_label:
\tbtfss $freg, $tflag
\tgoto $end_label
\tbcf   $freg, $tflag
\tgoto $action_label
$end_label:
...
    } else {
        if ($freg eq 'INTCON' and $ereg eq 'INTCON') {
            return << "...";
;; enable interrupt servicing for $treg
\tbanksel $freg
\tbsf INTCON, GIE
\tbcf $freg, $tflag
\tbsf $ereg, $tenable
;; end of interrupt servicing
...
        } else {
            return << "...";
;; enable interrupt servicing for $treg
\tbanksel INTCON
\tbsf INTCON, GIE
\tbanksel $freg
\tbcf $freg, $tflag
\tbanksel $ereg
\tbsf $ereg, $tenable
;; end of interrupt servicing
...

        }
    }
}

sub isr_ioc {
    my $self = shift;
    return unless $self->doesroles(qw(Chip ISR));
    unless (exists $self->registers->{INTCON}) {
        carp $self->type, " has no register named INTCON";
        return;
    }
    my $ioch = shift;
    my $ipin = shift;
    return unless (defined $ioch and ref $ioch eq 'HASH');
    return unless defined $ipin;
    my $ioc_reg = $ioch->{reg};
    my $ioc_bit = $ioch->{bit};
    my $ioc_flag = $ioch->{flag};
    my $ioc_enable = $ioch->{enable};
    if (@_) {
        my ($var, $port, $portbit, %isr) = @_;
        my $action_label = $isr{ISR};
        my $end_label = $isr{END};
        return unless $action_label;
        return unless $end_label;
        my $isr_label;
        if (defined $ioc_bit) {
            $isr_label = '_isr_' . lc($ioc_bit);
        } elsif (defined $ioc_reg) {
            $isr_label = '_isr_' .lc($ioc_reg);
        } else {
            $isr_label = '_isr_' . lc($ipin);
        }
        my $code_ioc = '';
        if (defined $portbit) {
            $code_ioc = "\tbtfsc $port, $portbit\n\taddlw 0x01";
        } else {
            $code_ioc = "\tmovf $port, W";
        }
        return  << "..."
$isr_label:
\tbtfss INTCON, $ioc_flag
\tgoto $end_label
\tbcf   INTCON, $ioc_flag
\tbanksel $port
$code_ioc
\tbanksel $var
\tmovwf $var
\tgoto $action_label
$end_label:
...

    } else {
        my $code_en = '';
        if (defined $ioc_bit and defined $ioc_reg) {
            $code_en = "\tbanksel $ioc_reg\n\tbsf $ioc_reg, $ioc_bit";
        } elsif (defined $ioc_reg) {
            $code_en = "\tbanksel $ioc_reg\n\tclrf $ioc_reg\n\tcomf $ioc_reg, F";
        } else {
            # if ioc_reg/ioc_bit is not defined just move on
        }
        return << "...";
;; enable interrupt-on-change setup for $ipin
\tbanksel INTCON
\tbcf INTCON, $ioc_flag
\tbsf INTCON, GIE
\tbsf INTCON, $ioc_enable
$code_en
;; end of interrupt-on-change setup
...
    }
}


1;
__END__
