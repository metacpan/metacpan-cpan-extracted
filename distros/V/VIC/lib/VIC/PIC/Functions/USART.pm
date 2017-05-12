package VIC::PIC::Functions::USART;
use strict;
use warnings;
our $VERSION = '0.31';
$VERSION = eval $VERSION;
use Carp;
use POSIX ();
use Scalar::Util qw(looks_like_number);
use Moo::Role;

sub usart_setup {
    my ($self, $outp, $baudr) = @_;
    return unless $self->doesroles(qw(USART GPIO CodeGen Chip));
    return unless $outp =~ /UART|USART/;
    my $sync = ($outp =~ /^UART/) ? 0 : 1; # the other is USART
    my $ipin = $self->usart_pins->{async_in};
    my $opin = $self->usart_pins->{async_out};
    my $sclk = $self->usart_pins->{sync_clock};
    my $sdat = $self->usart_pins->{sync_data};
    return unless (defined $ipin and defined $opin);
    #return if ($sync == 1 and not defined $sclk and not defined $sdat);
    return unless (exists $self->pins->{$ipin} and exists $self->pins->{$opin});
    my ($code, $funcs, $macros, $tables) = ('', {}, {}, []);
    $macros->{m_usart_var} = $self->_usart_var;
    if (exists $self->registers->{SPBRGH} and
        exists $self->registers->{SPBRG} and
        exists $self->registers->{BAUDCTL}) {
        ## Enhanced USART (16-bit)
        ## Required registers TXSTA, RCSTA, BAUDCTL, TXREG, RCREG
        ## To enable the transmitter for asynchronous ops
        ## TXEN = 1, SYNC = 0, SPEN = 1
        ## if TX/CK pin is shared with analog I/O then clear the appropriate
        ## ANSEL bit
        ## find if the $ipin/$opin is shared with an analog pin
        my ($baud_code, $io_code, $an_code) = ('', '', '');
        my $key = $sync ? 'usart' : 'uart';
        ## calculate the Baud rate
        my $baudrate = $baudr;
        $baudrate = $self->code_config->{$key}->{baud} unless defined $baudr;
        # find closest approximation of baud-rate
        # if baud-rate not given assume 9600
        my $f_osc = $self->code_config->{$key}->{f_osc} || $self->f_osc;
        my $baudref = $self->usart_baudrates($baudrate, $f_osc, $sync);
        unless (ref $baudref eq 'HASH') {
            carp "Baud rate $baudrate cannot be supported";
            return;
        }
        my $spbrgh = sprintf "0x%02X", (($baudref->{SPBRG} >> 8) & 0xFF);
        my $spbrg = sprintf "0x%02X", ($baudref->{SPBRG} & 0xFF);
        my $baudctl_code = '';
        if ($baudref->{BRG16}) {
            $baudctl_code .= "\tbanksel BAUDCTL\n\tbsf BAUDCTL, BRG16\n";
        } else {
            $baudctl_code .= "\tbanksel BAUDCTL\n\tbcf BAUDCTL, BRG16\n";
        }
        if ($baudref->{BRGH}) {
            $baudctl_code .= "\tbanksel TXSTA\n\tbsf TXSTA, BRGH\n";
        } else {
            $baudctl_code .= "\tbanksel TXSTA\n\tbcf TXSTA, BRGH\n";
        }
        chomp $baudctl_code;
        my $cbaud = sprintf "%0.04f", $baudref->{actual};
        my $ebaud = sprintf "%0.06f%%", $baudref->{error};
        $baud_code .= <<"...";
;;;Desired Baud: $baudref->{baud}
;;;Calculated Baud: $cbaud
;;;Error: $ebaud
;;;SPBRG: $baudref->{SPBRG}
;;;BRG16: $baudref->{BRG16}
;;;BRGH: $baudref->{BRGH}
$baudctl_code
\tbanksel SPBRG
\tmovlw $spbrgh
\tmovwf SPBRGH
\tmovlw $spbrg
\tmovwf SPBRG
...
        if (exists $self->registers->{ANSEL}) {
            my $ipin_no = $self->pins->{$ipin};
            my $opin_no = $self->pins->{$opin};
            my $iallpins = $self->pins->{$ipin_no};
            my $oallpins = $self->pins->{$opin_no};
            unless (ref $iallpins eq 'ARRAY') {
                carp "Invalid data for pin $ipin_no";
                return;
            }
            unless (ref $oallpins eq 'ARRAY') {
                carp "Invalid data for pin $opin_no";
                return;
            }
            my @anpins = ();
            foreach (@$iallpins) {
                push @anpins, $_ if exists $self->analog_pins->{$_};
            }
            foreach (@$oallpins) {
                push @anpins, $_ if exists $self->analog_pins->{$_};
            }
            my $pansel = '';
            foreach (sort @anpins) {
                my ($pno, $pbit) = @{$self->analog_pins->{$_}};
                my $ansel = 'ANSEL';
                if (exists $self->registers->{ANSELH}) {
                    $ansel = ($pbit >= 8) ? 'ANSELH' : 'ANSEL';
                }
                if ($ansel ne $pansel) {
                    $an_code .= "\tbanksel $ansel\n";
                    $pansel = $ansel;
                }
                $an_code .= "\tbcf $ansel, ANS$pbit\n";
            }
        }
        unless (exists $self->registers->{TXSTA} and
            exists $self->registers->{RCSTA}) {
            carp "Register TXSTA & RCSTA are required for operations for $outp";
            return;
        }
        if ($sync) {
            #TODO
            carp "Synchronous operations not implemented\n";
            return;
        }
        $io_code .= <<"...";
\tbanksel TXSTA
\t;; asynchronous operation
\tbcf TXSTA, SYNC
\t;; transmit enable
\tbsf TXSTA, TXEN
\tbanksel RCSTA
\t;; serial port enable
\tbsf RCSTA, SPEN
\t;; continuous receive enable
\tbsf RCSTA, CREN
$an_code
...

        $code = <<"EUSARTCODE";
$baud_code
$io_code
EUSARTCODE
    } elsif (exists $self->registers->{SPBRG}) {
        ## USART (8-bit)
    } else {
        carp "$outp for chip ", $self->type, " is not supported";
        return;
    }
    return wantarray ? ($code, $funcs, $macros, $tables) : $code;
}

