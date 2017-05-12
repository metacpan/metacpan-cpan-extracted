package VIC::PIC::Gpsim;
use strict;
use warnings;
use bigint;
use Carp;
use Pegex::Base; # use this instead of Mo

our $VERSION = '0.31';
$VERSION = eval $VERSION;

has type => 'gpsim';

has include => 'coff.inc';

has pic => undef; # refer to the PIC object

has node_count => 0;

has scope_channels => 0;

has stimulus_count => 0;

has should_autorun => 0;

has disable => 0;

sub supports_modifier {
    my $self = shift;
    my $mod = shift;
    return 1 if $mod =~ /^(?:every|wave)$/i;
    0;
}

sub init_code {
    my $self = shift;
    croak "This chip is not supported" unless $self->pic->doesroles(qw(Chip CodeGen GPIO));
    my $pic = '';
    $pic = $self->pic->type if $self->pic;
    my $freq = $self->pic->f_osc if $self->pic;
    if ($freq) {
        $freq = qq{\t.sim "$pic.frequency = $freq"};
    } else {
        $freq = '';
    }
    return << "...";
;;;; generated common code for the Simulator
\t.sim "module library libgpsim_modules"
\t.sim "$pic.xpos = 200"
\t.sim "$pic.ypos = 200"
$freq
...
}

sub _gen_led {
    my $self = shift;
    my ($id, $x, $y, $name, $port, $color) = @_;
    if (defined $color and ref $color eq 'HASH') {
        $color = $color->{string};
    }
    $color = 'red' unless defined $color;
    $color = 'red' unless $color =~ /red|orange|green|yellow|blue/i;
    $color = lc $color;
    $color = substr ($color, 1) if $color =~ /^@/;
    return << "...";
\t.sim "module load led L$id"
\t.sim "L$id.xpos = $x"
\t.sim "L$id.ypos = $y"
\t.sim "L$id.color = $color"
\t.sim "node $name"
\t.sim "attach $name $port L$id.in"
...
}


sub _get_gpio_info {
    my ($self, $port) = @_;
    my $gpio_pin = $self->pic->get_input_pin($port);
    if ($gpio_pin) {
        # this is a pin
        return @{$self->pic->input_pins->{$gpio_pin}};
    } else {
        $gpio_pin = $self->pic->get_output_pin($port);
        if ($gpio_pin) {
            # this is a pin
            return @{$self->pic->output_pins->{$gpio_pin}};
        }
    }
    return;
}

sub _get_simreg {
    my ($self, $port) = @_;
    my $simreg = lc $port;
    if ($self->pic) {
        if (exists $self->pic->registers->{$port}) {
            # this is a port
            $simreg = lc $port;
        } elsif (exists $self->pic->pins->{$port}) {
            my ($io1) = $self->_get_gpio_info($port);
            if (defined $io1) {
                $simreg = lc $io1;
            } else {
                my $pic = $self->pic->type;
                carp "Cannot find '$port' in PIC $pic. Using '$simreg'";
            }
        } else {
            my $pic = $self->pic->type;
            carp "Cannot find '$port' in PIC $pic. Using '$simreg'";
        }
    }
    return $simreg;
}

sub _get_simport {
    my ($self, $port, $pin) = @_;
    my $simport = lc $port;
    if ($self->pic) {
        if (exists $self->pic->registers->{$port}) {
            # this is a port
            $simport = lc $port;
            $simport .= $pin if defined $pin;
        } elsif (exists $self->pic->pins->{$port}) {
            my ($io1, $io2, $io3) = $self->_get_gpio_info($port);
            if (defined $io1 and defined $io3) {
                $simport = lc "$io1$io3";
            } else {
                my $pic = $self->pic->type;
                carp "Cannot find '$port' in PIC $pic. Using '$simport'";
            }
        } else {
            my $pic = $self->pic->type;
            carp "Cannot find '$port' in PIC $pic. Using '$simport'";
        }
    }
    return $simport;
}

sub _get_portpin {
    my ($self, $port) = @_;
    my $simport = lc $port;
    my $simpin;
    if ($self->pic) {
        if (exists $self->pic->registers->{$port}) {
            # this is a port
            $simport = lc $port;
        } elsif (exists $self->pic->pins->{$port}) {
            my ($io1, $io2, $io3) = $self->_get_gpio_info($port);
            if (defined $io1) {
                $simport = lc $io1;
                $simpin = $io3;
            } else {
                my $pic = $self->pic->type;
                carp "Cannot find '$port' in PIC $pic. Using '$simport'";
            }
        } else {
            return;
        }
    }
    return wantarray ? ($simport, $simpin) : $simport;
}

