use strict;
no warnings;

use Config;
use IPC::Run3;
use Test::More tests => 1;

my $script = 'script/umlclass.pl';
my @cmd = ($^X, '-Ilib', $script);

my ($stdout, $stderr);

{
    my $outfile = 'exclude01.png';
    run3( [@cmd, '--dot', '/some/invalid/path/32fdsf232xcc/dot',
            '-o', $outfile, '-E', $Config{archlibexp}],
              \undef, \$stdout, \$stderr ),
        "umlclass -o $outfile -E $Config{archlibexp}";
    is $stderr, "ERROR: The dot program (/some/invalid/path/32fdsf232xcc/dot) cannot be found or be run.\n";
}

