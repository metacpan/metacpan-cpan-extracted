use warnings;
use strict;

use Test::More;
use Word::Rhymes;

BEGIN {
    if (! $ENV{WORD_RHYMES_PRINT} && ! $ENV{RELEASE_TESTING}) {
        plan skip_all => "RELEASE_TESTING or WORD_RHYMES_PRINT env var not set";
    }
}

use Capture::Tiny qw(capture_stdout);

my $mod = 'Word::Rhymes';

{
    my $o = $mod->new(file => 't/data/zoo.data');
    my $stdout = capture_stdout { $o->print('zoo') };

    my $test_data;

    {
        local $/;
        open my $fh, '<', 't/data/print.data' or die $!;
        $test_data = <$fh>;
    }

    is $stdout, $test_data, "print data is accurate ok";

}

{
    my $o = $mod->new(file => 't/data/zoo.data');
    is $o->print('zoo'), 0, "return from print() ok";
}
done_testing

