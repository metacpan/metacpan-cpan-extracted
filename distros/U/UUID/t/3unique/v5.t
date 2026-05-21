#
# v5 should be all dupes.
#
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
        UUID::generate_v5($bin, dns => 'www.example.com');
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
    is $got,   1,         'unique ok';
}

done_testing;