sub _usart_var {
    return <<'...';
;;;;;;; USART I/O VARS ;;;;;;
VIC_VAR_USART_UDATA udata
VIC_VAR_USART_WLEN res 1
VIC_VAR_USART_WIDX res 1
VIC_VAR_USART_RLEN res 1
VIC_VAR_USART_RIDX res 1
...
}

sub _usart_write_bytetbl {
    return <<"....";
m_usart_write_bytetbl macro tblentry, wlen
\tlocal _usart_write_bytetbl_loop_0
\tlocal _usart_write_bytetbl_loop_1
\tbanksel VIC_VAR_USART_WLEN
\tmovlw wlen
\tmovwf VIC_VAR_USART_WLEN
\tbanksel VIC_VAR_USART_WIDX
\tclrf VIC_VAR_USART_WIDX
_usart_write_bytetbl_loop_0:
\tmovf VIC_VAR_USART_WIDX, W
\tcall tblentry
\tbanksel TXREG
\tmovwf TXREG
\tbanksel TXSTA
\tbtfss TXSTA, TRMT
\tgoto \$ - 1
\tbanksel VIC_VAR_USART_WIDX
\tincf VIC_VAR_USART_WIDX, F
\tbcf STATUS, Z
\tbcf STATUS, C
\tmovf VIC_VAR_USART_WIDX, W
\tsubwf VIC_VAR_USART_WLEN, W
\t;; W == 0
\tbtfsc STATUS, Z
\tgoto _usart_write_bytetbl_loop_1
\tgoto _usart_write_bytetbl_loop_0
_usart_write_bytetbl_loop_1:
\t;; finish the sending
\tbanksel TXSTA
\tbtfss TXSTA, TRMT
\tgoto \$ - 1
\tbanksel VIC_VAR_USART_WIDX
\tclrf VIC_VAR_USART_WIDX
\tclrf VIC_VAR_USART_WLEN
\tendm
....
}

sub _usart_write_byte {
    return <<"....";
m_usart_write_byte macro wvar
\tbanksel wvar 
\tmovf wvar, W
\tbanksel TXREG
\tmovwf TXREG
\tbanksel TXSTA
\tbtfss TXSTA, TRMT
\tgoto \$ - 1
\tendm
....
}

