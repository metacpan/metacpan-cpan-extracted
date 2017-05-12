use strict;
use warnings;
use Data::Dumper;
use Win32::MMF::Shareable;

# Tie variables to shared namespace
my $ns = tie my $shared, "Win32::MMF::Shareable", '$shared';
tie my @shared, "Win32::MMF::Shareable", '@shared';
tie my %shared, "Win32::MMF::Shareable", '%shared';

tie my $sh2, "Win32::MMF::Shareable", '$shared';
tie my @sh2, "Win32::MMF::Shareable", '@shared';
tie my %sh2, "Win32::MMF::Shareable", '%shared';

# as scalar
$shared = "Hello world";

# as list
@shared = ();
for (0..3) {
    $shared[$_] = "$_" x ($_ + 1);
}

# as hash
%shared = @shared;

$ns->debug();

print Dumper(\@sh2), "\n";
print Dumper(\%sh2), "\n";
print Dumper(\$sh2), "\n";

# iteration test
foreach (sort keys %sh2) {
    print "$_ => $sh2{$_}\n";
}

foreach (sort values %sh2) {
    print "$_\n";
}

# hash slice test
my @keys = keys %sh2;
my @values = (0 .. $#keys);
@sh2{@keys} = @values;

print Dumper(\%sh2);

