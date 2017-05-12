use strict;
use warnings;

use Test::More tests => 4;

# Load the module.
use_ok 'Test::Fixme';

{    # Test loading of simple file.
    my $content  = Test::Fixme::load_file('t/dirs/normal/one.txt');
    my $expected = "abcdef\nghijkl\nmnopqr\nstuvwx\n\n12345\n67890\n";
    is $content, $expected, "check simple file";
}

{    # Test loading of non-existent file.
    ok !defined Test::Fixme::load_file('t/i/do/not/exist'),
      "load non-existent file";
}

{    # Test loading of a zero length file
    is Test::Fixme::load_file('t/dirs/normal/four.pod'), '',
      "load zero length file";
}
