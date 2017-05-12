use strict;
use Win32::MMF::Shareable;

my $glue = 'data';
my %options = (
    create    => 0,
    exclusive => 0,
    mode      => 0644,
    destroy   => 0,
    );
my %colours;
tie %colours, 'Win32::MMF::Shareable', $glue, { %options } or
    die "client: tie failed\n";
foreach my $c (keys %colours) {
    print "client: these are $c: ",
        join(', ', @{$colours{$c}}), "\n";
}
delete $colours{'red'};
exit;
