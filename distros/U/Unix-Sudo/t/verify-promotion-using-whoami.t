use strict;
use warnings;
use Test::More;

use Capture::Tiny qw(capture);

use Unix::Sudo qw(sudo);

use lib 't/lib';
use sudosanity;

sudosanity::checks && do {
    my($stdout, $stderr, $rv) = capture {
        sudo {
            eval "no tainting;";
            print `whoami`;
        }
    };
    chomp($stdout);
    is($stdout, 'root', "ran 'whoami' as root");
};

END { done_testing }
