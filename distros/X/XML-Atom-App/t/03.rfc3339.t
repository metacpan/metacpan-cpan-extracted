use Test::More tests => 7;

eval 'use DateTime;';
plan skip_all => 'DateTime required for testing RFC 3339 date stringification' if $@;

BEGIN {
use_ok( 'XML::Atom::App' );
}

diag( "Testing XML::Atom::App $XML::Atom::App::VERSION RFC 3339 date stringification" );

my $date = [
    'year'      => 1999, 
    'month'     => 7, 
    'day'       => 17, 
    'hour'      => 12,
    'minute'    => 01,
    'second'    => 00,
    'time_zone' => 'EST',
];

my $dt = DateTime->new( @{$date} );

ok( XML::Atom::App->datetime_as_rfc3339($date) eq '1999-07-17T12:01:00-0500', 'from array ref' );
ok( XML::Atom::App->datetime_as_rfc3339($dt) eq '1999-07-17T12:01:00-0500', 'from DateTime object' );


ok( XML::Atom::App->datetime_as_rfc3339($dt) eq '1999-07-17T12:01:00-0500', 'negative TZ offset' );

$dt->set_time_zone('GMT');
ok( XML::Atom::App->datetime_as_rfc3339($dt) eq '1999-07-17T17:01:00Z', 'no TZ offset' );

$dt->set_time_zone('Pacific/Fiji');
ok( XML::Atom::App->datetime_as_rfc3339($dt) eq '1999-07-18T05:01:00+1200', 'positive TZ offset' );

ok( XML::Atom::App->atom_date_string($dt) eq '1999-07-18T05:01:00+1200', 'atom_date_string() alias');