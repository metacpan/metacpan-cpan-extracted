use strict;
use Win32::MMF::Shareable;

my $glue = 'data';
my %options = (
    create    => 'yes',
    exclusive => 0,
    mode      => 0644,
    destroy   => 'yes',
);
my %colours;
tie %colours, 'Win32::MMF::Shareable', $glue, { %options } or
    die "server: tie failed\n";
%colours = (
    red => [
        'fire truck',
        'leaves in the fall',
    ],
    blue => [
        'sky',
        'police cars',
    ],
);
((print "server: there are 2 colours\n"), sleep 1)
    while scalar keys %colours == 2;
print "server: here are all my colours:\n";
foreach my $c (keys %colours) {
    print "server: these are $c: ",
        join(', ', @{$colours{$c}}), "\n";
}
exit;

