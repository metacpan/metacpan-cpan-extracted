use strict;
use Test::More;

use PICA::Path;

my %pathes = (
    '003.$abc' => '003.$abc',
    '003.abc'  => '003.$abc',
    '001B$0'   => '001B$0',    
    '123A[0.]/1-3' => '123A/0.$*/1-3',
    '123+'         => undef,
    '300@'         => undef,
    '003$$'        => undef,
    '123A/-'       => undef,
    # TODO: deprecate occurrence read as position 
    '003X/0'     => '003X',
    '....$*/10-10' => '....$*/10',
    '....$*/1-'    => '....$*/1-',
    '....$*/0-' => '....$*',
    '003X[0-01]' => '003X/0-1',
    '003X[2-02]' => '003X/2',
    '003X[7-13]' => '003X/7-13',
    '003X[13-7]' => undef,
    '003@.0'     => '003@$0',
    '123X'       => '123X',
    '123X$*'     => '123X$*',
    '123X*'      => '123X$*',
    '123X/**'    => '123X/*$*',
    '2...'       => '2...',
    '2.../*'     => '2...',
);

foreach my $path (keys %pathes) {
    my $parsed = eval {PICA::Path->new($path)};
    if ($@ || !$parsed) {
        is $pathes{$path}, undef, "invalid path: $path";
    }
    else {
        is "$parsed", $pathes{$path}, "stringify $path";
    }
}

is "" . PICA::Path->new('123A[00]'), '123A';
is "" . PICA::Path->new('003.abc')->stringify(1), '003.abc', 'stringify(1)';

my $field = ['123A', undef, 0 => 'abcdefghijk'];
my %matches
    = ('123A' => ['abcdefghijk'], '123A$*/1' => ['b'], '123A$*/10-' => ['k']);

while (my ($path, $values) = each %matches) {
    is_deeply [PICA::Path->new($path)->match_subfields($field)], $values;
}

ok(PICA::Path->new('....[0-3]')->match_field(['000X','0']), 'occurrence range');
ok(!PICA::Path->new('....[0-3]')->match_field(['000X','4']), 'occurrence range');
ok(PICA::Path->new('....[7-13]')->match_field(['000X','13']), 'occurrence range');
ok(!PICA::Path->new('....[7-13]')->match_field(['000X','14']), 'occurrence range');
ok(!PICA::Path->new('....[7-13]')->match_field(['000X','6']), 'occurrence range');

my @match = (
    ['123X',0] => { '123X' => 1, '123X[*]' => 1, '123X/1' => 0},
    ['123X',1] => { '123X' => 0, '123X[*]' => 1, '123X/1' => 1}
);

while (my ($field, $test) = splice @match, 0, 2) { 
    while (my ($path, $ok) = each %$test) {
        my $match = PICA::Path->new($path)->match_field($field) ? 1 : 0;
        is($match, $ok, "$path ~ " . join '/', @$field);
    }
}

# Accessors
my $path = PICA::Path->new('123A[0.]/1-3');
is $path->fields,      '123A';
is $path->occurrences, '0.';
is $path->subfields,   '*';
is $path->positions,   '1-3';

$path = PICA::Path->new('00..$0');
is $path->fields,      '00..';
is $path->occurrences, undef;
is $path->subfields,   '0';
is $path->positions,   undef;

done_testing;
