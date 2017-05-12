#!perl -w

use strict;
use Test::More;

use Text::Clevery;
use Text::Clevery::Parser;

my $tc = Text::Clevery->new(verbose => 2);

my @set = (
    [<<'T', {types => [qw(int str object)]}, <<'X'],
{foreach from=$types item=foo name=bar -}
    {$smarty.foreach.bar.index} {$foo}
{/foreach -}
T
    0 int
    1 str
    2 object
X

    [<<'T', {types => [qw(int str object)]}, <<'X'],
{foreach from=$types item=foo name=bar -}
    {$smarty.foreach.bar.iteration} {$foo}
{/foreach -}
T
    1 int
    2 str
    3 object
X

    [<<'T', {types => [qw(int str object)]}, <<'X'],
{foreach from=$types item=foo name=bar -}
    {$smarty.foreach.bar.iteration} {$foo}
{/foreach -}
({$smarty.foreach.bar.total})
T
    1 int
    2 str
    3 object
(3)
X

    [<<'T', {types => [qw(int str object)]}, <<'X'],
{foreach from=$types item=foo name=bar -}
{if $smarty.foreach.bar.first -}
    --------
{/if -}
    {$smarty.foreach.bar.iteration} {$foo}
{if $smarty.foreach.bar.last -}
    --------
{/if -}
{/foreach -}
T
    --------
    1 int
    2 str
    3 object
    --------
X

    [<<'T', {types => [qw(int str object)]}, <<'X'],
{foreach from=$types item=i0 name=i0 -}
{foreach from=$types item=i1 name=i1 -}
    {$smarty.foreach.i0.index}:{$i0} {$smarty.foreach.i1.index}:{$i1}
{/foreach -}
{/foreach -}
T
    0:int 0:int
    0:int 1:str
    0:int 2:object
    1:str 0:int
    1:str 1:str
    1:str 2:object
    2:object 0:int
    2:object 1:str
    2:object 2:object
X

    [<<'T', {types => [qw(int str object)]}, <<'X'],
{foreach from=$types item=foo name=bar -}
    {$smarty.foreach.bar.index} {$foo}
{foreachelse -}
    unlikely
{/foreach -}
T
    0 int
    1 str
    2 object
X

    [<<'T', {types => []}, <<'X'],
{foreach from=$types item=foo name=bar -}
    unlikely
{foreachelse -}
    the array is empty
{/foreach -}
T
    the array is empty
X
    [<<'T', {types => undef}, <<'X'],
{foreach from=$types item=foo name=bar-}
    unlikely
{foreachelse -}
    the array is empty
{/foreach -}
T
    the array is empty
X
);

for my $d(@set) {
    my($source, $vars, $expected, $msg) = @{$d};
    is eval { $tc->render_string($source, $vars) }, $expected, $msg
        or do { ($@ && diag $@); diag $source };
}

done_testing;