sub attach_led {
    my ($self, $port, $count, $color) = @_;
    $count = 1 unless $count;
    $count = 1 if int($count) < 1;
    my $code = '';
    if ($count == 1) {
        my $c = $self->node_count;
        my $node = lc $port . 'led';
        $self->node_count($c + 1);
        my $x = ($c >= 4) ? 400 : 100;
        my $y = 50 + 50 * $c;
        # use the default pin 0 here
        my $simport = $self->_get_simport($port, 0);
        $code = $self->_gen_led($c, $x, $y, $node, $simport, $color);
    } else {
        $count--;
        if ($self->pic) {
            for (0 .. $count) {
                my $c = $self->node_count + $_;
                my $x = ($_ >= 4) ? 400 : 100;
                my $y = 50 + 50 * $c;
                my $node = lc $port . $c . 'led';
                my $simport = $self->_get_simport($port, $_);
                $code .= $self->_gen_led($c, $x, $y, $node, $simport, $color);
            }
            $self->node_count($self->node_count + $count + 1);
        }
    }
    return $code;
}

sub attach_led7seg {
    my ($self, @pins) = @_;
    my $code = '';
    my @simpins = ();
    my $color = 'red';
    foreach my $p (@pins) {
        if (defined $p and ref $p eq 'HASH') {
            $p = $p->{string};
            next unless defined $p;
        }
        if (exists $self->pic->pins->{$p}) {
            push @simpins, $p;
        } elsif (exists $self->pic->registers->{$p}) {
            # find all the output pins for the port
            foreach (sort(keys %{$self->pic->output_pins})) {
                next unless defined $self->pic->output_pins->{$_}->[0];
                push @simpins, $_ if $self->pic->output_pins->{$_}->[0] eq $p;
            }
        } elsif ($p =~ /red|orange|green|yellow|blue/i) {
            $color = $p;
            $color = substr($p, 1) if $p =~ /^@/;
            next;
        } else {
            carp "Ignoring port $p as it doesn't exist\n";
        }
    }
    return unless scalar @simpins;
    my $id = $self->node_count;
    $self->node_count($id + 1);
    my $x = 500;
    my $y = 50 + 50 * $id;
    $code .= << "...";
\t.sim "module load led_7segments L$id"
\t.sim "L$id.xpos = $x"
\t.sim "L$id.ypos = $y"
...
    my @nodes = qw(cc seg0 seg1 seg2 seg3 seg4 seg5 seg6);
    foreach my $n (@nodes) {
        my $p = shift @simpins;
        my $sp = $self->_get_simport($p);
        $code .= << "...";
\t.sim "node $n"
\t.sim "attach $n $sp L$id.$n"
...
    }
    return $code;
}

sub stop_after {
    my ($self, $usecs) = @_;
    # convert $secs to cycles
    my $cycles = $usecs * 10;
    my $code = << "...";
\t.sim "break c $cycles"
...
    return $code;
}

sub logfile {
    my ($self, $file) = @_;
    $file = "vicsim.log" unless defined $file;
    if (ref $file eq 'HASH') {
        $file = $file->{string} || 'vicsim.log';
    }
    $file = substr($file, 1) if $file =~ /^@/;
    return "\t.sim \"log lxt $file\"\n" if $file =~ /\.lxt/i;
    return "\t.sim \"log on $file\"\n";
}

sub log {
    my $self = shift;
    my $code = '';
    foreach my $port (@_) {
        if ($port =~ /US?ART/) {
            next unless $self->pic->doesrole('USART');
            my $ipin = $self->pic->usart_pins->{async_in};
            my $opin = $self->pic->usart_pins->{async_out};
            if (defined $ipin and defined $opin) {
                my $ireg = $self->_get_simreg($ipin);
                my $oreg = $self->_get_simreg($opin);
                $code .= $self->log($ipin);
                $code .= $self->log($opin) if $ireg ne $oreg;
            }
        } else {
            my $reg = $self->_get_simreg($port);
            next unless $reg;
            $code .= << "...";
\t.sim "log r $reg"
\t.sim "log w $reg"
...
        }
    }
    return $code;
}

