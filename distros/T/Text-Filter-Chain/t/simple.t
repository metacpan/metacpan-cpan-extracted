#!perl -w
use strict;
use Test;
use Text::Filter;
BEGIN {
    plan(tests => 9);
}

### a lower case converter
package LowerCaser;
use base qw(Text::Filter);
sub run {
    my $this = shift;
    while(defined(my $line = $this->readline)) {
	$this->writeline(lc $line);
    }
}

### a filter which skips every 2nd line
package LineSkipper;
use base qw(Text::Filter);
sub run {
    my $this = shift;
    while(defined (my $line = $this->readline)) {
	$this->writeline($line);
	$this->readline; # skips a line
    }
}

### switch back to package main
package main;

# load the package
eval "use Text::Filter::Chain";
ok(length($@) == 0) or die $@; # 1

# run two filters in series
my @hoedje_van_papier = ( # a children's song in dutch
    'Een, Twee, Drie, Vier', 
    'Hoedje Van, Hoedje Van', 
    'Een, Twee, Drie, Vier', 
    'Hoedje Van Papier',
);
my $input1 = [@hoedje_van_papier];
my $chain1 = new Text::Filter::Chain;
$chain1->add_filter(new LowerCaser(input => $input1));
$chain1->add_filter(new LineSkipper());
my $output1 = [];
$chain1->set_output($output1);
$chain1->run();
ok(scalar @$output1 == 2); # 2
ok($output1->[0],'een, twee, drie, vier'); # 3
ok($output1->[1],'een, twee, drie, vier'); # 4

# the same, but now with magical output buffer
my $chain2 = new Text::Filter::Chain(filters => [
    new LowerCaser(),
    new LineSkipper(),
]);
$chain2->set_input([@hoedje_van_papier]);
$chain2->run();
my $output2 = $chain2->{output}->[0];
ok(defined $output2); # 5
ok(defined(ref $output2)); # 6
ok(scalar @$output2 == 2); # 7
ok($output2->[0],'een, twee, drie, vier'); # 8
ok($output2->[1],'een, twee, drie, vier'); # 9

__END__
