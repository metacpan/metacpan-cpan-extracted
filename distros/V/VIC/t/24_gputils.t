use Test::Lib;
use Test::VIC;

unless ($ENV{TEST_GPUTILS}) {
    Test::VIC::plan skip_all => "Skipping unless ENV{TEST_GPUTILS} is defined";
} else {
my $input = <<'...';
PIC PIC16F690;

# A Comment

Main { # set the Main function
     digital_output RC0; # mark pin RC0 as output
     write RC0, 1; # write the value 1 to RC0
} # end the Main function
...

my $chips = VIC::supported_chips();
foreach (sort @$chips) {
    my $code = $input;
    if (/12f683/i) {
        $code =~ s/RC0/GP0/gs;
    } elsif (/16f6[24]\w+/i) {
        $code =~ s/RC0/RA0/gs;
    }
    my $chip = $_;
    Test::VIC::subtest "gputils check for $_" => sub { assembles_ok($code, $chip) };
}

Test::VIC::done_testing();
}
