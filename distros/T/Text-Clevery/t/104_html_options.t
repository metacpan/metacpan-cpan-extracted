#!perl -w

use strict;
use Test::More;

use Text::Clevery;
use Text::Clevery::Parser;

my $tc = Text::Clevery->new(verbose => 2);

my @set = (
    [<<'T', { opts => [ [1800, 'Joe'], [9904, 'Jack'] ], sel => 9904  }, <<'X'],
{html_options name=foo options=$opts selected=$sel}
T
<select name="foo">
<option value="1800">Joe</option>
<option value="9904" selected="selected">Jack</option>
</select>
X

    [<<'T', { ids => [100, 101], names => ['Joe', 'Jack'], sel => 101  }, <<'X'],
{html_options name=foo values=$ids output=$names selected=$sel}
T
<select name="foo">
<option value="100">Joe</option>
<option value="101" selected="selected">Jack</option>
</select>
X

    [<<'T', { ids => [100, 101], names => ['Joe', 'Jack'], sel => 101  }, <<'X'],
<select name="foo">
{html_options values=$ids output=$names selected=$sel}
</select>
T
<select name="foo">
<option value="100">Joe</option>
<option value="101" selected="selected">Jack</option>
</select>
X

    [<<'T', { grp => { sport => { 1 => 'golf', 2 => 'swim' }, rest => { 3 => 'sauna', 4 => 'massage' } }, , sel => 2  }, <<'X'],
{html_options name=foo options=$grp selected=$sel}
T
<select name="foo">
<optgroup label="rest">
<option value="3">sauna</option>
<option value="4">massage</option>
</optgroup>
<optgroup label="sport">
<option value="1">golf</option>
<option value="2" selected="selected">swim</option>
</optgroup>
</select>
X

    [<<'T', { ids => [qw(<100> <101>)], names => [qw(<Joe> <Jack>)], sel => '<101>'  }, <<'X', 'escape html'],
{html_options name="foo" values=$ids output=$names selected=$sel}
T
<select name="foo">
<option value="&lt;100&gt;">&lt;Joe&gt;</option>
<option value="&lt;101&gt;" selected="selected">&lt;Jack&gt;</option>
</select>
X

);

for my $d(@set) {
    my($source, $vars, $expected, $msg) = @{$d};
    is eval { $tc->render_string($source, $vars) }, $expected, $msg
        or do { ($@ && diag $@); diag $source };
}

done_testing;
