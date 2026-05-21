use warnings;
use strict;

use Test::More;
use Test::MockModule;

package Tgt::OriginalFor; ## no critic (Modules::RequireFilenameMatchesPackage)
our $VERSION = 1;
sub greet { 'hello' }
sub other { 'other' }
package main; ## no critic (Modules::RequireFilenameMatchesPackage)

# 1. Returns the actual sub when not mocked
{
    my $code = Test::MockModule->original_for('Tgt::OriginalFor', 'greet');
    is(ref($code), 'CODE', 'returns a coderef when sub is not mocked');
    is($code->(), 'hello', '... that calls the real implementation');
}

# 2. Returns the truly-original (not the active mock) when mocked
{
    my $mock = Test::MockModule->new('Tgt::OriginalFor');
    $mock->mock('greet', sub { 'mocked' });

    is(Tgt::OriginalFor::greet(), 'mocked', 'symbol table now holds the mock');

    my $orig = Test::MockModule->original_for('Tgt::OriginalFor', 'greet');
    is($orig->(), 'hello',
        'original_for returns the pre-mock implementation, not the mock');

    $mock->unmock_all;
}

# 3. Recommended GH #83-safe pattern: closure captures strings, not $mock.
#    Works under distinct => 1 mode because there is no $mock capture.
{
    my @results;
    my $run = sub {
        my ($label) = @_;
        my $mock = Test::MockModule->new(
            'Tgt::OriginalFor', no_auto => 1, distinct => 1
        );
        $mock->mock('greet', sub {
            return Test::MockModule
                ->original_for('Tgt::OriginalFor', 'greet')->() . "_$label";
        });
        push @results, Tgt::OriginalFor::greet();
    };
    $run->('first');
    $run->('second');
    is_deeply \@results, ['hello_first', 'hello_second'],
        'original_for pattern works under distinct => 1 (no leak)';
}

# 4. Stacked mocks: original_for still returns the truly-original
{
    my $m1 = Test::MockModule->new('Tgt::OriginalFor', distinct => 1);
    $m1->mock('other', sub { 'L1' });
    {
        my $m2 = Test::MockModule->new('Tgt::OriginalFor', distinct => 1);
        $m2->mock('other', sub { 'L2' });
        is(Tgt::OriginalFor::other(), 'L2', 'top mock wins');
        my $orig = Test::MockModule->original_for('Tgt::OriginalFor', 'other');
        is($orig->(), 'other',
            'original_for returns pre-any-mock impl, not the layer below');
    }
    $m1->unmock_all;
}

# 5. Invalid args croak
{
    eval { Test::MockModule->original_for('', 'foo') };
    like($@, qr/Invalid package name/, 'empty package croaks');

    eval { Test::MockModule->original_for('Tgt::OriginalFor', '') };
    like($@, qr/valid function name/i, 'empty sub name croaks');
}

# 6. Looking up a sub that doesn't exist returns undef without crashing
{
    my $code = Test::MockModule->original_for('Tgt::OriginalFor', 'nonexistent');
    is($code, undef, 'returns undef for nonexistent sub');
}

done_testing;
