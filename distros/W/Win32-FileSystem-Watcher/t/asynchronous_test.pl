use Win32::FileSystem::Watcher;
use strict;
use warnings;

#my $watcher = Win32::FileSystem::Watcher->new( "c:\\" );

my $watcher = Win32::FileSystem::Watcher->new(
    "c:\\",
    notify_filter  => FILE_NOTIFY_ALL,
    watch_sub_tree => 1,
);

$watcher->start();
print "Monitoring started.";

sleep(5);

my @entries = $watcher->get_results();

$watcher->stop(); # or undef $watcher

foreach my $entry (@entries) {
    print $entry->action_name . " " . $entry->file_name . "\n";
}



# $watcher->start();
# ...
#$watcher->stop();
