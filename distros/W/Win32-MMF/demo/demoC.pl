use strict;
use warnings;
use Win32::MMF::Shareable;
use Data::Dumper;

tie my $ref, "Win32::MMF::Shareable", "var_1";
tie my $r2, "Win32::MMF::Shareable", "var_1";
$ref = [ 'A', 'B', 'C' ];

print Dumper($r2);

push @$r2, 'D';         # this does not work

print Dumper($r2);

my @list = @$r2;
push @list, 'D';
$r2 = [ @list ];        # this works

print Dumper($ref);

