#!/usr/bin/perl -W -T

use strict;
#use Data::Dumper;
use Text::Placeholder::Appliance::Directory_Listing;

my $listing = Text::Placeholder::Appliance::Directory_Listing->new(
	'[=counter=]. [=file_name_full=] [=file_mode_rwx=]');
my $rows = $listing->generate('/');
print join("\n", @$rows), "\n";

exit(0);

__END__
# prints something like this:
1. /. rwxr-xr-x
2. /.. rwxr-xr-x
3. /archive rwxr-xr-x
4. /bin rwxr-xr-x
5. /boot rwxr-xr-x
6. /dev rwxr-xr-x
7. /etc rwxr-xr-x
8. /home rwxr-xr-x
9. /lib rwxr-xr-x
10. /lib64 rwxr-xr-x
11. /lost+found rwx------
12. /media rwxr-xr-x
13. /mnt rwxr-xr-x
14. /opt rwxr-xr-x
15. /proc r-xr-xr-x
16. /root rwx------
17. /sbin rwxr-xr-x
18. /selinux rwxr-xr-x
19. /srv rwxr-xr-x
20. /sys rwxr-xr-x
21. /tmp rwxrwxrws
22. /usr rwxr-xr-x
23. /var rwxr-xr-x