sub _usart_write_bytes {
    return <<"....";
m_usart_write_bytes macro wvar, wlen
\tlocal _usart_write_bytes_loop_0
\tlocal _usart_write_bytes_loop_1
\tbanksel VIC_VAR_USART_WLEN
\tmovlw (wlen - 1)
\tmovwf VIC_VAR_USART_WLEN
\tclrf VIC_VAR_USART_WIDX
\tbanksel wvar
\tmovlw (wvar - 1) ;; load address into FSR
\tmovwf FSR
_usart_write_bytes_loop_0:
\tincf FSR, F  ;; increment the FSR pointer
\tmovf INDF, W ;; load byte into register
\tbanksel TXREG
\tmovwf TXREG
\tbanksel TXSTA
\tbtfss TXSTA, TRMT
\tgoto \$ - 1
\tbanksel VIC_VAR_USART_WIDX
\tincf VIC_VAR_USART_WIDX, F
\tbcf STATUS, Z
\tbcf STATUS, C
\tmovf VIC_VAR_USART_WIDX, W
\tsubwf VIC_VAR_USART_WLEN, W
\t;; W == 0
\tbtfsc STATUS, Z
\tgoto _usart_write_bytes_loop_1
\tgoto _usart_write_bytes_loop_0
_usart_write_bytes_loop_1:
\tbanksel TXSTA
\tbtfss TXSTA, TRMT
\tgoto \$ - 1
\tbanksel VIC_VAR_USART_WIDX
\tclrf VIC_VAR_USART_WIDX
\tclrf VIC_VAR_USART_WLEN
\tendm
....
}

sub _usart_read_byte {
    # TODO: check RX9 for 9th-bit
    return <<"...";
m_usart_read_byte macro rvar
\tlocal _usart_read_byte_0
\tbanksel VIC_VAR_USART_RIDX
\tclrf VIC_VAR_USART_RIDX
\tbanksel PIR1
\tbtfss PIR1, RCIF
\tgoto \$ - 1
\tbtfsc RCSTA, OERR
\tbcf RCSTA, CREN
\tbtfsc RCSTA, FERR
\tbcf RCSTA, CREN
_usart_read_byte_0:
\tbanksel RCREG
\tmovf RCREG, W
\tbanksel rvar
\tmovwf rvar
\tbanksel RCSTA
\tbtfss RCSTA, CREN
\tbsf RCSTA, CREN
\tendm
...
}

sub usart_write {
    my ($self, $outp, $data) = @_;
    return unless $self->doesroles(qw(USART GPIO CodeGen Chip));
    return unless $outp =~ /US?ART/;
    return unless defined $data;
    my ($code, $funcs, $macros, $tables) = ('', {}, {}, []);
    # check if $data is a string or value or variable
    my @bytearr = ();
    my $nstr;
    my $table_entry = '';
    my $szvar;
    if (ref $data eq 'HASH') {
        if (exists $data->{type}) {
            # this is a variable with data
            unless ($data->{type} eq 'string') {
                carp "Only string variables can use this part of the code";
                return;
            }
            $szvar = $data->{size};
            $data = $data->{name};
            $code .= ";;; sending contents of the variable '$data' of size '$szvar' to $outp\n";
        } else {
            # this is a string
            $nstr = $data->{string};
            my $nstr2 = $nstr;
            $nstr2 =~ s/[\n]/\\n/gs;
            $nstr2 =~ s/[\r]/\\r/gs;
            $code .= ";;; sending the string '$nstr2' to $outp\n";
            @bytearr = split //, $nstr;
            push @$tables, {
                bytes => [(map { sprintf "0x%02X", ord($_) } @bytearr), "0x00"],
                name => $data->{name},
                comment => "\t;;storing string '$nstr2'",
            };
            $table_entry = $data->{name};
        }
    } else {
        if (looks_like_number($data)) {
            $code .= ";;; sending the number '$data' to $outp in big-endian mode\n";
            my $nstr = pack "N", $data;
            $nstr =~ s/^\x00{1,3}//g; # remove the beginning nulls
            @bytearr = split //, $nstr;
            $table_entry = sprintf("_vic_bytes_0x%02X", $data);
            push @$tables, {
                bytes => [(map { sprintf "0x%02X", ord($_) } @bytearr), "0x00"],
                name => $table_entry,
                comment => "\t;;storing number $data",
            };
        } else {
            $code .= ";;; sending the variable '$data' to $outp\n";
        }
    }
    if (@bytearr) {
        ## length has to be 1 byte only
        ## use TXREG and TRMT bit of TXSTA to check if it is done
        ## by polling the TRMT check
        ## use DECFSZ to manage the loop
        ## use a table to store multiple strings/byte arrays
        ## TODO: call store_string() to store the string/array of bytes
        ## the best way is to store all strings as temporary variables and
        ## send the variable into the functions to be detected appropriately
        ## use the dt directive to store each string entry in a table
        ## the byte arrays generated by a number can be pushed back using a
        ## temporary variable
        if (scalar @bytearr > 256) {
            carp "Warning: Cannot write more than 256 bytes at a time to $outp. You tried to write ", scalar @bytearr;
        }
        my $len = scalar(@bytearr) < 256 ? scalar(@bytearr) : 0xFF;
        $len = sprintf "0x%02X", $len;
        $macros->{m_usart_write_bytetbl} = $self->_usart_write_bytetbl;
        $code .= <<"...";
;;;; byte array has length $len
\tm_usart_write_bytetbl $table_entry, $len
...
    } elsif (defined $szvar) {
        ## multiple bytes writing
        $macros->{m_usart_write_bytes} = $self->_usart_write_bytes;
        $data = uc $data;
        $code .= <<"...";
\tm_usart_write_bytes $data, $szvar
...
    } else {
        $macros->{m_usart_write_byte} = $self->_usart_write_byte;
        $data = uc $data;
        $code .= <<"...";
\tm_usart_write_byte $data
...
    }
    return wantarray ? ($code, $funcs, $macros, $tables) : $code;
}

