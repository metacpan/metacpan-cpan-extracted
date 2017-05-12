use Test::More;
use_ok('VIC::PIC::Any');

can_ok( 'VIC::PIC::Any', 'supported_chips' );
can_ok( 'VIC::PIC::Any', 'new' );
can_ok( 'VIC::PIC::Any', 'new_simulator' );
can_ok( 'VIC::PIC::Any', 'supported_simulators' );
can_ok( 'VIC::PIC::Any', 'is_chip_supported' );
can_ok( 'VIC::PIC::Any', 'is_simulator_supported' );
can_ok( 'VIC::PIC::Any', 'list_chip_features' );
can_ok( 'VIC::PIC::Any', 'print_pinout' );
my $chips = VIC::PIC::Any::supported_chips();
isa_ok( $chips, ref [] );
ok( scalar(@$chips) > 0 );

foreach my $chip (@$chips) {
    subtest $chip => sub {
        my $self = VIC::PIC::Any->new($chip);
        isnt( $self, undef );
        isa_ok( $self, 'VIC::PIC::' . uc($chip) );
        can_ok($self, qw/list_roles chip_config print_pinout doesrole doesroles/);
        my $roles = $self->list_roles;
        isa_ok($roles, ref []);
        isa_ok($self->chip_config, ref {});
        isa_ok($self->memory, ref {});
        isa_ok($self->address, ref {});
        isa_ok($self->pin_counts, ref {});
        isa_ok($self->banks, ref {});
        isa_ok($self->registers, ref {});
        isa_ok($self->pins, ref {});
        isa_ok($self->clock_pins, ref {});
        isa_ok($self->oscillator_pins, ref {});
        isa_ok($self->program_pins, ref {});
        isnt($self->program_pins->{clock}, undef);
        isnt($self->program_pins->{data}, undef);
        if ($self->doesrole('Timer')) {
            my $tp = $self->timer_pins;
            isnt($tp, undef);
            isa_ok($tp, ref {});
            my @ep = sort qw(reg flag enable freg ereg);
            foreach (keys %$tp) {
                if (/^TMR\d+/) {
                    my $p = $tp->{$_};
                    isnt($p, undef);
                    isa_ok($p, ref {});
                    my @kp = sort (keys %$p);
                    is_deeply(\@kp, \@ep);
                }
            }
        }
        if ($self->doesrole('GPIO')) {
            my $ioc = $self->ioc_ports;
            isnt($ioc, undef);
            isa_ok($ioc, ref {});
            isnt($ioc->{FLAG}, undef);
            isnt($ioc->{ENABLE}, undef);
        }
        if ($self->doesrole('USART')) {
            my $usart = $self->usart_pins;
            isnt($usart, undef);
            isa_ok($usart, ref {});
            my @ep = sort qw(async_in async_out sync_clock sync_data rx_int tx_int UART USART);
            my @kp = sort (keys %$usart);
            is_deeply(\@kp, \@ep);
        }
        if ($self->doesroles('SPI')) {
            my $ss = $self->selector_pins;
            isnt($ss, undef);
            isa_ok($ss, ref {});
            isnt($ss->{spi_or_i2c}, undef);
            my $spi = $self->spi_pins;
            isnt($spi, undef);
            isa_ok($spi, ref {});
            my @ep = sort qw(data_in data_out clock);
            my @kp = sort (keys %$spi);
            is_deeply(\@kp, \@ep);
        }
        if ($self->doesroles('I2C')) {
            my $ss = $self->selector_pins;
            isnt($ss, undef);
            isa_ok($ss, ref {});
            isnt($ss->{spi_or_i2c}, undef);
            my $i2c = $self->i2c_pins;
            isnt($i2c, undef);
            isa_ok($i2c, ref {});
            my @ep = sort qw(data clock);
            my @kp = sort (keys %$i2c);
            is_deeply(\@kp, \@ep);
        }
        done_testing();
    };
}
my $sims = VIC::PIC::Any::supported_simulators();
isa_ok( $sims, ref [] );
ok( scalar(@$sims) > 0 );
foreach my $sim (@$sims) {
    subtest $sim => sub {
        my $self = VIC::PIC::Any->new_simulator( type => $sim );
        isnt( $self, undef );
        isa_ok( $self, 'VIC::PIC::' . ucfirst($sim) );
        can_ok($self, qw/type include pic supports_modifier init_code attach_led
            attach_led7seg stop_after logfile log scope sim_assert stimulate
            attach autorun stopwatch get_autorun_code disable/);
        done_testing();
    };
}

done_testing();

