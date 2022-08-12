package VIC::PIC::Functions::ADC;
use strict;
use warnings;
our $VERSION = '0.32';
$VERSION = eval $VERSION;
use Carp;
use POSIX ();
use Moo::Role;

sub adc_enable {
    my $self = shift;
    return unless $self->doesroles(qw(GPIO ADC Chip CodeGen));
    unless (defined $self->adc_channels and $self->adc_channels > 0) {
        carp $self->type, " has no ADC";
        return;
    }
    unless (exists $self->registers->{ADCON0} and
            exists $self->registers->{ADCON1}) {
        carp $self->type, " has no valid ADCON0/ADCON1 registers";
        return;
    }
    if (@_) {
        my ($clock, $channel) = @_;
        my $f_osc = $self->f_osc;
        my $scale = POSIX::ceil(($f_osc / 4) / $clock) if $clock > 0;
        $scale = 2 unless $clock;
        $scale = 2 if $scale < 2;
        my $adcs = $self->adcs_bits->{$scale};
        $adcs = $self->adcs_bits->{internal} if $self->code_config->{adc}->{internal};
        my $adcon1 = "0$adcs" . '0000';
        my $code = << "...";
\tbanksel ADCON1
\tmovlw B'$adcon1'
\tmovwf ADCON1
...
        if (defined $channel) {
            my $adfm = defined $self->code_config->{adc}->{right_justify} ?
            $self->code_config->{adc}->{right_justify} : 1;
            my $vcfg = $self->code_config->{adc}->{vref} || 0;
            my $chs = $self->adc_chs_bits->{$channel};
            my $adcon0 = "$adfm$vcfg$chs" . '01';
            $code .= << "...";
\tbanksel ADCON0
\tmovlw B'$adcon0'
\tmovwf ADCON0
...
        }
        return $code;
    }
    # no arguments have been given
    return << "...";
\tbanksel ADCON0
\tbsf ADCON0, ADON
...
}

sub adc_disable {
    my $self = shift;
    return unless $self->doesroles(qw(ADC));
    unless (defined $self->adc_channels and $self->adc_channels > 0) {
        carp $self->type, " has no ADC";
        return;
    }
    unless (exists $self->registers->{ADCON0}) {
        carp $self->type, " has no valid ADCON0/ADCON1 registers";
        return;
    }
    return << "...";
\tbanksel ADCON0
\tbcf ADCON0, ADON
...
}

sub adc_read {
    #TODO: if the variable is 16-bit the varlow should be auto-adjusted
    my ($self, $varhigh, $varlow) = @_;
    return unless $self->doesroles(qw(ADC GPIO Chip));
    unless (defined $self->adc_channels and $self->adc_channels > 0) {
        carp $self->type, " has no ADC";
        return;
    }
    $varhigh = uc $varhigh;
    $varlow = uc $varlow if defined $varlow;
    unless (exists $self->registers->{ADCON0} and
        exists $self->registers->{ADRESH} and
        exists $self->registers->{ADRESL}) {
        carp $self->type, " has no valid ADCON0/ADRESH/ADRESL registers";
        return;
    }
    my $code = << "...";
\t;;;delay 5us
\tnop
\tnop
\tnop
\tnop
\tnop
\tbsf ADCON0, GO
\tbtfss ADCON0, GO
\tgoto \$ - 1
\tmovf ADRESH, W
\tmovwf $varhigh
...
    $code .= "\tmovf ADRESL, W\n\tmovwf $varlow\n" if defined $varlow;
    return $code;
}

1;
__END__
