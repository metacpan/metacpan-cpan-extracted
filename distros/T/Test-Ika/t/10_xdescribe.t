use strict;
use warnings;
use utf8;
use Test::More;
use Test::Ika;
use Test::Ika::Reporter::Test;

my $reporter = Test::Ika::Reporter::Test->new();
local $Test::Ika::REPORTER = $reporter;
my @RESULT;
{
    package sandbox;
    use Test::Ika;
    use Test::More;

    xdescribe 'foo' => sub {
        before_all {
            push @RESULT, 'BEFORE ALL foo';
        };
        after_all {
            push @RESULT, 'AFTER ALL foo';
        };
        before_each {
            push @RESULT, 'BEFORE EACH foo';
        };
        after_each {
            push @RESULT, 'AFTER EACH foo';
        };

        it 'bar' => sub {
            push @RESULT, 'test bar';
        };

        it 'baz';

        xit 'quux' => sub {
            push @RESULT, 'test quux';
        };
    };

    runtests;
}

is(join("\n", @RESULT), '');

is scalar @{$reporter->report} => 3;
like $reporter->report->[0]->[1] => qr/DISABLED/; # normal case is disabled
like $reporter->report->[1]->[1] => qr/NOT IMPLEMENTED/;
like $reporter->report->[2]->[1] => qr/DISABLED/;

done_testing;

