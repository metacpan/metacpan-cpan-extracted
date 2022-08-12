package VIC::PIC::Functions::CodeGen;
use strict;
use warnings;
our $VERSION = '0.32';
$VERSION = eval $VERSION;
use Carp;
use POSIX ();
use Moo::Role;

# default
has org => (is => 'ro', default => 0);
has code_config => (is => 'rw', default => sub {
        {
            debounce => {
                count => 5,
                delay => 1000, # in microseconds
            },
            adc => {
                right_justify => 1,
                vref => 0,
                internal => 0,
            },
            variable => {
                bits => 8, # bits. same as register_size
                export => 0, # do not export variables
            },
            string => {
                size => 32, # character allocation of null strings
            },
            uart => {
                baud => 9600, # baud rate
                bit9 => 0, # allow 9 bits
            },
            usart => {
                baud => 9600, # baud rate
                bit9 => 0, # allow 9 bits
            },
        }
});

sub validate {
    my ($self, $var) = @_;
    return undef unless defined $var;
    return 0 if $var =~ /^\d+$/;
    return 0 unless $self->doesrole('Chip');
    return 1 if exists $self->pins->{$var};
    return 1 if exists $self->registers->{$var};
    return 1 if ($self->doesrole('Timer', 1) and exists $self->timer_pins->{$var});
    return 1 if ($self->doesrole('Timer', 1) and exists $self->wdt_prescaler->{$var});
    return 1 if ($self->doesrole('USART', 1) and exists $self->usart_pins->{$var});
    return 0;
}

sub validate_operator {
    my ($self, $op) = @_;
    my $vop = "op_$op" if $op =~ /^
            LE | GE | GT | LT | EQ | NE |
            ADD | SUB | MUL | DIV | MOD |
            BXOR | BOR | BAND | AND | OR | SHL | SHR |
            ASSIGN | INC | DEC | NOT | COMP |
            TBLIDX | ARRIDX | STRIDX
        /x;
    return lc $vop if defined $vop;
}

sub validate_modifier_operator {
    my ($self, $mod) = @_;
    my $vmod = "op_$mod" if $mod =~ /^
            SQRT | HIGH | LOW
        /x;
    return lc $vmod if defined $vmod;
}

sub update_code_config {
    my ($self, $grp, $key, $val) = @_;
    return unless $self->doesrole('CodeGen');
    return unless defined $grp;
    $grp = lc $grp; # force lower case in case of usage for things like SPI/UART/I2C
    $self->code_config->{$grp} = {} unless exists $self->code_config->{$grp};
    my $grpref = $self->code_config->{$grp};
    if ($key eq 'bits') {
        $val = 8 unless defined $val;
        $val = 8 if $val <= 8;
        $val = 16 if ($val > 8 and $val <= 16);
        $val = 32 if ($val > 16 and $val <= 32);
        carp "$val-bits is not supported. Maximum supported size is 64-bit"
            if $val > 64;
        $val = 64 if $val > 32;
    }
    $val = 1 unless defined $val;
    if (ref $grpref eq 'HASH') {
        $grpref->{$key} = $val;
    } else {
        $self->code_config->{$grp} = { $key => $val };
    }
    1;
}

sub address_bits {
    my ($self, $varname) = @_;
    return unless $self->doesrole('CodeGen');
    my $bits = $self->code_config->{variable}->{bits};
    return $bits unless $varname;
    $bits = $self->code_config->{lc $varname}->{bits} || $bits;
    return $bits;
}

sub is_variable {
    my ($self, $varname) = @_;
    return unless $varname;
    return unless $self->doesrole('CodeGen');
    return 1 if defined $self->code_config->{lc $varname};
    return 0;
}


1;
__END__
