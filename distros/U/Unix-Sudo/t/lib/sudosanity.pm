package #
  sudosanity;

use strict;
use warnings;
use Test::More;

sub checks {
    SKIP: {
        skip "You must not be running as root", 1
            if($> == 0);
    
        my $sudo_works = !system(
            "sudo", "-p",
            "\nThe tests for Unix::Sudo need your password. They'll run 'whoami',\n".
            "  'true', and some perl code as root: ",
            "true"
        );
        skip "Your sudo doesn't work", 1
            unless($sudo_works);

        return 1;
    }
    return 0;
}

1;