sub _set_scope {
    my ($self, $port) = @_;
    my $simport = $self->_get_simport($port);
    my $chnl = $self->scope_channels;
    carp "Maximum of 8 channels can be used in the scope\n" if $chnl > 7;
    return '' if $chnl > 7;
    if (lc($simport) eq lc($port)) {
        my @code = ();
        for (0 .. 7) {
            $simport = $self->_get_simport($port, $_);
            if ($self->scope_channels < 8) {
                $chnl = $self->scope_channels;
                push @code, "\t.sim \"scope.ch$chnl = \\\"$simport\\\"\"";
                $self->scope_channels($chnl + 1);
            }
            carp "Maximum of 8 channels can be used in the scope\n" if $chnl > 7;
            last if $chnl > 7;
        }
        return join("\n", @code);
    } else {
        $self->scope_channels($chnl + 1);
        return << "...";
\t.sim "scope.ch$chnl = \\"$simport\\""
...
    }
}

sub scope {
    my $self = shift;
    my $code = '';
    foreach my $port (@_) {
        if ($port =~ /US?ART/) {
            next unless $self->pic->doesrole('USART');
            my $ipin = $self->pic->usart_pins->{async_in};
            my $opin = $self->pic->usart_pins->{async_out};
            $code .= $self->_set_scope($ipin) if defined $opin;
            $code .= $self->_set_scope($opin) if defined $opin;
        } else {
            $code .= $self->_set_scope($port);
        }
    }
    return $code;
}

### have to change the operator back to the form acceptable by gpsim
sub _get_operator {
    my $self = shift;
    my $op = shift;
    return '==' if $op eq 'EQ';
    return '!=' if $op eq 'NE';
    return '>' if $op eq 'GT';
    return '>=' if $op eq 'GE';
    return '<' if $op eq 'LT';
    return '<=' if $op eq 'LE';
    return undef;
}

