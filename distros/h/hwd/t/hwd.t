#!perl

use Test::More tests => 15;

my $cmd = "$^X -Mblib bin/hwd";
my $hwd = 't/simple.hwd';

NEXTID_OPTION: {
    my $run = "$cmd --nextid $hwd";
    # diag "Running: $run";
    my $output = `$run`;
    chomp $output;
    is($output, "Next task ID: 108", "--nextid option");
}

TASKS_OPTION: {
    my $run = "$cmd --tasks $hwd";
    # diag "Running: $run";
    my @output = `$run`;
    chomp @output;
    like(shift @output, qr(^Ape), "Ape's tasks");
    like(shift @output, qr(104));
    like(shift @output, qr(105));
    shift @output;

    like(shift @output, qr(^Chimp), "Chimp's tasks");
    like(shift @output, qr(103));
    like(shift @output, qr(106));
    like(shift @output, qr(107));
    shift @output;

    like(shift @output, qr(^Monkey), "Monkey's tasks");
    like(shift @output, qr(102));
    like(shift @output, qr(101));
}

USER_TASKS_OPTION: {
    my $run = "$cmd --tasks Chimp $hwd";
    # diag "Running: $run";
    my @output = `$run`;
    chomp @output;
    like(shift @output, qr(^Chimp), "Chimp's tasks");
    like(shift @output, qr(103));
    like(shift @output, qr(106));
    like(shift @output, qr(107));
}
