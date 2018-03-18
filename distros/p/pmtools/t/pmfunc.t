# pmfunc testing

# ------ pragmas
use strict;
use warnings;
use Test::More tests => 3;

# ------ define variable
my $output = undef;	# output from pmfunc

# ------ add pmtools to PATH for testing, so we use the current pmtools
$ENV{"PATH"} = 'blib/script:' . $ENV{"PATH"};

eval {
    $output = `bin/pmfunc Cwd::chdir 2>&1`;
};

isnt($?, 127, "pmfunc runs");

like($output, qr/^sub\schdir\s/msx,     "found 'chdir()'");
like($output, qr/my\s\$newdir\s=\s/msx, "display function body");
