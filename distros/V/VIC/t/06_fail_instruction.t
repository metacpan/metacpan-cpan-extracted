use t::TestVIC tests => 1, debug => 0;

my $input = <<'...';
PIC P16F690;

# A Comment

Main { # set the Main function
     digital_output RC0; # mark pin RC0 as output
     write RC0, 1; # write the value 1 to RC0
     bad_instruction PORTA;
} # end the Main function
...

compile_fails_ok($input);
