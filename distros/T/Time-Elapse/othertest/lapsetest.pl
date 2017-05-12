    #!/usr/bin/perl
	use Time::Elapse;
    Time::Elapse->lapse(my $now = "testing 0");
    for (1 .. 5)
    {
        print "$now\n";
        $now = "testing $_";
    }
    print "$now\n";
