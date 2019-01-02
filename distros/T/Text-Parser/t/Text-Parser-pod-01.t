use strict;
use warnings;
use Test::More;
use Test::Output;
use Test::Exception;

BEGIN { use_ok 'Text::Parser'; }

my $parser = Text::Parser->new();
(@ARGV) = qw(t/text-simple.txt);
lives_ok {
    $parser->read(shift @ARGV);
    stdout_is {
        print $parser->get_records, "\n";
    }
    "This is a file with one line\n\n", 'Prints the output to screen correctly';
}
'No errors in reading this file';

done_testing();
