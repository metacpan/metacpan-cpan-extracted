use strict;
use warnings;
use Win32::FileSystem::Watcher::Synchronous;
my $watcher = Win32::FileSystem::Watcher::Synchronous->new(
    "c:\\",
    notify_filter  => FILE_NOTIFY_ALL,
    watch_sub_tree => 1,
);

warn "Monitoring started.";

while (1) {
    my @entries = $watcher->get_results();

    foreach my $entry (@entries) {
        print $entry->action_name . " " . $entry->file_name . "\n";
    }
}
