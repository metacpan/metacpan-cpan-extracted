#!/usr/local/bin/perl -w

use strict;
use Getopt::Long;
use Carp;
use GO::AppHandle;

# Get args

my $apph = GO::AppHandle->connect(\@ARGV);
my $opt = {};
GetOptions($opt,
	   "help|h",
           "id=s@",
           "names",
	  );

if ($opt->{help}) {
    system("perldoc $0");
    exit;
}

my @accs = (@ARGV, @{$opt->{id} || []});
while (my $acc = shift @accs) {
    print "ACC:$acc\n";
    my $path_l = 
      $apph->get_paths_to_top({acc=>$acc});
    foreach my $path (@$path_l) {
        printf "  PATH: %s\n",
          $path->to_text($opt->{names} ? () : ('acc'));
    }
}
$apph->disconnect;