sub usart_read {
    my $self = shift;
    my $inp = shift;
    my $var = undef;
    my %action = ();
    if (scalar(@_) == 1) {
        $var = shift;
    } elsif (scalar(@_) > 1){
        %action = @_;
    } else {
        carp 'Invalid invocation of usart_read() function';
        return;
    }
    return unless $self->doesroles(qw(USART GPIO CodeGen Chip));
    return unless $inp =~ /US?ART/;
    my ($code, $funcs, $macros, $tables) = ('', {}, {}, []);
    unless (defined $var) {
        if (defined $action{PARAM}) {
            $var = $action{PARAM} . '0';
        } else {
            carp "Implementation errors implementing the Action block";
            return;
        }
        $var = uc $var;
        $macros->{lc("m_read_$var")} = $self->_macro_read_var($var);
        return unless (defined $action{ACTION} or defined $action{ISR});
        return unless defined $action{END};
    }
    $macros->{m_usart_read_byte} = $self->_usart_read_byte;
    $code .= <<"...";
;;;; reading single byte on the $inp port
\tm_usart_read_byte $var
...
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
            my $pictype = $self->type;
            unless ($self->doesrole('ISR')) {
                carp "$pictype does not do the ISR role";
                return;
            }
            my $rx_int = $self->usart_pins->{rx_int};
            carp "rx_int not defined for $pictype" and return unless $rx_int;
            my $isr_label = lc "isr_rx_$inp"; # required by receiver
            $code = ";;;; $inp read is done using $isr_label";
            $code .= $self->_usart_isr_setup($inp, $rx_int);
            $funcs->{$isr_label} = $self->_usart_isr_read($inp, $rx_int, %action);
        } else {
            carp "Unknown action requested. Probably a bug in implementation";
            return;
        }
    }
    return wantarray ? ($code, $funcs, $macros, $tables) : $code;
}

sub _usart_isr_setup {
    my $self = shift;
    my $inp = shift;
    my $href = shift;
    return unless (defined $href and ref $href eq 'HASH');
    unless (exists $self->registers->{INTCON}) {
        carp $self->type, " has no register named INTCON";
        return;
    }
    my $reg = $href->{reg};
    my $enable = $href->{enable};
    my $preg = $href->{preg};
    my $penable = $href->{penable};
    my $code = << "...";
;;; enable interrupt servicing for $inp
\tbanksel INTCON
\tbsf INTCON, GIE
...
    if ($preg eq 'INTCON') {
        $code .= "\tbsf $preg, $penable\n";
    } else {
        $code .= "\tbanksel $preg\n\tbsf $preg, $penable\n";
    }
    $code .= << "...";
\tbanksel $reg
\tbsf $reg, $enable
;;; end of interrupt servicing for $inp
...
    return $code;
}

sub _usart_isr_read {
    my $self = shift;
    my $inp = shift;
    my $href = shift;
    my %isr = @_;
    return unless (defined $href and ref $href eq 'HASH');
    return unless (defined $isr{ISR} and $isr{END});
    my $reg = $href->{reg};
    my $enable = $href->{enable};
    my $flag = $href->{flag};
    my $begin_label = $isr{ISR};
    my $end_label = $isr{END};
    my $isr_var_code = '';
    if (defined $isr{PARAM}) {
        my $ivar = uc ($isr{PARAM} . '0');
        $isr_var_code = "\tbanksel $ivar\n\tmovwf $ivar\n";
    }
    my $isr_label = lc "_isr_rx_$inp"; # required by receiver to be this way
    return << "....";
$isr_label:
\tbanksel $reg
\tbtfss $reg, $flag
\tgoto $end_label
\tbtfsc RCSTA, OERR
\tbcf RCSTA, CREN
\tbtfsc RCSTA, FERR
\tbcf RCSTA, CREN
\tbanksel RCREG
\tmovf RCREG, W
$isr_var_code
\tbanksel RCSTA
\tbtfss RCSTA, CREN
\tbsf RCSTA, CREN
\tgoto $begin_label
$end_label:
....
}

1;
__END__
