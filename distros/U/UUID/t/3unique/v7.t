use strict;
use warnings;
use MyTest;
use MyTmpTimer;
use UUID;

my $N = 4_000;
my %seen = ();
my $count = 0;

my $fh = tmptimer( $N, sub {
    my ($N, $fh) = @_;
    my ($bin, $str);
    for (1 .. $N) {
        UUID::generate_v7($bin);
        UUID::unparse($bin, $str);
        print $fh $str. "\n";
    }
});

while (my $str = <$fh>) {
    chomp $str;
    note $str if $count++ < 3;
    ++$seen{$str};
}

# avoid cleanup race
$fh->close;

{
    my $expected = $N;
    my $got = scalar keys %seen;
    is $count, $expected, 'count ok';
    is $got,   $expected, 'unique ok';

    # show the repeats, if any
    my $reps = scalar grep { $seen{$_} > 1 } keys %seen;
    next unless $reps;
    diag q(     repeats: '). $reps. q(');
}

done_testing;
