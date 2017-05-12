use strict;
use warnings;
use Test::More tests => 13;
use Tie::Handle::TtyRec;
use Term::TtyRec::Plus;

$\ = "\n";

{
    no warnings 'redefine';
    my $i = 0;
    *Tie::Handle::TtyRec::gettimeofday = sub () {
        ++$i;
        return ($i * 1000, $i * 2000);
    };
}

my @data1 = qw(foo bar baz);
my @data2 = qw(quux quuux quuuux);
my @data = (@data1, @data2);

my $ttyrec = Tie::Handle::TtyRec->new("t/001.ttyrec");
for (@data1) {
    print $ttyrec $_;
}
close $ttyrec;
$ttyrec = Tie::Handle::TtyRec->new("t/001.ttyrec", append => 1);
print $ttyrec @data2;
close $ttyrec;

my $ttp = Term::TtyRec::Plus->new(infile => "t/001.ttyrec");
my @frames;
while (my $frame = $ttp->next_frame) {
    push @frames, $frame;
}

unlink "t/001.ttyrec";

is(@frames, 6);

for (0 .. $#data) {
    is($frames[$_]{data}, $data[$_], "frame $_ had the right data");
    is($frames[$_]->{orig_header}, header($_), "frame $_ had the right header");
}

sub header {
    my $idx = shift;
    my $n = 1_000 * ($idx + 1);
    return pack('VVV', $n, $n * 2, length $data[$idx]);
}