sub sim_assert {
    my ($self, $condition, $msg) = @_;
    my $assert_msg;
    if ($condition =~ /@@/) {
        my @args = split /@@/, $condition;
        my $literal = qr/^\d+$/;
        if (scalar @args == 3) {
            my $lhs = shift @args;
            my $op = shift @args;
            my $rhs = shift @args;
            my $op2 = $self->_get_operator($op);
            if ($lhs !~ $literal) {
                my ($port, $pin) = $self->_get_portpin($lhs);
                if (defined $pin) {
                    my $pval = sprintf "0x%02X", (1 << $pin);
                    $lhs = lc "($port & $pval)";
                } elsif (defined $port) {
                    $lhs = lc $port;
                } else {
                    # may be a variable
                    $lhs = uc $lhs;
                }
            } else {
                $lhs = sprintf "0x%02X", $lhs;
            }
            if ($rhs !~ $literal) {
                my ($port, $pin) = $self->_get_portpin($lhs);
                if (defined $pin) {
                    my $pval = sprintf "0x%02X", (1 << $pin);
                    $rhs = lc "($port & $pval)";
                } elsif (defined $port) {
                    $rhs = lc $port;
                } else {
                    # may be a variable
                    $rhs = uc $rhs;
                }
            } else {
                $rhs = sprintf "0x%02X", $rhs;
            }
            $condition = "$lhs $op2 $rhs";
        }
        #TODO: handle more complex expressions
        if (defined $msg and ref $msg eq 'HASH') {
            $msg = $msg->{string};
        }
        $msg  = "$condition is false" unless $msg;
        $msg = substr($msg, 1) if $msg =~ /^@/;
        $condition = substr($condition, 1) if $condition =~ /^@/;
        $assert_msg = qq{$condition, \\\"$msg\\\"};
    } else {
        if (defined $msg and ref $msg eq 'HASH') {
            $msg = $msg->{string};
        }
        if (defined $condition and ref $condition eq 'HASH') {
            $condition = $condition->{string};
        }
        if (defined $condition and defined $msg) {
            $msg = substr($msg, 1) if $msg =~ /^@/;
            $condition = substr($condition, 1) if $condition =~ /^@/;
            $assert_msg = qq{$condition, \\\"$msg\\\"};
        } elsif (defined $condition and not defined $msg) {
            $condition = substr($condition, 1) if $condition =~ /^@/;
            $assert_msg = qq{\\\"$condition\\\"};
        } elsif (defined $msg and not defined $condition) {
            $msg = substr($msg, 1) if $msg =~ /^@/;
            $assert_msg = qq{\\\"$msg\\\"};
        } else {
            $assert_msg = qq{\\\"user requested an assert\\\"};
        }
    }

    return << "..."
\t;; break if the condition evaluates to false
\t.assert "$assert_msg"
\tnop ;; needed for the assert
...
}

sub stimulate {
    my $self = shift;
    my $pin = shift;
    my %hh = ();
    foreach my $href (@_) {
        %hh = (%hh, %$href);
    }
    my $period = '';
    $period = $hh{EVERY} if (defined $hh{EVERY} and length $hh{EVERY});
    $period = qq{\t.sim "period $period"} if (defined $period and length $period);
    my $wave = '';
    my $wave_type = 'digital';
    if (exists $hh{WAVE} and ref $hh{WAVE} eq 'ARRAY') {
        my $arr = $hh{WAVE};
        $wave = "\t.sim \"{ " . join(',', @$arr) . " }\"" if scalar @$arr;
        my $ad = 0;
        foreach (@$arr) {
            $ad |= 1 unless /^\d+$/;
        }
        $wave_type = 'analog' if $ad;
    }
    my $start = $hh{START} || 0;
    $start = qq{\t.sim "start_cycle $start"};
    my $init = $hh{INITIAL} || 0;
    $init = qq{\t.sim "initial_state $init"};
    my $num = $self->stimulus_count;
    $self->stimulus_count($num + 1);
    my $node = "stim$num$pin";
    my $simpin = $self->_get_simport($pin);
    return << "..."
\t.sim \"echo creating stimulus number $num\"
\t.sim \"stimulus asynchronous_stimulus\"
$init
$start
\t.sim \"$wave_type\"
$period
$wave
\t.sim \"name stim$num\"
\t.sim \"end\"
\t.sim \"echo done creating stimulus number $num\"
\t.sim \"node $node\"
\t.sim \"attach $node stim$num $simpin\"
...
}

sub get_autorun_code {
    return qq{\t.sim "run"\n};
}

sub autorun {
    my $self = shift;
    $self->should_autorun(1);
    return "\t;;;; will autorun on start\n";
}

sub stopwatch {
    my ($self, $rollover) = @_;
    my $code = qq{\t.sim "stopwatch.enable = true"\n};
    $code .= qq{\t.sim "stopwatch.rollover = $rollover"\n} if defined $rollover;
    $code .= qq{\t.sim "break stopwatch"\n} if defined $rollover;
    return $code;
}

sub attach {
    my $self = shift;
    return unless @_;
    my $pin = shift;
    my $code = '';
    if ($pin =~ /US?ART/) {
        # TX - connect to UART
        # RX - connect to UART but also send it data
        unless ($self->pic->doesrole('USART')) {
            carp "PIC ", $self->pic->type, " does not do USART";
            return;
        }
        my $baudrate = shift if @_;
        my $loopback = shift if @_;
        my $key = ($pin =~ /^UART/) ? 'uart' : 'usart';
        $baudrate = $self->pic->code_config->{$key}->{baud} unless defined
        $baudrate;
        $baudrate = 9600 unless defined $baudrate;
        my $id = $self->node_count;
        $self->node_count($id + 1);
        my $ipin = $self->pic->usart_pins->{async_in};
        my $rxport = $self->_get_simport($ipin);
        my $opin = $self->pic->usart_pins->{async_out};
        my $txport = $self->_get_simport($opin);
        return unless (exists $self->pic->pins->{$ipin} and exists $self->pic->pins->{$opin});
        $code .= qq{\t.sim "module load usart U$id"\n};
        $code .= qq{\t.sim "node TX_U$id"\n};
        $code .= qq{\t.sim "node RX_U$id"\n};
        $code .= qq{\t.sim "attach TX_U$id $txport U$id.RXPIN"\n};
        $code .= qq{\t.sim "attach RX_U$id $rxport U$id.TXPIN"\n};
        $code .= qq{\t.sim "U$id.txbaud = $baudrate"\n};
        $code .= qq{\t.sim "U$id.rxbaud = $baudrate"\n};
        my $x = 500;
        my $y = 50 + 50 * $id;
        $code .= qq{\t.sim "U$id.xpos = $x"\n};
        $code .= qq{\t.sim "U$id.ypos = $y"\n};
        if (defined $loopback) {
            if (ref $loopback eq 'HASH' and $loopback->{string} =~ /loopback/i) {
                $code .= qq{\t.sim "U$id.loop = true"\n};
            }
        }
    }
    return $code;
}

1;

=encoding utf8

=head1 NAME

VIC::Receiver

=head1 SYNOPSIS

The Pegex::Receiver class for handling the grammar.

=head1 DESCRIPTION

INTERNAL CLASS.

=head1 AUTHOR

Vikas N Kumar <vikas@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2014. Vikas N Kumar

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
