#!perl
use strict;
use warnings;
use Test::More tests => 61;
use Test::NoWarnings;

BEGIN { use_ok('Text::FixedLengthMultiline'); }

my $fmt;
my %data;

# Build a new format
# 2 tests
sub new_fmt()
{
    # Set the global variables
    undef $fmt;
    undef %data;
    $fmt = Text::FixedLengthMultiline->new(@_);
    isa_ok($fmt, 'Text::FixedLengthMultiline', 'Line '.(caller)[2]);
    return $fmt;
}

# Parse a line and test the result
# 2 tests
sub test_parse()
{
    my ($line, $expected_data, $expected_result) = @_;
    my $test_name = 'Line ' . ((caller)[2]) . ' parsing result for: '.(defined $line ? "<$line>" : 'undef');
    is($fmt->parse_line($line, \%data), $expected_result, $test_name);
    is_deeply(\%data, $expected_data, $test_name);
}

&new_fmt(format => [ 'col1' => 6 ]);
&test_parse(undef, { }, 0);
&test_parse('', { }, 0);
&test_parse('     ', { }, 0);
&test_parse('abc   ', { col1 => 'abc' }, 0);
&test_parse('def', { col1 => 'abc' }, -1);
undef %data;
&test_parse('def', { col1 => 'def' }, 0);
undef %data;
&test_parse('  abc     ', { col1 => '  abc' }, 0);
undef %data;
&test_parse('abc   z', { col1 => 'abc' }, -7);

&new_fmt(format => [ 'col1' => -6 ]);
&test_parse(undef, { }, 0);
&test_parse('', { }, 0);
&test_parse('     ', { }, 0);
&test_parse('abc ', { col1 => 'abc   ' }, 0);
&test_parse('def', { col1 => 'abc   ' }, -1);
undef %data;
&test_parse('def', { col1 => 'def   ' }, 0);
undef %data;
&test_parse('  abc     ', { col1 => 'abc ' }, 0);
undef %data;
&test_parse('   abcz', { col1 => 'abc' }, -7);

&new_fmt(format => [ 2, '!col1' => 6 ]);
&test_parse(undef, { }, -1);
&test_parse('', { }, -1);
&test_parse('     ', { }, 3);
&test_parse('a', { }, -1);
&test_parse('a     ', { }, -1);
&test_parse(' a', { }, -2);
&test_parse(' a     ', { }, -2);
undef %data;
&test_parse('  abc   ', { col1 => 'abc' }, 0);
&test_parse('  def', { col1 => 'abc' }, -3);
undef %data;
&test_parse('  def', { col1 => 'def' }, 0);
undef %data;
&test_parse('    abc     ', { col1 => '  abc' }, 0);
undef %data;
&test_parse('  abc   z', { col1 => 'abc' }, -9);

# TODO More tests
