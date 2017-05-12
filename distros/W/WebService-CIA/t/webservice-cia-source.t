use strict;
use Test::More tests => 7;

#1
BEGIN { use_ok('WebService::CIA::Source'); }

my $source = WebService::CIA::Source->new;

#2
ok ( defined $source, 'new() - returns something' );

#3
ok ( $source->isa('WebService::CIA::Source'), 'new() - returns a WebService::CIA::Source object' );

#4
ok( ! defined $source->value('zz', 'Test'), 'value() - invalid args - returns undef' );

#5
ok( $source->value('testcountry', 'Test') eq 'Wombat', 'value() - valid args - returns test string' );

#6
ok( scalar keys %{$source->all('zz')} == 0, 'all() - invalid args - returns empty hashref' );

#7
ok( scalar keys %{$source->all('testcountry')} == 1 &&
    exists $source->all('testcountry')->{'Test'} &&
    $source->all('testcountry')->{'Test'} eq 'Wombat', 'all() - valid args - returns hashref with test value');
