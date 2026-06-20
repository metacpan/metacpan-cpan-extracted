use strict;
use warnings;

use pEFL::Ecore;
use File::HomeDir;

pEFL::Ecore::File::init();

my $dir = File::HomeDir->my_home;

print "Monitor directory: $dir\n";

my $monitor = pEFL::Ecore::FileMonitor->add(
    $dir,
    \&mein_verzeichnis_callback,
    "test_data"
);

pEFL::Ecore::Mainloop::begin();

pEFL::Ecore::File::shutdown();

sub mein_verzeichnis_callback {
    my ($data, $monitor_obj, $event, $path) = @_;

    print "Get user data: $data\n" if $data;

    if ($event == ECORE_FILE_EVENT_CREATED_FILE) {
        print "New file created: $path\n";
    }
    elsif ($event ==  ECORE_FILE_EVENT_CREATED_DIRECTORY) {
    	print "New Directory created: $path\n";
    }
    elsif ($event ==  ECORE_FILE_EVENT_DELETED_FILE) {
    	print "The following file was deleted: $path\n";
    }
    elsif ($event ==  ECORE_FILE_EVENT_DELETED_DIRECTORY) {
    	print "The following directory was deleted: $path\n";
    }
    elsif ($event ==  ECORE_FILE_EVENT_MODIFIED) {
    	print "The following path was modified: $path\n";
    }    
}
