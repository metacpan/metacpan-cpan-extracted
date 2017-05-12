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

    describe 'foo' => sub {
        xcontext 'xcontext' => sub {
            before_all {
                push @RESULT, 'BEFORE ALL foo xcontext';
            };
            after_all {
                push @RESULT, 'AFTER ALL foo xcontext';
            };
            before_each {
                push @RESULT, 'BEFORE EACH foo xcontext';
            };
            after_each {
                push @RESULT, 'AFTER EACH foo xcontext';
            };

            it 'bar' => sub {
                push @RESULT, 'foo xcontext bar';
            };

            it 'baz';

            xit 'quux' => sub {
                push @RESULT, 'foo xcontext quux';
            };
        };

        context 'normal' => sub {
            before_all {
                push @RESULT, 'BEFORE ALL foo normal';
            };
            after_all {
                push @RESULT, 'AFTER ALL foo normal';
            };
            before_each {
                push @RESULT, 'BEFORE EACH foo normal';
            };
            after_each {
                push @RESULT, 'AFTER EACH foo normal';
            };

            it 'bar' => sub {
                push @RESULT, 'foo normal bar';
            };

            it 'baz';

            xit 'quux' => sub {
                push @RESULT, 'foo normal quux';
            };
        };
    };

    runtests;
}

is(join("\n", @RESULT), join("\n", (
    'BEFORE ALL foo normal',
        'BEFORE EACH foo normal',
            'foo normal bar',
        'AFTER EACH foo normal',
        'BEFORE EACH foo normal',
            # spec 'baz' only
        'AFTER EACH foo normal',
        'BEFORE EACH foo normal',
            # skip xit spec 'quux'
        'AFTER EACH foo normal',
    'AFTER ALL foo normal',
)));

is scalar @{$reporter->report} => 6;
like $reporter->report->[0]->[1] => qr/DISABLED/; # normal case is disabled
like $reporter->report->[1]->[1] => qr/NOT IMPLEMENTED/;
like $reporter->report->[2]->[1] => qr/DISABLED/;
unlike $reporter->report->[3]->[1] => qr/DISABLED/; # it is under context
like $reporter->report->[4]->[1] => qr/NOT IMPLEMENTED/;
like $reporter->report->[5]->[1] => qr/DISABLED/;

done_testing;

