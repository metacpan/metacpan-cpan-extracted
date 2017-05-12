use t::TestVIC tests => 1, debug => 0;

my $input = <<'...';
PIC p16f690;

Main {
     digital_output RC0;
     write RC0, 1;
     write RC0, PORTB;
}
...

compile_fails_ok($input);
