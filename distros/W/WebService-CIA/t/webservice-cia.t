use strict;
use Test::More tests => 11;

#1
BEGIN {	use_ok('WebService::CIA'); }

#2
ok( !eval {WebService::CIA->new()}, "new() - no source - dies" );

use WebService::CIA::Source;
my $source = WebService::CIA::Source->new;
my $cia = WebService::CIA->new({'Source' => $source});

#3
ok( defined $cia, 'new() returns something' );

#4
ok( $cia->isa('WebService::CIA'), 'new() returns a WebService::CIA object' );

#5
ok( ref $cia->source eq 'WebService::CIA::Source', 'source() - returns source object' );

#6 
ok( $cia->get('testcountry', 'Test') eq 'Wombat', 'get() - valid args - returns test string' );

#7
ok( ! defined $cia->get('zz', 'Test'), 'get() - invalid args - returns undef' );

#8
ok( exists $cia->get_all_hashref(['testcountry'])->{'testcountry'}->{'Test'} &&
    $cia->get_all_hashref(['testcountry'])->{'testcountry'}->{'Test'} eq 'Wombat', 'get_all_hashref() - valid args - returns test hashref' );

#9
ok( scalar keys %{$cia->get_all_hashref(['zz'])->{'Test'}} == 0, 'get_all_hashref() - invalid args - returns empty hashref' );

#10
my $data = $cia->get_hashref(['testcountry'],['Test', 'Foo']);
ok( $data->{'testcountry'}->{'Test'} eq 'Wombat' &&
    ! defined $data->{'testcountry'}->{'Foo'}, 'get_hashref() (multiple fields) - mix of valid/invalid args - returns test hashref' );

#11
$data = $cia->get_hashref(['testcountry', 'zz'],['Test']);
ok( $data->{'testcountry'}->{'Test'} eq 'Wombat' &&
    ! defined $data->{'zz'}->{'Test'}, 'get_hashref() (multiple countries) - mix of valid/invalid args - returns test hashref' );

